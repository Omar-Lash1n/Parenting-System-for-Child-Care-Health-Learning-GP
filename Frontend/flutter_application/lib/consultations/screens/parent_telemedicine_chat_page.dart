import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/api/chat_service.dart';
import 'package:Ajial/api/parent_consultation_service.dart';
import 'package:Ajial/consultations/screens/doctor_booking_page.dart';

class ParentTelemedicineChatPage extends StatefulWidget {
  final String bookingId;
  final String doctorId;
  final String doctorName;
  final String doctorImage;
  final String doctorSpecialization;
  final DateTime chatDeadline;

  const ParentTelemedicineChatPage({
    super.key,
    required this.bookingId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
    required this.doctorSpecialization,
    required this.chatDeadline,
  });

  @override
  State<ParentTelemedicineChatPage> createState() =>
      _ParentTelemedicineChatPageState();
}

/// Display model for one bubble (mapped from the backend [ChatMessageModel]).
class _UiMessage {
  final String text;
  final bool isOutgoing; // true = parent (me), false = doctor
  final DateTime time;
  final String? attachmentUrl;
  final String? attachmentType; // 'image' | 'file'
  final String? fileName;

  _UiMessage({
    required this.text,
    required this.isOutgoing,
    required this.time,
    this.attachmentUrl,
    this.attachmentType,
    this.fileName,
  });
}

class _ParentTelemedicineChatPageState extends State<ParentTelemedicineChatPage> {
  late final ChatApiService _api;
  late final ChatHubService _hub;

  Duration _timeLeft = Duration.zero;
  DateTime? _deadline;
  Timer? _timer;
  Timer? _typingDebounce;
  bool _typingSent = false;

  String? _patientImage;
  String? _doctorImageUrl;

  final TextEditingController _chatController = TextEditingController();
  final List<_UiMessage> _messages = [];
  final Set<String> _seenIds = {};
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _canSend = false;
  String? _windowNotice;
  bool _doctorOnline = false;
  bool _doctorTyping = false;
  bool _sending = false;

  final Color primaryColor = const Color(0xFFBF092F); // Red
  final String fontFamily = 'IBM Plex Sans Arabic';

  @override
  void initState() {
    super.initState();
    _deadline = widget.chatDeadline;
    _doctorImageUrl = widget.doctorImage;
    final auth = AuthService();
    _api = ChatApiService(auth.getToken);
    _hub = ChatHubService(auth.getToken)
      ..onMessage = _onIncomingMessage
      ..onTyping = (t) {
        if (mounted) setState(() => _doctorTyping = t);
        if (t) _scrollToBottom();
      }
      ..onPresence = (online) {
        if (mounted) setState(() => _doctorOnline = online);
      }
      ..onError = (msg) {
        if (mounted) _showSnack(msg);
      };

    _loadPatientProfile();
    _bootstrap();
    _startTimer();
  }

  Future<void> _bootstrap() async {
    try {
      final convo = await _api.getConversation(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _canSend = convo.canSendMessages;
        _windowNotice = convo.windowNotice;
        _doctorOnline = convo.participant.isOnline;
        if (convo.participant.avatarUrl != null &&
            convo.participant.avatarUrl!.isNotEmpty) {
          _doctorImageUrl = convo.participant.avatarUrl;
        }
        if (convo.windowClosesAt != null) _deadline = convo.windowClosesAt;
        for (final m in convo.messages) {
          if (_seenIds.add(m.id)) _messages.add(_map(m));
        }
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('تعذّر تحميل المحادثة');
      return;
    }
    // Live channel is best-effort: messaging still works over REST without it.
    await _hub.connectQuietly(widget.bookingId);
  }

  _UiMessage _map(ChatMessageModel m) => _UiMessage(
        text: m.content ?? '',
        isOutgoing: m.senderRole == 'parent',
        time: m.createdAt,
        attachmentUrl: m.attachmentUrl,
        attachmentType: m.type == 'text' ? null : m.type,
        fileName: m.attachmentName,
      );

  void _onIncomingMessage(ChatMessageModel m) {
    if (!mounted) return;
    if (!_seenIds.add(m.id)) return; // dedup by id (echo / reconnect)
    setState(() {
      _doctorTyping = false;
      _messages.add(_map(m));
    });
    _scrollToBottom();
  }

  Future<void> _loadPatientProfile() async {
    final profile = await AuthService().getParentProfile();
    if (profile != null && mounted) {
      setState(() {
        _patientImage = profile['profileImageUrl'] ?? profile['profileImage'];
      });
    }
  }

  void _startTimer() {
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeLeft());
  }

  void _updateTimeLeft() {
    final deadline = _deadline;
    if (deadline == null) return;
    final now = DateTime.now();
    if (now.isBefore(deadline)) {
      setState(() => _timeLeft = deadline.difference(now));
    } else {
      _timer?.cancel();
      setState(() {
        _timeLeft = Duration.zero;
        _canSend = false;
        _windowNotice ??= 'انتهت فترة التحدث مع الطبيب';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _typingDebounce?.cancel();
    _hub.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onInputChanged(String _) {
    if (!_canSend) return;
    if (!_typingSent) {
      _typingSent = true;
      _hub.sendTyping(true);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      _typingSent = false;
      _hub.sendTyping(false);
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || !_canSend) return;
    _chatController.clear();
    _typingDebounce?.cancel();
    _typingSent = false;
    _hub.sendTyping(false);
    try {
      // Send over REST (reliable + broadcasts to the doctor). Render our own
      // copy now; the hub echo (if connected) is deduped by id.
      final sent = await _api.sendText(widget.bookingId, text);
      if (sent != null) _onIncomingMessage(sent);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleAttachmentSelection(String value) async {
    if (!_canSend) return;
    String? path;
    String? name;
    if (value == 'camera') {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      path = photo?.path;
      name = photo?.name;
    } else if (value == 'gallery') {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      path = image?.path;
      name = image?.name;
    } else if (value == 'file') {
      final result = await FilePicker.pickFiles();
      if (result != null && result.files.single.path != null) {
        path = result.files.single.path;
        name = result.files.single.name;
      }
    }
    if (path == null) return;
    final fileName = name ?? path.split('/').last.split('\\').last;

    setState(() => _sending = true);
    try {
      final sent = await _api.sendAttachment(widget.bookingId, path, fileName);
      if (sent != null) _onIncomingMessage(sent);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: TextStyle(fontFamily: fontFamily))),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isTimeout = !_canSend;

    String timerText = _windowNotice ?? 'فترة التحدث مع الطبيب انتهت';
    if (_canSend && _timeLeft.inSeconds > 0) {
      String days = _timeLeft.inDays.toString().padLeft(2, '0');
      String hours = (_timeLeft.inHours % 24).toString().padLeft(2, '0');
      String minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
      timerText = '$days يوم : $hours س : $minutes ق';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Transform.flip(
                          flipX: true,
                          child: Image.asset(
                            'images/back arrow red.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.arrow_forward, color: primaryColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: (_doctorImageUrl != null &&
                                  _doctorImageUrl!.isNotEmpty)
                              ? NetworkImage(_doctorImageUrl!)
                              : null,
                          onBackgroundImageError: (_, __) {},
                          child: (_doctorImageUrl == null || _doctorImageUrl!.isEmpty)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        Positioned(
                          bottom: -2,
                          left: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _doctorOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.doctorName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                            ],
                          ),
                          Text(
                            _doctorOnline ? 'متصل الآن' : widget.doctorSpecialization,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 12,
                              color: _doctorOnline
                                  ? Colors.green
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Timer Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        timerText,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isTimeout ? Colors.black87 : primaryColor,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 18, color: primaryColor),
                  ],
                ),
              ),

              // Messages Area
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: primaryColor))
                    : _messages.isEmpty && !_doctorTyping
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'images/chat empty.png',
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'يبدو انه لا يتم التواصل بعد مع الطبيب\n${widget.doctorName}, ارسل استفسارك الان',
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 24.0),
                            itemCount: _messages.length + (_doctorTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length && _doctorTyping) {
                                return _buildTypingIndicator();
                              }
                              final message = _messages[index];
                              return message.isOutgoing
                                  ? _buildOutgoingMessage(message)
                                  : _buildIncomingMessage(message);
                            },
                          ),
              ),

              // Input Area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isTimeout) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorBookingPage(
                                doctor: AvailableDoctor(
                                  id: widget.doctorId,
                                  fullName: widget.doctorName,
                                  specialization: widget.doctorSpecialization,
                                  profileImageUrl: _doctorImageUrl,
                                  hasClinic: true,
                                  hasRemote: true,
                                ),
                                initialServiceType: 'remote',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Colors.black87, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              'حجز الجلسة مرة اخري',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          PopupMenuButton<String>(
                            onSelected: _handleAttachmentSelection,
                            enabled: !isTimeout && !_sending,
                            offset: const Offset(0, -180),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'camera',
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('التقاط صورة',
                                          style: TextStyle(fontFamily: fontFamily),
                                          textAlign: TextAlign.right),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.camera_alt_outlined,
                                        color: Colors.grey.shade600, size: 20),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'gallery',
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('صورة من المعرض',
                                          style: TextStyle(fontFamily: fontFamily),
                                          textAlign: TextAlign.right),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.image_outlined,
                                        color: Colors.grey.shade600, size: 20),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'file',
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('تحميل ملف',
                                          style: TextStyle(fontFamily: fontFamily),
                                          textAlign: TextAlign.right),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.insert_drive_file_outlined,
                                        color: Colors.grey.shade600, size: 20),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: _sending
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: primaryColor),
                                      )
                                    : Image.asset(
                                        'images/pin.png',
                                        width: 20,
                                        height: 20,
                                        color: isTimeout
                                            ? Colors.grey.shade400
                                            : Colors.black,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: isTimeout
                                ? Text(
                                    'انتهت فترة التحدث الى الطبيب',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  )
                                : TextField(
                                    controller: _chatController,
                                    onChanged: _onInputChanged,
                                    decoration: InputDecoration(
                                      hintText: 'اكتب استشارتك هنا...',
                                      hintStyle: TextStyle(
                                        fontFamily: fontFamily,
                                        color: Colors.grey.shade400,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                          ),
                          GestureDetector(
                            onTap: isTimeout ? null : _sendMessage,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isTimeout
                                    ? primaryColor.withValues(alpha: 0.5)
                                    : primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Image.asset(
                                  'images/send.png',
                                  width: 20,
                                  height: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingMessage(_UiMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMessageContent(message),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(message.time),
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundImage:
                  (_doctorImageUrl != null && _doctorImageUrl!.isNotEmpty)
                      ? NetworkImage(_doctorImageUrl!)
                      : null,
              onBackgroundImageError: (_, __) {},
              child: (_doctorImageUrl == null || _doctorImageUrl!.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingMessage(_UiMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          border: Border.all(color: primaryColor, width: 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _safeAvatar(20, _patientImage),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMessageContent(message),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(message.time),
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade500, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade600, shape: BoxShape.circle)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'الطبيب يكتب...',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 12,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(_UiMessage message) {
    if (message.attachmentUrl != null && message.attachmentType == 'image') {
      return Column(
        crossAxisAlignment: message.isOutgoing
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              message.attachmentUrl!,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 150,
                height: 150,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          if (message.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _plainText(message),
          ],
        ],
      );
    }

    if (message.attachmentUrl != null && message.attachmentType == 'file') {
      final fileName = message.fileName ??
          message.attachmentUrl!.split('/').last.split('?').first;
      return Column(
        crossAxisAlignment: message.isOutgoing
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(message.attachmentUrl!);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                _showSnack('تعذّر فتح الملف');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.blue, size: 30),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      fileName,
                      style: TextStyle(fontFamily: fontFamily, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _plainText(message),
          ],
        ],
      );
    }

    return _plainText(message);
  }

  Widget _plainText(_UiMessage message) => Text(
        message.text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
        textAlign: message.isOutgoing ? TextAlign.right : TextAlign.left,
      );

  String _formatTime(DateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour >= 12 ? 'م' : 'ص';
    return '$hour12:${t.minute.toString().padLeft(2, '0')} $period';
  }

  /// Avatar that never depends on a bundled asset: a network image when a real
  /// URL is present, otherwise a person icon. Avoids 404s on missing assets.
  Widget _safeAvatar(double radius, String? url) {
    final hasUrl = url != null && url.startsWith('http');
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: hasUrl ? NetworkImage(url) : null,
      onBackgroundImageError: hasUrl ? (_, __) {} : null,
      child: hasUrl
          ? null
          : Icon(Icons.person, size: radius, color: Colors.grey.shade500),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Ajial/api/chat_service.dart';
import 'package:Ajial/api/specialist-services.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';

class SpecialistTelemedicineChatPage extends StatefulWidget {
  final String bookingId;
  final String patientName;
  final String patientImage;
  final DateTime chatDeadline;

  const SpecialistTelemedicineChatPage({
    super.key,
    required this.bookingId,
    required this.patientName,
    required this.patientImage,
    required this.chatDeadline,
  });

  @override
  State<SpecialistTelemedicineChatPage> createState() =>
      _SpecialistTelemedicineChatPageState();
}

/// Display model for one bubble (mapped from the backend [ChatMessageModel]).
class _UiMessage {
  final String text;
  final bool isDoctor; // true = doctor (me), false = patient (parent)
  final DateTime time;
  final String? attachmentUrl;
  final String? attachmentType; // 'image' | 'file'
  final String? fileName;

  _UiMessage({
    required this.text,
    required this.isDoctor,
    required this.time,
    this.attachmentUrl,
    this.attachmentType,
    this.fileName,
  });
}

class _SpecialistTelemedicineChatPageState
    extends State<SpecialistTelemedicineChatPage> {
  late final ChatApiService _api;
  late final ChatHubService _hub;

  Duration _timeLeft = Duration.zero;
  Timer? _timer;
  Timer? _typingDebounce;
  bool _typingSent = false;

  final TextEditingController _chatController = TextEditingController();
  final List<_UiMessage> _messages = [];
  final Set<String> _seenIds = {};
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _canSend = false;
  String? _windowNotice;
  bool _patientOnline = false;
  bool _patientTyping = false;
  bool _sending = false;
  String? _patientImageUrl;

  @override
  void initState() {
    super.initState();
    final specialist = SpecialistService();
    _api = ChatApiService(specialist.getSpecialistToken);
    _hub = ChatHubService(specialist.getSpecialistToken)
      ..onMessage = _onIncomingMessage
      ..onTyping = (t) {
        if (mounted) setState(() => _patientTyping = t);
        if (t) _scrollToBottom();
      }
      ..onPresence = (online) {
        if (mounted) setState(() => _patientOnline = online);
      }
      ..onError = (msg) {
        if (mounted) _showSnack(msg);
      };

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
        _patientOnline = convo.participant.isOnline;
        if (convo.participant.avatarUrl != null &&
            convo.participant.avatarUrl!.isNotEmpty) {
          _patientImageUrl = convo.participant.avatarUrl;
        }
        for (final m in convo.messages) {
          if (_seenIds.add(m.id)) _messages.add(_map(m));
        }
        _loading = false;
      });
      _scrollToBottom();
      await _hub.connect(widget.bookingId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('تعذّر تحميل المحادثة');
    }
  }

  _UiMessage _map(ChatMessageModel m) => _UiMessage(
        text: m.content ?? '',
        isDoctor: m.senderRole == 'doctor',
        time: m.createdAt,
        attachmentUrl: m.attachmentUrl,
        attachmentType: m.type == 'text' ? null : m.type,
        fileName: m.attachmentName,
      );

  void _onIncomingMessage(ChatMessageModel m) {
    if (!mounted) return;
    if (!_seenIds.add(m.id)) return; // dedup by id
    setState(() {
      _patientTyping = false;
      _messages.add(_map(m));
    });
    _scrollToBottom();
  }

  void _startTimer() {
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeLeft());
  }

  void _updateTimeLeft() {
    final deadline = widget.chatDeadline;
    final now = DateTime.now();
    if (now.isBefore(deadline)) {
      setState(() => _timeLeft = deadline.difference(now));
    } else {
      _timer?.cancel();
      setState(() {
        _timeLeft = Duration.zero;
        _canSend = false;
        _windowNotice ??= 'انتهت فترة التحدث مع المريض';
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
      await _hub.sendMessage(text);
    } catch (e) {
      _showSnack('تعذّر إرسال الرسالة');
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
      await _api.sendAttachment(widget.bookingId, path, fileName);
    } catch (e) {
      _showSnack('تعذّر رفع المرفق');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: specialistFont))),
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

  String _formatDuration(Duration d) {
    String days = d.inDays.toString().padLeft(2, '0');
    String hours = (d.inHours % 24).toString().padLeft(2, '0');
    String minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$days يوم : $hours س : $minutes د : $seconds ث';
  }

  ImageProvider _patientAvatar() {
    if (_patientImageUrl != null && _patientImageUrl!.isNotEmpty) {
      return NetworkImage(_patientImageUrl!);
    }
    return AssetImage(widget.patientImage);
  }

  @override
  Widget build(BuildContext context) {
    final bool isTimeout = !_canSend;
    String timerText = _windowNotice ?? 'انتهت فترة التحدث مع المريض';
    if (_canSend && _timeLeft.inSeconds > 0) {
      timerText = _formatDuration(_timeLeft);
    } else if (_canSend) {
      timerText = 'المحادثة متاحة';
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
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F7F0),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'images/back arrow.png',
                          width: 24,
                          height: 24,
                          color: specialistGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(radius: 24, backgroundImage: _patientAvatar()),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              left: 0,
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: _patientOnline ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.patientName,
                              style: const TextStyle(
                                fontFamily: specialistFont,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              _patientOnline ? 'متاح الان' : 'غير متصل',
                              style: TextStyle(
                                fontFamily: specialistFont,
                                fontSize: 12,
                                color: _patientOnline
                                    ? Colors.green
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Timer Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9F4),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 18, color: specialistGreen),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        timerText,
                        style: const TextStyle(
                          fontFamily: specialistFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),

              // Messages Area
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: specialistGreen))
                    : _messages.isEmpty && !_patientTyping
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
                                  'يبدو انه لا يتم التواصل بعد مع\nالمريض ${widget.patientName}',
                                  style: TextStyle(
                                    fontFamily: specialistFont,
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
                            itemCount: _messages.length + (_patientTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length && _patientTyping) {
                                return _buildTypingIndicator();
                              }
                              final message = _messages[index];
                              return message.isDoctor
                                  ? _buildDoctorMessage(message)
                                  : _buildPatientMessage(message);
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
                child: Container(
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
                                const Expanded(
                                  child: Text('التقاط صورة',
                                      style: TextStyle(fontFamily: specialistFont),
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
                                const Expanded(
                                  child: Text('صورة من المعرض',
                                      style: TextStyle(fontFamily: specialistFont),
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
                                const Expanded(
                                  child: Text('تحميل ملف',
                                      style: TextStyle(fontFamily: specialistFont),
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
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: specialistGreen),
                                  )
                                : Image.asset(
                                    'images/pin.png',
                                    width: 20,
                                    height: 20,
                                    color: isTimeout ? Colors.grey.shade400 : Colors.black,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isTimeout
                            ? const Text(
                                'انتهت فترة التحدث الى المريض',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: specialistFont,
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : TextField(
                                controller: _chatController,
                                onChanged: _onInputChanged,
                                decoration: InputDecoration(
                                  hintText: 'اكتب استشارتك هنا...',
                                  hintStyle: TextStyle(
                                    fontFamily: specialistFont,
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
                                ? specialistGreen.withValues(alpha: 0.5)
                                : specialistGreen,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorMessage(_UiMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FBF7),
          border: Border.all(color: specialistGreen),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('images/pic.png'),
                    ),
                    Positioned(
                      bottom: -2,
                      left: -2,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified, color: Colors.blue, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildMessageContent(message)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(message.time),
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientMessage(_UiMessage message) {
    return Align(
      alignment: Alignment.centerRight,
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
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMessageContent(message)),
                const SizedBox(width: 12),
                CircleAvatar(radius: 20, backgroundImage: _patientAvatar()),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(message.time),
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              'المريض يكتب...',
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 12,
                color: Colors.grey.shade500,
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
        crossAxisAlignment:
            message.isDoctor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
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
        crossAxisAlignment:
            message.isDoctor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
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
                      style: const TextStyle(fontFamily: specialistFont, fontSize: 12),
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
        style: const TextStyle(
          fontFamily: specialistFont,
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
        textAlign: message.isDoctor ? TextAlign.right : TextAlign.left,
      );

  String _formatTime(DateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour >= 12 ? 'م' : 'ص';
    return '$hour12:${t.minute.toString().padLeft(2, '0')} $period';
  }
}

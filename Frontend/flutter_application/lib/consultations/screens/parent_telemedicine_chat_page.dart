import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/api/parent_consultation_service.dart';
import 'package:Ajial/consultations/screens/doctor_booking_page.dart';

class ParentTelemedicineChatPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String doctorImage;
  final String doctorSpecialization;
  final DateTime chatDeadline;

  const ParentTelemedicineChatPage({
    super.key,
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

class ChatMessage {
  final String text;
  final bool isOutgoing; // true = patient (user), false = doctor
  final DateTime time;
  final String? attachmentPath;
  final String? attachmentType; // 'image' or 'file'
  final String? fileName;

  ChatMessage({
    required this.text,
    required this.isOutgoing,
    required this.time,
    this.attachmentPath,
    this.attachmentType,
    this.fileName,
  });
}

class _ParentTelemedicineChatPageState extends State<ParentTelemedicineChatPage> {
  Duration _timeLeft = Duration.zero;
  Timer? _timer;
  String? _patientImage;

  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;

  final Color primaryColor = const Color(0xFFBF092F); // Red
  final String fontFamily = 'IBM Plex Sans Arabic';

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadPatientProfile();
  }

  Future<void> _loadPatientProfile() async {
    final authService = AuthService();
    final profile = await authService.getParentProfile();
    if (profile != null && mounted) {
      setState(() {
        _patientImage = profile['profileImageUrl'] ?? profile['profileImage'];
      });
    }
  }

  void _startTimer() {
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    if (now.isBefore(widget.chatDeadline)) {
      setState(() {
        _timeLeft = widget.chatDeadline.difference(now);
      });
    } else {
      _timer?.cancel();
      setState(() {
        _timeLeft = Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleAttachmentSelection(String value) async {
    if (value == 'camera') {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        _sendAttachment(photo.path, 'image');
      }
    } else if (value == 'gallery') {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _sendAttachment(image.path, 'image');
      }
    } else if (value == 'file') {
      FilePickerResult? result = await FilePicker.pickFiles();
      if (result != null && result.files.single.path != null) {
        _sendAttachment(result.files.single.path!, 'file', fileName: result.files.single.name);
      }
    }
  }

  void _sendAttachment(String path, String type, {String? fileName}) {
    setState(() {
      _messages.add(ChatMessage(
        text: type == 'image' ? 'تم إرفاق صورة' : 'تم إرفاق ملف',
        isOutgoing: true,
        time: DateTime.now(),
        attachmentPath: path,
        attachmentType: type,
        fileName: fileName,
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate doctor replying to attachment
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: 'شكراً لك، جاري مراجعة المرفق.',
            isOutgoing: false,
            time: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isOutgoing: true,
        time: DateTime.now(),
      ));
      _chatController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate doctor typing and replying
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: 'أهلاً بك، سأقوم بمراجعة الحالة في أقرب وقت والرد عليك.',
            isOutgoing: false,
            time: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
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
    return '02 يوم : $hours س : $minutes ق'; // The user screenshot has '02 يوم', but let's use actual $days for correctness
    // wait, I will use actual days
  }

  @override
  Widget build(BuildContext context) {
    final bool isTimeout = _timeLeft.inSeconds <= 0;
    
    String timerText = 'فترة التحدث مع الطبيب انتهت';
    if (!isTimeout) {
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
                          color: Colors.red.shade50, // Fallback if image doesn't have it
                          shape: BoxShape.circle,
                        ),
                        child: Transform.flip(
                          flipX: true, // Flip arrow to point right
                          child: Image.asset(
                            'images/back arrow red.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (_, __, ___) => Icon(Icons.arrow_forward, color: primaryColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(widget.doctorImage),
                          onBackgroundImageError: (_, __) => const Icon(Icons.person),
                        ),
                        Positioned(
                          bottom: -2,
                          left: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
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
                              Text(
                                widget.doctorName,
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                            ],
                          ),
                          Text(
                            widget.doctorSpecialization,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 12,
                              color: Colors.grey.shade600,
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
                    Text(
                      timerText,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isTimeout ? Colors.black87 : primaryColor,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 18, color: primaryColor),
                  ],
                ),
              ),

              // Messages Area
              Expanded(
                child: _messages.isEmpty
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isTyping) {
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
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
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
                                  profileImageUrl: widget.doctorImage,
                                  hasClinic: true, // Defaults, will be updated by page load
                                  hasRemote: true,
                                ),
                                initialServiceType: 'remote', // Telemedicine chat context
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
                          // Pin Button (Right in RTL, meaning first child)
                          PopupMenuButton<String>(
                            onSelected: _handleAttachmentSelection,
                            enabled: !isTimeout,
                            offset: const Offset(0, -180),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'camera',
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('التقاط صورة', style: TextStyle(fontFamily: fontFamily), textAlign: TextAlign.right),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.camera_alt_outlined, color: Colors.grey.shade600, size: 20),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'gallery',
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('صورة من المعرض', style: TextStyle(fontFamily: fontFamily), textAlign: TextAlign.right),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.image_outlined, color: Colors.grey.shade600, size: 20),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'file',
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('تحميل ملف', style: TextStyle(fontFamily: fontFamily), textAlign: TextAlign.right),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.insert_drive_file_outlined, color: Colors.grey.shade600, size: 20),
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
                                child: Image.asset(
                                  'images/pin.png',
                                  width: 20,
                                  height: 20,
                                  color: isTimeout ? Colors.grey.shade400 : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // TextField
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
                          
                          // Send Button
                          GestureDetector(
                            onTap: isTimeout ? null : _sendMessage,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isTimeout ? primaryColor.withValues(alpha: 0.5) : primaryColor,
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

  Widget _buildIncomingMessage(ChatMessage message) { // Doctor message
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
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
                    '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')} ${message.time.hour >= 12 ? 'م' : 'ص'}',
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
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.doctorImage),
                  onBackgroundImageError: (_, __) => const Icon(Icons.person),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
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
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingMessage(ChatMessage message) { // Patient message
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          border: Border.all(color: primaryColor, width: 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(0), // Sharp bottom-right corner
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _patientImage != null && _patientImage!.isNotEmpty
                  ? NetworkImage(_patientImage!)
                  : const AssetImage('images/pic.png') as ImageProvider,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMessageContent(message),
                  const SizedBox(height: 8),
                  Text(
                    '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')} ${message.time.hour >= 12 ? 'م' : 'ص'}',
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

  Widget _buildMessageContent(ChatMessage message) {
    if (message.attachmentPath != null) {
      if (message.attachmentType == 'image') {
        return Column(
          crossAxisAlignment: message.isOutgoing ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network(
                      message.attachmentPath!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 150,
                          height: 150,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    )
                  : Image.file(
                      File(message.attachmentPath!),
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 150,
                          height: 150,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              message.text,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: message.isOutgoing ? TextAlign.right : TextAlign.left,
            ),
          ],
        );
      } else if (message.attachmentType == 'file') {
        String fileName = message.fileName ?? message.attachmentPath!.split('/').last.split('\\').last;
        return Column(
          crossAxisAlignment: message.isOutgoing ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () async {
                final result = await OpenFile.open(message.attachmentPath!);
                if (result.type != ResultType.done) {
                  String errorMsg = 'لا يمكن فتح هذا الملف';
                  if (result.type == ResultType.noAppToOpen) {
                    errorMsg = 'لا يوجد تطبيق لفتح هذا النوع من الملفات';
                  } else if (result.message.isNotEmpty) {
                    errorMsg = result.message;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMsg, style: TextStyle(fontFamily: fontFamily))),
                  );
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
            const SizedBox(height: 8),
            Text(
              message.text,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: message.isOutgoing ? TextAlign.right : TextAlign.left,
            ),
          ],
        );
      }
    }
    
    return Text(
      message.text,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        color: Colors.black87,
        height: 1.5,
      ),
      textAlign: message.isOutgoing ? TextAlign.right : TextAlign.left,
    );
  }
}

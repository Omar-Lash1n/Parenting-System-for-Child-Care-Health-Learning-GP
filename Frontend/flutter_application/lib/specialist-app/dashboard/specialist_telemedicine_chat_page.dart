import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';

class SpecialistTelemedicineChatPage extends StatefulWidget {
  final String patientName;
  final String patientImage;

  const SpecialistTelemedicineChatPage({
    super.key,
    required this.patientName,
    required this.patientImage,
  });

  @override
  State<SpecialistTelemedicineChatPage> createState() =>
      _SpecialistTelemedicineChatPageState();
}

class ChatMessage {
  final String text;
  final bool isDoctor;
  final DateTime time;
  final String? attachmentPath;
  final String? attachmentType; // 'image' or 'file'

  ChatMessage({
    required this.text,
    required this.isDoctor,
    required this.time,
    this.attachmentPath,
    this.attachmentType,
  });
}

class _SpecialistTelemedicineChatPageState
    extends State<SpecialistTelemedicineChatPage> {
  // Timer for 3 days (72 hours)
  Duration _timeLeft = const Duration(days: 3);
  Timer? _timer;

  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
        setState(() {}); // Trigger rebuild for timeout state
      }
    });
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
        _sendAttachment(result.files.single.path!, 'file');
      }
    }
  }

  void _sendAttachment(String path, String type) {
    setState(() {
      _messages.add(ChatMessage(
        text: type == 'image' ? 'تم إرفاق صورة' : 'تم إرفاق ملف',
        isDoctor: true,
        time: DateTime.now(),
        attachmentPath: path,
        attachmentType: type,
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate patient replying to attachment
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: 'شكراً دكتور، جاري المراجعة.',
            isDoctor: false,
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
        isDoctor: true,
        time: DateTime.now(),
      ));
      _chatController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate patient typing and replying
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: 'أهلاً دكتور، نعم لاحظت احمرار بسيط في قدم يحيى يبكي قليلاً عند لمسها.',
            isDoctor: false,
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
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$days يوم : $hours س : $minutes د : $seconds ث';
  }

  @override
  Widget build(BuildContext context) {
    final bool isTimeout = _timeLeft.inSeconds <= 0;

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
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: AssetImage(widget.patientImage),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0, // Left in RTL visually, but 'right' in Positioned is logical right. Let's use left to make it appear on the left side of avatar.
                              left: 0,
                              child: Align(
                                alignment: Alignment.bottomLeft,
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
                              'متاح الان',
                              style: TextStyle(
                                fontFamily: specialistFont,
                                fontSize: 12,
                                color: Colors.grey.shade600,
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
                    Text(
                      _formatDuration(_timeLeft),
                      style: const TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textDirection: TextDirection.rtl, // Ensuring numbers format right
                    ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                        itemCount: _messages.length + (_isTyping ? 1 : 0) + 1, // +1 for date header
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Date Header
                            return Center(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Text(
                                  'اليوم, ١٤ مايو ٢٠٢٤',
                                  style: TextStyle(
                                    fontFamily: specialistFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            );
                          }

                          final messageIndex = index - 1;
                          if (messageIndex == _messages.length && _isTyping) {
                            return _buildTypingIndicator();
                          }

                          final message = _messages[messageIndex];
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
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
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
                                const Expanded(
                                  child: Text('التقاط صورة', style: TextStyle(fontFamily: specialistFont), textAlign: TextAlign.right),
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
                                const Expanded(
                                  child: Text('صورة من المعرض', style: TextStyle(fontFamily: specialistFont), textAlign: TextAlign.right),
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
                                const Expanded(
                                  child: Text('تحميل ملف', style: TextStyle(fontFamily: specialistFont), textAlign: TextAlign.right),
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
                      
                      // TextField or Timeout Text
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
                      
                      // Send Button (Left in RTL, meaning last child)
                      GestureDetector(
                        onTap: isTimeout ? null : _sendMessage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isTimeout ? specialistGreen.withValues(alpha: 0.5) : specialistGreen,
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

  Widget _buildDoctorMessage(ChatMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
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
                Expanded(
                  child: _buildMessageContent(message),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')} ${message.time.hour >= 12 ? 'م' : 'ص'}',
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

  Widget _buildPatientMessage(ChatMessage message) {
    return Align(
      alignment: Alignment.centerRight,
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
                Expanded(
                  child: _buildMessageContent(message),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(widget.patientImage),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')} ${message.time.hour >= 12 ? 'م' : 'ص'}',
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

  Widget _buildMessageContent(ChatMessage message) {
    if (message.attachmentPath != null) {
      if (message.attachmentType == 'image') {
        return Column(
          crossAxisAlignment: message.isDoctor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
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
              style: const TextStyle(
                fontFamily: specialistFont,
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: message.isDoctor ? TextAlign.right : TextAlign.left,
            ),
          ],
        );
      } else if (message.attachmentType == 'file') {
        String fileName = message.attachmentPath!.split('/').last.split('\\').last;
        return Column(
          crossAxisAlignment: message.isDoctor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
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
            const SizedBox(height: 8),
            Text(
              message.text,
              style: const TextStyle(
                fontFamily: specialistFont,
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: message.isDoctor ? TextAlign.right : TextAlign.left,
            ),
          ],
        );
      }
    }
    
    return Text(
      message.text,
      style: const TextStyle(
        fontFamily: specialistFont,
        fontSize: 14,
        color: Colors.black87,
        height: 1.5,
      ),
      textAlign: message.isDoctor ? TextAlign.right : TextAlign.left,
    );
  }
}

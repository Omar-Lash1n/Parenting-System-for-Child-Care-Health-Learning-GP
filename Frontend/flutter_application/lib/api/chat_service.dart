// --- lib/api/chat_service.dart ---
// Phase 7: real-time consultation chat (parent ↔ doctor) tied to a Booking.
// REST (history + send + attachments) over `api/chat`, live push over SignalR
// hub `/hubs/chat`. Shared by both the parent app and the specialist app — the
// caller supplies its own JWT via [tokenProvider] and its own role via [myRole].

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Host root (no `/api`) — REST lives under `$_host/api`, the hub at `$_host/hubs/chat`.
const String _chatHost =
    'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net';

/// A single chat message as returned by the backend (camelCase JSON).
class ChatMessageModel {
  final String id;
  final String bookingId;
  final String senderUserId;
  final String senderRole; // 'parent' | 'doctor'
  final String type; // 'text' | 'image' | 'file'
  final String? content;
  final String? attachmentUrl;
  final String? attachmentName;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.bookingId,
    required this.senderUserId,
    required this.senderRole,
    required this.type,
    required this.content,
    required this.attachmentUrl,
    required this.attachmentName,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt']?.toString();
    DateTime parsed;
    try {
      parsed = rawDate != null ? DateTime.parse(rawDate).toLocal() : DateTime.now();
    } catch (_) {
      parsed = DateTime.now();
    }
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      senderUserId: json['senderUserId']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'doctor',
      type: json['type']?.toString() ?? 'text',
      content: json['content']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      attachmentName: json['attachmentName']?.toString(),
      createdAt: parsed,
    );
  }
}

/// The other party in the conversation (header card).
class ChatParticipant {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? specialty;
  final bool isOnline;

  ChatParticipant({
    required this.userId,
    required this.fullName,
    required this.avatarUrl,
    required this.specialty,
    required this.isOnline,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      specialty: json['specialty']?.toString(),
      isOnline: json['isOnline'] == true,
    );
  }
}

/// Conversation envelope: participant + window state + ordered messages.
class ChatConversation {
  final String bookingId;
  final ChatParticipant participant;
  final bool canSendMessages;
  final String windowState; // 'open' | 'closed' | 'notAllowed'
  final String? windowNotice;
  final DateTime? windowClosesAt;
  final List<ChatMessageModel> messages;

  ChatConversation({
    required this.bookingId,
    required this.participant,
    required this.canSendMessages,
    required this.windowState,
    required this.windowNotice,
    required this.windowClosesAt,
    required this.messages,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    DateTime? closesAt;
    final raw = json['windowClosesAt']?.toString();
    if (raw != null && raw.isNotEmpty) {
      try {
        closesAt = DateTime.parse(raw).toLocal();
      } catch (_) {}
    }
    return ChatConversation(
      bookingId: json['bookingId']?.toString() ?? '',
      participant: ChatParticipant.fromJson(
          (json['participant'] as Map?)?.cast<String, dynamic>() ?? {}),
      canSendMessages: json['canSendMessages'] == true,
      windowState: json['windowState']?.toString() ?? 'closed',
      windowNotice: json['windowNotice']?.toString(),
      windowClosesAt: closesAt,
      messages: (json['messages'] as List?)
              ?.map((m) =>
                  ChatMessageModel.fromJson((m as Map).cast<String, dynamic>()))
              .toList() ??
          [],
    );
  }
}

/// REST client for `api/chat`. Pass a [tokenProvider] returning the caller's JWT.
class ChatApiService {
  final Future<String?> Function() tokenProvider;
  static const String _apiBase = '$_chatHost/api';

  ChatApiService(this.tokenProvider);

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw Exception('غير مصرح. يرجى تسجيل الدخول مرة أخرى.');
    }
    return {
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
    };
  }

  Map<String, dynamic> _extractData(String body) {
    final decoded = json.decode(body);
    if (decoded is Map<String, dynamic>) {
      if (decoded['success'] == false) {
        throw Exception(decoded['message']?.toString() ?? 'حدث خطأ');
      }
      if (decoded['data'] is Map<String, dynamic>) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded;
    }
    return {};
  }

  /// GET /api/chat/bookings/{bookingId} — participant + window + history.
  Future<ChatConversation> getConversation(String bookingId) async {
    final url = '$_apiBase/chat/bookings/$bookingId';
    final response = await http
        .get(Uri.parse(url), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return ChatConversation.fromJson(_extractData(response.body));
    }
    throw Exception('فشل تحميل المحادثة (${response.statusCode})');
  }

  /// POST /api/chat/bookings/{bookingId}/messages — send text.
  /// The message is also broadcast over the hub, so the caller renders it via
  /// `ReceiveMessage`; the returned model is provided for convenience.
  Future<ChatMessageModel?> sendText(String bookingId, String content) async {
    final url = '$_apiBase/chat/bookings/$bookingId/messages';
    final headers = await _headers();
    headers['Content-Type'] = 'application/json';
    final response = await http
        .post(Uri.parse(url),
            headers: headers, body: jsonEncode({'content': content}))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return ChatMessageModel.fromJson(_extractData(response.body));
    }
    // Surface the backend's Arabic message (e.g. window closed) where possible.
    try {
      final decoded = json.decode(response.body);
      throw Exception(decoded['message']?.toString() ?? 'فشل إرسال الرسالة');
    } catch (_) {
      throw Exception('فشل إرسال الرسالة (${response.statusCode})');
    }
  }

  /// POST /api/chat/bookings/{bookingId}/attachments — send an image/file.
  /// Returns the created message so the caller can render it immediately.
  Future<ChatMessageModel?> sendAttachment(
    String bookingId,
    String filePath,
    String fileName, {
    String? caption,
  }) async {
    final url = '$_apiBase/chat/bookings/$bookingId/attachments';
    final token = await tokenProvider();
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['accept'] = 'application/json';

    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final parts = mimeType.split('/');
    request.files.add(await http.MultipartFile.fromPath(
      'File',
      filePath,
      filename: fileName,
      contentType: parts.length == 2 ? MediaType(parts[0], parts[1]) : null,
    ));
    if (caption != null && caption.isNotEmpty) {
      request.fields['Caption'] = caption;
    }

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      return ChatMessageModel.fromJson(_extractData(response.body));
    }
    try {
      final decoded = json.decode(response.body);
      throw Exception(decoded['message']?.toString() ?? 'فشل رفع المرفق');
    } catch (_) {
      throw Exception('فشل رفع المرفق (${response.statusCode})');
    }
  }
}

/// SignalR live channel for one booking's chat. Handles connect, join, send,
/// typing, and presence; reconnects automatically.
class ChatHubService {
  final Future<String?> Function() tokenProvider;
  static const String _hubUrl = '$_chatHost/hubs/chat';

  HubConnection? _connection;
  String? _bookingId;

  /// Fired for every new message (including the caller's own echo).
  void Function(ChatMessageModel message)? onMessage;

  /// Fired when the other party starts/stops typing.
  void Function(bool isTyping)? onTyping;

  /// Fired when the other party's online state changes.
  void Function(bool isOnline)? onPresence;

  /// Fired on a backend error (e.g. window closed, not authorized).
  void Function(String message)? onError;

  /// Fired when the connection state changes (for the header indicator).
  void Function(bool connected)? onConnectionChange;

  ChatHubService(this.tokenProvider);

  /// Connects but never throws — the chat still works over REST if the live
  /// channel is unavailable. Returns true on success.
  Future<bool> connectQuietly(String bookingId) async {
    try {
      await connect(bookingId);
      return true;
    } catch (_) {
      onConnectionChange?.call(false);
      return false;
    }
  }

  Future<void> connect(String bookingId) async {
    _bookingId = bookingId;

    // Put the JWT directly in the URL query — the backend reads `access_token`
    // for `/hubs` paths on every request (negotiate, SSE, WS, long-polling),
    // which is more reliable than accessTokenFactory alone on the handshake.
    final token = (await tokenProvider()) ?? '';
    final url = '$_hubUrl?access_token=$token';

    final connection = HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => (await tokenProvider()) ?? '',
            // On web, force long-polling: Azure App Service has WebSockets off
            // by default, and a failing WS surfaces as an uncaught error inside
            // the web event-stream. Long-polling is plain HTTP and is robust.
            // Mobile keeps the default (negotiates WebSockets).
            transport: kIsWeb ? HttpTransportType.LongPolling : null,
          ),
        )
        .withAutomaticReconnect()
        .build();

    connection.on('ReceiveMessage', (args) {
      if (args == null || args.isEmpty) return;
      final map = (args[0] as Map).cast<String, dynamic>();
      onMessage?.call(ChatMessageModel.fromJson(map));
    });

    connection.on('Typing', (args) {
      if (args == null || args.isEmpty) return;
      final map = (args[0] as Map).cast<String, dynamic>();
      onTyping?.call(map['isTyping'] == true);
    });

    connection.on('PresenceChanged', (args) {
      if (args == null || args.isEmpty) return;
      final map = (args[0] as Map).cast<String, dynamic>();
      onPresence?.call(map['isOnline'] == true);
    });

    connection.on('ErrorMessage', (args) {
      if (args == null || args.isEmpty) return;
      onError?.call(args[0].toString());
    });

    connection.onreconnected(({connectionId}) async {
      onConnectionChange?.call(true);
      // Re-join the conversation group after a reconnect.
      final bid = _bookingId;
      if (bid != null) {
        try {
          await connection.invoke('JoinConversation', args: [bid]);
        } catch (_) {}
      }
    });
    connection.onreconnecting(({error}) => onConnectionChange?.call(false));
    connection.onclose(({error}) => onConnectionChange?.call(false));

    await connection.start();
    _connection = connection;
    onConnectionChange?.call(true);

    await connection.invoke('JoinConversation', args: [bookingId]);
  }

  Future<void> sendMessage(String content) async {
    final conn = _connection;
    final bid = _bookingId;
    if (conn == null || bid == null) return;
    await conn.invoke('SendMessage', args: [bid, content]);
  }

  Future<void> sendTyping(bool isTyping) async {
    final conn = _connection;
    final bid = _bookingId;
    if (conn == null || bid == null) return;
    try {
      await conn.invoke('Typing', args: [bid, isTyping]);
    } catch (_) {}
  }

  Future<void> dispose() async {
    final conn = _connection;
    final bid = _bookingId;
    _connection = null;
    if (conn == null) return;
    try {
      if (bid != null) {
        await conn.invoke('LeaveConversation', args: [bid]);
      }
    } catch (_) {}
    await conn.stop();
  }
}

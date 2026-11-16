import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../models/chat_models.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  Future<List<ChatConversationModel>> fetchConversations() async {
    final res = await ApiService.get('/chat/conversations');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .whereType<Map>()
            .map((e) =>
                ChatConversationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return <ChatConversationModel>[];
  }

  Future<List<ChatParticipant>> fetchContacts() async {
    final res = await ApiService.get('/chat/contacts');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .whereType<Map>()
            .map((e) => ChatParticipant.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return <ChatParticipant>[];
  }

  Future<ChatConversationModel> openDirectConversation({
    String? targetUserId,
    String? targetEmail,
    String? targetRole,
    String? targetName,
    String? orderId,
    String? title,
    String? initialMessage,
    String messageType = 'TEXT',
    Map<String, dynamic>? metadata,
  }) async {
    final payload = <String, dynamic>{
      if (targetUserId != null && targetUserId.isNotEmpty)
        'target_user_id': targetUserId,
      if (targetEmail != null && targetEmail.isNotEmpty)
        'target_email': targetEmail,
      if (targetRole != null && targetRole.isNotEmpty)
        'target_role': targetRole,
      if (targetName != null && targetName.isNotEmpty)
        'target_name': targetName,
      if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
      if (title != null && title.isNotEmpty) 'title': title,
      if (initialMessage != null && initialMessage.isNotEmpty)
        'initial_message': initialMessage,
      'message_type': messageType,
      'metadata': ?metadata,
    };

    final res = await ApiService.post('/chat/conversations/direct', payload);
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        decoded is Map &&
        decoded['data'] is Map) {
      return ChatConversationModel.fromJson(
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    }

    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Gagal membuka ruang percakapan (${res.statusCode})';
    throw Exception(msg);
  }

  Future<List<ChatMessageModel>> fetchMessages(String conversationId) async {
    final res =
        await ApiService.get('/chat/conversations/$conversationId/messages');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .whereType<Map>()
            .map((e) =>
                ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return <ChatMessageModel>[];
  }

  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String body, {
    String messageType = 'TEXT',
    Map<String, dynamic>? metadata,
  }) async {
    final res = await ApiService.post(
      '/chat/conversations/$conversationId/messages',
      {
        'body': body,
        'message_type': messageType,
        'metadata': ?metadata,
      },
    );
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        decoded is Map &&
        decoded['data'] is Map) {
      return ChatMessageModel.fromJson(
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Gagal mengirim pesan (${res.statusCode})';
    throw Exception(msg);
  }
}

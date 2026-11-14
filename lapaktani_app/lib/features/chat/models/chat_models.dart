class ChatParticipant {
  final String id;
  final String fullName;
  final String email;
  final int? roleId;
  final String role;

  const ChatParticipant({
    required this.id,
    required this.fullName,
    required this.email,
    this.roleId,
    required this.role,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['email'] ?? 'Pengguna LapakTani')
          .toString(),
      email: (json['email'] ?? '').toString(),
      roleId: json['role_id'] != null
          ? int.tryParse(json['role_id'].toString())
          : null,
      role: (json['role'] ?? 'petani').toString().toLowerCase(),
    );
  }

  String get roleLabel {
    switch (role) {
      case 'penyuluh':
        return 'Penyuluh BPP';
      case 'admin':
        return 'Ketua Poktan';
      case 'dinas':
        return 'Dinas Pertanian';
      case 'pembeli':
        return 'Pembeli';
      default:
        return 'Petani';
    }
  }
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String messageType;
  final String body;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.messageType,
    required this.body,
    this.metadata,
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedMeta;
    final rawMeta = json['metadata'];
    if (rawMeta is Map) {
      parsedMeta = Map<String, dynamic>.from(rawMeta);
    }

    return ChatMessageModel(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      senderName: (json['sender_name'] ?? 'Pengguna LapakTani').toString(),
      senderRole: (json['sender_role'] ?? 'petani').toString().toLowerCase(),
      messageType:
          (json['message_type'] ?? 'TEXT').toString().toUpperCase(),
      body: (json['body'] ?? '').toString(),
      metadata: parsedMeta,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class ChatConversationModel {
  final String id;
  final String type;
  final String? orderId;
  final String title;
  final DateTime? updatedAt;
  final List<ChatParticipant> participants;
  final ChatParticipant? otherParticipant;
  final ChatMessageModel? lastMessage;
  final int unreadCount;

  const ChatConversationModel({
    required this.id,
    required this.type,
    this.orderId,
    required this.title,
    this.updatedAt,
    this.participants = const [],
    this.otherParticipant,
    this.lastMessage,
    this.unreadCount = 0,
  });

  bool get isOrderChat => type.toUpperCase() == 'ORDER' || orderId != null;

  String get displayTitle {
    if (isOrderChat && title.isNotEmpty) return title;
    if (otherParticipant != null && otherParticipant!.fullName.isNotEmpty) {
      return otherParticipant!.fullName;
    }
    return title.isNotEmpty ? title : 'Ruang Obrolan';
  }

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final rawParts = json['participants'];
    final parts = rawParts is List
        ? rawParts
            .whereType<Map>()
            .map((e) => ChatParticipant.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ChatParticipant>[];

    final rawOther = json['other_participant'];
    final other = rawOther is Map
        ? ChatParticipant.fromJson(Map<String, dynamic>.from(rawOther))
        : (parts.isNotEmpty ? parts.first : null);

    final rawLast = json['last_message'];
    final lastMsg = rawLast is Map
        ? ChatMessageModel.fromJson(Map<String, dynamic>.from(rawLast))
        : null;

    return ChatConversationModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'DIRECT').toString().toUpperCase(),
      orderId: json['order_id']?.toString(),
      title: (json['title'] ?? '').toString(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      participants: parts,
      otherParticipant: other,
      lastMessage: lastMsg,
      unreadCount:
          int.tryParse((json['unread_count'] ?? 0).toString()) ?? 0,
    );
  }
}

import 'dart:convert';

class NotificationModel {
  final String id;
  final String orderId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String type; // 'order_incoming', 'harvest_reminder', 'courier_pickup'

  const NotificationModel({
    required this.id,
    required this.orderId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.type = 'order_incoming',
  });

  NotificationModel copyWith({
    String? id,
    String? orderId,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      orderId: map['orderId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isRead: map['isRead'] == true,
      type: map['type']?.toString() ?? 'order_incoming',
    );
  }

  String toJson() => jsonEncode(toMap());
  factory NotificationModel.fromJson(String source) => NotificationModel.fromMap(jsonDecode(source));
}

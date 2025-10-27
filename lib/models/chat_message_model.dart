import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String content;
  final String senderId;
  final String senderName;
  final String senderType; // 'user' or 'ai'
  final DateTime timestamp;
  final String? messageType; // 'text', 'voice', 'action'
  final Map<String, dynamic>? metadata; // Additional data like order info, route data
  final bool isRead;
  final String? actionType; // 'show_route', 'mark_delivery', 'emergency_alert'
  final Map<String, dynamic>? actionData; // Data for actions

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.timestamp,
    this.messageType = 'text',
    this.metadata,
    this.isRead = false,
    this.actionType,
    this.actionData,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] ?? '',
      conversationId: map['conversationId'] ?? '',
      content: map['content'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderType: map['senderType'] ?? 'user',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageType: map['messageType'] ?? 'text',
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      isRead: map['isRead'] ?? false,
      actionType: map['actionType'],
      actionData: map['actionData'] != null ? Map<String, dynamic>.from(map['actionData']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'content': content,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'timestamp': Timestamp.fromDate(timestamp),
      'messageType': messageType,
      'metadata': metadata,
      'isRead': isRead,
      'actionType': actionType,
      'actionData': actionData,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? conversationId,
    String? content,
    String? senderId,
    String? senderName,
    String? senderType,
    DateTime? timestamp,
    String? messageType,
    Map<String, dynamic>? metadata,
    bool? isRead,
    String? actionType,
    Map<String, dynamic>? actionData,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversationModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole; // 'transporter', 'farmer', 'distributor'
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int messageCount;
  final String? lastMessageId;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final Map<String, dynamic>? context; // Transporter-specific context
  final List<String>? tags; // Conversation tags for categorization

  ChatConversationModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.messageCount = 0,
    this.lastMessageId,
    this.lastMessageContent,
    this.lastMessageAt,
    this.context,
    this.tags,
  });

  factory ChatConversationModel.fromMap(Map<String, dynamic> map) {
    return ChatConversationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? 'transporter',
      title: map['title'] ?? 'AI Assistant',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      messageCount: map['messageCount'] ?? 0,
      lastMessageId: map['lastMessageId'],
      lastMessageContent: map['lastMessageContent'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      context: map['context'] != null ? Map<String, dynamic>.from(map['context']) : null,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'messageCount': messageCount,
      'lastMessageId': lastMessageId,
      'lastMessageContent': lastMessageContent,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'context': context,
      'tags': tags,
    };
  }

  ChatConversationModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userRole,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? messageCount,
    String? lastMessageId,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    Map<String, dynamic>? context,
    List<String>? tags,
  }) {
    return ChatConversationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      messageCount: messageCount ?? this.messageCount,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      context: context ?? this.context,
      tags: tags ?? this.tags,
    );
  }
}

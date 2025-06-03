class ChatModel {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String avatarUrl;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final String userId;
  final bool hasChatted;

  ChatModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatarUrl,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
    required this.userId,
    this.hasChatted = false,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, bool? hasChatted, String? lastMessage) {
    return ChatModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'User',
      lastMessage: lastMessage ?? '',
      time: formatTimeAgo(map['last_message_time']),
      avatarUrl: map['image'] ?? '',
      unreadCount: (map['unread_count'] ?? 0).toInt(),
      isOnline: map['is_online'] ?? false,
      isTyping: false,
      userId: map['id'] ?? '',
      hasChatted: hasChatted ?? false,
    );
  }

  static String formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';

    final DateTime messageTime = DateTime.parse(timestamp);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(messageTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${messageTime.day}/${messageTime.month}';
    }
  }
}

class MessageModel {
  final String id;
  final String text;
  final String time;
  final bool isSentByMe;
  final MessageType type;
  final String? imageUrl;
  final bool isRead;
  final String senderId;
  final String receiverId;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.text,
    required this.time,
    required this.isSentByMe,
    this.type = MessageType.text,
    this.imageUrl,
    this.isRead = false,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String currentUserId) {
    final DateTime createdAt = DateTime.parse(map['created_at']);

    return MessageModel(
      id: map['id'] ?? '',
      text: map['message'] ?? '',
      time: formatTime(createdAt),
      isSentByMe: map['sender_id'] == currentUserId,
      type: MessageType.text,
      isRead: map['is_read'] ?? false,
      senderId: map['sender_id'] ?? '',
      receiverId: map['receiver_id'] ?? '',
      createdAt: createdAt,
    );
  }

  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

enum MessageType { text, image, audio }

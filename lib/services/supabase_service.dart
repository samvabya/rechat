import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/chat_model.dart';

  class ChatSummary {
  final String userId;
  final String lastMessage;
  final DateTime timestamp;

  ChatSummary({
    required this.userId,
    required this.lastMessage,
    required this.timestamp,
  });
}
class SupabaseService {
  static final SupabaseClient _supabase = supabase;

  // Get all users
  Future<List<ChatModel>> getChatContacts() async {
    try {
      final response = await supabase.from('users').select('*');

      List<ChatSummary> chattedUsers = await getUniqueInteractedUserIds(supabase.auth.currentUser?.id ?? '');

      return response.map((data) => ChatModel.fromMap(data, chattedUsers.map((e) => e.userId).toList().contains(data['id']), chattedUsers.where((element) => element.userId==data['id']).first.lastMessage)).toList();
    } catch (e) {
      debugPrint('Error getting chat contacts: $e');
      return [];
    }
  }

Future<List<ChatSummary>> getUniqueInteractedUserIds(String myId) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('chats')
      .select('sender_id, receiver_id, message, created_at')
      .or('sender_id.eq.$myId,receiver_id.eq.$myId')
      .order('created_at', ascending: false); // newest first

  if (response.isEmpty) {
    return [];
  }

  final Map<String, ChatSummary> latestMessages = {};

  for (final chat in response) {
    final senderId = chat['sender_id'] as String;
    final receiverId = chat['receiver_id'] as String;
    final message = chat['message'] as String;
    final createdAt = DateTime.parse(chat['created_at']);

    // Get the "other" user in the chat
    final otherUserId = senderId == myId ? receiverId : senderId;

    // If this user not seen yet, store their latest message
    if (!latestMessages.containsKey(otherUserId)) {
      latestMessages[otherUserId] = ChatSummary(
        userId: otherUserId,
        lastMessage: message,
        timestamp: createdAt,
      );
    }
  }

  return latestMessages.values.toList();
}
  // Get chat messages between two users
  static Future<List<MessageModel>> getChatMessages(String otherUserId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('chats')
          .select()
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .or('sender_id.eq.$otherUserId,receiver_id.eq.$otherUserId')
          .order('created_at', ascending: true);

      // if (response.error != null) {
      //   throw response.error!;
      // }

      final List<dynamic> data = response;
      return data
          .where((msg) =>
              (msg['sender_id'] == userId &&
                  msg['receiver_id'] == otherUserId) ||
              (msg['sender_id'] == otherUserId && msg['receiver_id'] == userId))
          .map((msg) => MessageModel.fromMap(msg, userId))
          .toList();
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      return [];
    }
  }

  // Send a message
  static Future<MessageModel?> sendMessage({
    required String receiverId,
    required String message,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase.from('chats').insert({
        'sender_id': userId,
        'receiver_id': receiverId,
        'message': message,
      }).select();

      // if (response.error != null) {
      //   throw response.error!;
      // }

      final data = response[0];
      return MessageModel.fromMap(data, userId);
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String senderId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from('chats')
          .update({'is_read': true})
          .eq('sender_id', senderId)
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Listen to new messages
  static Stream<List<MessageModel>> listenToMessages(String otherUserId) {
    final userId = _supabase.auth.currentUser!.id;

    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((events) {
          return events
              .where((msg) =>
                  (msg['sender_id'] == userId &&
                      msg['receiver_id'] == otherUserId) ||
                  (msg['sender_id'] == otherUserId &&
                      msg['receiver_id'] == userId))
              .map((msg) => MessageModel.fromMap(msg, userId))
              .toList();
        });
  }

  // Listen to user presence
  static Stream<Map<String, bool>> listenToUserPresence() {
    return _supabase
        .from('user_presence')
        .stream(primaryKey: ['user_id']).map((events) {
      final Map<String, bool> presenceMap = {};
      for (final event in events) {
        presenceMap[event['user_id']] = event['is_online'] ?? false;
      }
      return presenceMap;
    });
  }

  // Update user profile
  static Future<void> updateProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase.from('profiles').update({
        'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }).eq('id', userId);

      // Also update auth metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': displayName,
          },
        ),
      );
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }
}

String formattedUrl(String url) {
  return 'https://dzndxdypnvjafxmindwj.supabase.co/storage/v1/object/public/uploads/$url';
}

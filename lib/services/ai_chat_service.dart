import 'dart:convert';
import 'package:ledger/models/ai_message.dart';
import 'package:ledger/services/secure_storage.dart';

class AiChat {
  final String id;
  final String title;
  final List<AiMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiChat({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AiChat.fromJson(Map<String, dynamic> json) {
    return AiChat(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List)
          .map((m) => AiMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  AiChat copyWith({
    String? id,
    String? title,
    List<AiMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiChat(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AiChatService {
  static const String _chatsKey = 'ai_chats';
  static const String _currentChatKey = 'current_ai_chat_id';

  Future<List<AiChat>> loadChats() async {
    try {
      final chatsJson = await SecureStorage.getValue(key: _chatsKey);
      if (chatsJson == null) return [];

      final List<dynamic> chatsList = jsonDecode(chatsJson);
      return chatsList
          .map((json) => AiChat.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveChats(List<AiChat> chats) async {
    final chatsJson = jsonEncode(chats.map((c) => c.toJson()).toList());
    await SecureStorage.setValue(key: _chatsKey, value: chatsJson);
  }

  Future<AiChat?> getCurrentChat() async {
    try {
      final currentId = await SecureStorage.getValue(key: _currentChatKey);
      if (currentId == null) return null;

      final chats = await loadChats();
      return chats.where((c) => c.id == currentId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  Future<void> setCurrentChat(String chatId) async {
    await SecureStorage.setValue(key: _currentChatKey, value: chatId);
  }

  Future<void> clearCurrentChat() async {
    await SecureStorage.clearValue(key: _currentChatKey);
  }

  Future<AiChat> saveChat(AiChat chat) async {
    final chats = await loadChats();
    final index = chats.indexWhere((c) => c.id == chat.id);

    if (index >= 0) {
      chats[index] = chat;
    } else {
      chats.add(chat);
    }

    await saveChats(chats);
    await setCurrentChat(chat.id);
    return chat;
  }

  Future<void> deleteChat(String chatId) async {
    final chats = await loadChats();
    chats.removeWhere((c) => c.id == chatId);
    await saveChats(chats);

    final currentId = await SecureStorage.getValue(key: _currentChatKey);
    if (currentId == chatId) {
      await clearCurrentChat();
    }
  }

  Future<void> deleteAllChats() async {
    await SecureStorage.clearValue(key: _chatsKey);
    await clearCurrentChat();
  }

  String generateChatTitle(List<AiMessage> messages) {
    // Get the first user message as the title
    final userMessage = messages.where((m) => m.role == 'user').firstOrNull;

    if (userMessage != null) {
      final content = userMessage.content.trim();
      if (content.length > 30) {
        return '${content.substring(0, 30)}...';
      }
      return content;
    }

    return 'New Chat - ${DateTime.now().toString().substring(0, 16)}';
  }
}

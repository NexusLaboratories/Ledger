import 'package:flutter/material.dart';
import 'package:ledger/components/ui/layout/custom_app_drawer.dart';
import 'package:ledger/services/ai_service.dart';
import 'package:ledger/models/ai_message.dart';
import 'package:ledger/components/ai/chat_message_widget.dart';
import 'package:ledger/components/typing_indicator.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/services/ai_chat_service.dart';
import 'package:ledger/components/ai/chat_menu_dialog.dart';
import 'package:ledger/screens/chats_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final AiService _aiService = AiService();
  final AiChatService _chatService = AiChatService();
  final List<AiMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  AiChat? _currentChat;

  @override
  void initState() {
    super.initState();
    _loadCurrentChat();
  }

  Future<void> _loadCurrentChat() async {
    final chat = await _chatService.getCurrentChat();
    if (chat != null) {
      setState(() {
        _currentChat = chat;
        _messages.clear();
        _messages.addAll(chat.messages);
      });
    } else {
      _createNewChat();
    }
    _scrollToBottom();
  }

  void _createNewChat() {
    final welcomeMessage = AiMessage(
      role: 'assistant',
      content:
          'Hello! I\'m your financial AI assistant. I can help you analyze your spending, track budgets, and provide insights about your transactions. What would you like to know?',
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.clear();
      _messages.add(welcomeMessage);
      _currentChat = null;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(AiMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
    _saveCurrentChat();
  }

  Future<void> _saveCurrentChat() async {
    if (_messages.length <= 1) return; // Don't save if only welcome message

    final chatId =
        _currentChat?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final title =
        _currentChat?.title ?? _chatService.generateChatTitle(_messages);

    final chat = AiChat(
      id: chatId,
      title: title,
      messages: _messages,
      createdAt: _currentChat?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final savedChat = await _chatService.saveChat(chat);
    setState(() {
      _currentChat = savedChat;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final userMessage = AiMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);

    setState(() => _isLoading = true);

    try {
      final response = await _aiService.sendMessage(text, _messages);
      _addMessage(response);
    } catch (e) {
      _addMessage(
        AiMessage(
          role: 'assistant',
          content: 'Sorry, I encountered an error: $e',
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onPressed: _showChatMenu,
          ),
        ],
      ),
      drawer: const CustomAppDrawer(),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Show typing indicator as last item when loading
                  return const TypingIndicator();
                }
                return ChatMessageWidget(
                  message: _messages[index],
                  onDelete: (msg) => _deleteMessage(msg),
                  onRetry: (msg) => _retryMessage(msg),
                );
              },
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask about your finances...',
                        filled: true,
                        fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    mini: true,
                    backgroundColor: CustomColors.primary,
                    child: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatMenu() {
    showDialog(
      context: context,
      builder: (context) => AiChatMenuDialog(
        onNewChat: _handleNewChat,
        onDeleteChat: _handleDeleteChat,
        onShowChats: _handleShowChats,
      ),
    );
  }

  void _handleNewChat() {
    _createNewChat();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Started new chat')));
  }

  Future<void> _handleDeleteChat() async {
    if (_currentChat == null) {
      _createNewChat();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentChat != null) {
      await _chatService.deleteChat(_currentChat!.id);
      _createNewChat();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chat deleted')));
      }
    }
  }

  Future<void> _handleShowChats() async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatsScreen(
          currentChatId: _currentChat?.id,
          onSelectChat: _loadChat,
        ),
      ),
    );
  }

  void _loadChat(AiChat chat) {
    setState(() {
      _currentChat = chat;
      _messages.clear();
      _messages.addAll(chat.messages);
    });
    _scrollToBottom();
  }

  void _deleteMessage(AiMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.remove(message);
              });
              _saveCurrentChat();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Message deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _retryMessage(AiMessage message) async {
    // Find the user message that prompted this AI response
    final messageIndex = _messages.indexOf(message);
    if (messageIndex <= 0) return;

    final previousMessage = _messages[messageIndex - 1];
    if (previousMessage.role != 'user') return;

    // Remove the AI response
    setState(() {
      _messages.removeAt(messageIndex);
      _isLoading = true;
    });

    // Retry with the previous user message
    final messenger = ScaffoldMessenger.of(context);
    try {
      final conversationHistory = _messages.take(messageIndex - 1).toList();
      final response = await _aiService.sendMessage(
        previousMessage.content,
        conversationHistory,
      );
      _addMessage(response);
    } catch (e) {
      // Use captured messenger instead of querying context after async gap
      messenger.showSnackBar(
        SnackBar(content: Text('Retry failed: ${e.toString()}')),
      );
    } finally {
      // Avoid returning inside finally (can swallow exceptions). Update state only if mounted.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

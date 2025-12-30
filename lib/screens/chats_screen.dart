import 'package:flutter/material.dart';
import 'package:ledger/services/ai_chat_service.dart';
import 'package:ledger/presets/theme.dart';

class ChatsScreen extends StatefulWidget {
  final String? currentChatId;
  final Function(AiChat) onSelectChat;

  const ChatsScreen({
    super.key,
    required this.currentChatId,
    required this.onSelectChat,
  });

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final AiChatService _chatService = AiChatService();
  List<AiChat> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final chats = await _chatService.loadChats();
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChat(AiChat chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete "${chat.title}"?'),
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

    if (confirmed == true) {
      await _chatService.deleteChat(chat.id);
      await _loadChats();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chat deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          if (_chats.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadChats,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
          ? _buildEmptyState(isDark)
          : _buildChatList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_outlined, size: 120, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No saved chats yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Start a conversation with the AI assistant to create your first chat!',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add_comment),
              label: const Text('Start New Chat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _chats.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 72,
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final isCurrentChat = chat.id == widget.currentChatId;

        return InkWell(
          onTap: () {
            Navigator.pop(context);
            widget.onSelectChat(chat);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrentChat
                  ? (isDark
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.1))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCurrentChat
                        ? CustomColors.primary
                        : (isDark ? Colors.grey[700] : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat,
                    color: isCurrentChat
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.title,
                        style: TextStyle(
                          fontWeight: isCurrentChat
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${chat.messages.length} messages',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(chat.updatedAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  onPressed: () => _deleteChat(chat),
                  tooltip: 'Delete chat',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

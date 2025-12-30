import 'package:flutter/material.dart';
import 'package:ledger/services/ai_chat_service.dart';

class AiChatMenuDialog extends StatelessWidget {
  final VoidCallback onNewChat;
  final VoidCallback onDeleteChat;
  final VoidCallback onShowChats;

  const AiChatMenuDialog({
    super.key,
    required this.onNewChat,
    required this.onDeleteChat,
    required this.onShowChats,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Chat Options'),
      children: [
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            onNewChat();
          },
          child: const Row(
            children: [
              Icon(Icons.add_comment_outlined),
              SizedBox(width: 16),
              Text('New Chat'),
            ],
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            onShowChats();
          },
          child: const Row(
            children: [
              Icon(Icons.chat_bubble_outline),
              SizedBox(width: 16),
              Text('Show Chats'),
            ],
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            onDeleteChat();
          },
          child: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 16),
              Text('Delete Chat', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

class ChatListDialog extends StatelessWidget {
  final List<AiChat> chats;
  final String? currentChatId;
  final Function(AiChat) onSelectChat;
  final Function(AiChat) onDeleteChat;

  const ChatListDialog({
    super.key,
    required this.chats,
    required this.currentChatId,
    required this.onSelectChat,
    required this.onDeleteChat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (chats.isEmpty) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline),
            SizedBox(width: 12),
            Text('Chats'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No saved chats yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation to create your first chat!',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  const SizedBox(width: 12),
                  const Text(
                    'Your Chats',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            // Chat list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: chats.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final isCurrentChat = chat.id == currentChatId;

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onSelectChat(chat);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCurrentChat
                                  ? Colors.green
                                  : (isDark
                                        ? Colors.grey[700]
                                        : Colors.grey[300]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.chat,
                              color: isCurrentChat
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${chat.messages.length} messages · ${_formatDate(chat.updatedAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            onPressed: () => onDeleteChat(chat),
                            tooltip: 'Delete chat',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

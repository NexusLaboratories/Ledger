import 'package:flutter/material.dart';
import 'package:ledger/models/ai_message.dart';
import 'package:ledger/components/ai/chart_renderer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessageWidget extends StatelessWidget {
  final AiMessage message;
  final Function(AiMessage)? onDelete;
  final Function(AiMessage)? onRetry;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onDelete,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
              radius: 18,
              child: Icon(
                Icons.psychology,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser
                      ? Theme.of(context).primaryColor
                      : (isDark ? Colors.grey[850] : Colors.grey[200]),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          fontSize: 15,
                          height: 1.4,
                        ),
                        strong: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        em: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                        ),
                        code: TextStyle(
                          color: isUser
                              ? Colors.white70
                              : (isDark ? Colors.grey[300] : Colors.black54),
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        listBullet: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          fontSize: 15,
                        ),
                      ),
                      selectable: true,
                    ),
                    if (message.chartData != null && message.chartType != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ChartRenderer(
                          chartType: message.chartType!,
                          data: message.chartData!,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 18,
              child: Icon(
                Icons.person,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final isUser = message.role == 'user';

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!(message);
                },
              ),
            if (!isUser && onRetry != null)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry Output'),
                onTap: () {
                  Navigator.pop(context);
                  onRetry!(message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

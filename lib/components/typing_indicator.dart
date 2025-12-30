import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final dotColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology, size: 20, color: Colors.green[700]),
          ),
          const SizedBox(width: 12),
          // Typing bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(0, dotColor!),
                    const SizedBox(width: 4),
                    _buildDot(1, dotColor),
                    const SizedBox(width: 4),
                    _buildDot(2, dotColor),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, Color color) {
    final delay = index * 0.2;
    final value = _controller.value;

    // Calculate opacity based on animation phase
    double opacity;
    if (value < delay) {
      opacity = 0.3;
    } else if (value < delay + 0.3) {
      opacity = 0.3 + ((value - delay) / 0.3) * 0.7;
    } else if (value < delay + 0.6) {
      opacity = 1.0 - ((value - delay - 0.3) / 0.3) * 0.7;
    } else {
      opacity = 0.3;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

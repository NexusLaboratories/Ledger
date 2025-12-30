import 'package:flutter/material.dart';
import 'package:ledger/models/tag.dart';
import 'package:ledger/constants/tag_icons.dart';
import 'package:ledger/presets/app_colors.dart';

class TagChipDisplay extends StatelessWidget {
  final List<String> tagNames;
  final List<Tag>? tags; // Optional: for icon/color display
  final String? emptyMessage;

  const TagChipDisplay({
    super.key,
    required this.tagNames,
    this.tags,
    this.emptyMessage,
  });

  Color _getTagColor(Tag? tag, int index) {
    if (tag?.color != null) {
      return Color(tag!.color!);
    }
    // Generate a color based on tag name or index for consistency
    final hash = (tag?.name ?? tagNames[index]).hashCode;
    final colors = AppColors.tagPalette;
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (tagNames.isEmpty) {
      return Text(
        emptyMessage ?? 'None',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(tagNames.length, (index) {
        final name = tagNames[index];
        final tag = tags?.firstWhere(
          (t) => t.name == name,
          orElse: () => Tag(id: '', name: name),
        );
        final tagColor = _getTagColor(tag, index);
        final tagIcon = TagIcons.getIconById(tag?.iconId);

        return Chip(
          avatar: tagIcon != null
              ? Icon(tagIcon.icon, size: 16, color: tagColor)
              : null,
          label: Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tagColor,
            ),
          ),
          backgroundColor: tagColor.withAlpha(38),
          side: BorderSide(color: tagColor, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }
}

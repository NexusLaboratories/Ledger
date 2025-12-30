import 'package:flutter/material.dart';
import 'package:ledger/components/ui/buttons/custom_button.dart';
import 'package:ledger/models/tag.dart';
import 'package:ledger/services/tag_service.dart';
import 'package:ledger/utilities/utilities.dart';
import 'package:ledger/constants/tag_icons.dart';

class TagFormModal extends StatefulWidget {
  final Tag? existing;
  const TagFormModal({super.key, this.existing});

  @override
  State<TagFormModal> createState() => _TagFormModalState();
}

class _TagFormModalState extends State<TagFormModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TagService _service = TagService();

  String? _selectedIconId;
  Color? _selectedColor;

  static const List<Color> _colorOptions = [
    Color(0xFF43A047), // Green (default)
    Color(0xFFE53935), // Red
    Color(0xFFD81B60), // Pink
    Color(0xFF8E24AA), // Purple
    Color(0xFF5E35B1), // Deep Purple
    Color(0xFF3949AB), // Indigo
    Color(0xFF1E88E5), // Blue
    Color(0xFF039BE5), // Light Blue
    Color(0xFF00ACC1), // Cyan
    Color(0xFF00897B), // Teal
    Color(0xFF7CB342), // Light Green
    Color(0xFFC0CA33), // Lime
    Color(0xFFFDD835), // Yellow
    Color(0xFFFFB300), // Amber
    Color(0xFFFF6F00), // Orange
    Color(0xFFE64A19), // Deep Orange
    Color(0xFF6D4C41), // Brown
    Color(0xFF546E7A), // Blue Grey
    Color(0xFF757575), // Grey
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _descriptionController.text = widget.existing!.description ?? '';
      _selectedIconId = widget.existing!.iconId;
      _selectedColor = widget.existing!.color != null
          ? Color(widget.existing!.color!)
          : null;
    } else {
      // Set default color to green for new tags
      _selectedColor = const Color(0xFF43A047);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final value = _nameController.text.trim();
    if (value.isEmpty) return;

    final tag = Tag(
      id: widget.existing?.id ?? Utilities.generateUuid(),
      userId: 'local',
      parentTagId: null,
      name: value,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      color: _selectedColor?.toARGB32(),
      iconId: _selectedIconId,
    );

    if (widget.existing == null) {
      await _service.createTag(tag);
    } else {
      await _service.updateTag(tag);
    }

    if (mounted) Navigator.pop(context, true);
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: TagIcons.allIcons.length,
            itemBuilder: (context, index) {
              final tagIcon = TagIcons.allIcons[index];
              final isSelected = _selectedIconId == tagIcon.id;
              return InkWell(
                onTap: () {
                  setState(() => _selectedIconId = tagIcon.id);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tagIcon.icon,
                        size: 28,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tagIcon.name,
                        style: TextStyle(
                          fontSize: 8,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedIconId = null);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colorOptions.map((color) {
            final isSelected = _selectedColor?.toARGB32() == color.toARGB32();
            return InkWell(
              onTap: () {
                setState(() => _selectedColor = color);
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedColor = null);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIcon = TagIcons.getIconById(_selectedIconId);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Create Tag' : 'Edit Tag',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Icon and Color Selection Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showIconPicker,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedIcon?.icon ?? Icons.label_outline,
                            color: _selectedColor ?? Colors.grey.shade600,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedIcon?.name ?? 'Select Icon',
                              style: TextStyle(
                                color: selectedIcon != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _selectedColor ?? Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _selectedColor == null
                        ? Icon(Icons.palette, color: Colors.grey.shade600)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: widget.existing == null ? 'Create' : 'Save',
                    onPressed: _handleSubmit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

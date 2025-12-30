import 'package:flutter/material.dart';
import 'package:ledger/components/ui/buttons/custom_button.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/utilities/utilities.dart';
import 'package:ledger/constants/tag_icons.dart';

class CategoryFormModal extends StatefulWidget {
  final Category? existing;
  const CategoryFormModal({super.key, this.existing});

  @override
  State<CategoryFormModal> createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends State<CategoryFormModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final CategoryService _service = CategoryService();
  List<Category> _availableParents = [];
  String? _selectedParentId;
  String? _selectedIconId;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _descriptionController.text = widget.existing!.description ?? '';
      _selectedParentId = widget.existing!.parentCategoryId;
      _selectedIconId = widget.existing!.iconId;
    }
    _loadParentOptions();
  }

  Future<void> _loadParentOptions() async {
    final cats = await _service.fetchCategoriesForUser('local');
    setState(() {
      _availableParents = cats
          .where((c) => c.id != widget.existing?.id)
          .toList();
    });
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

    final category = Category(
      id: widget.existing?.id ?? Utilities.generateUuid(),
      userId: 'local',
      parentCategoryId: _selectedParentId,
      name: value,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      iconId: _selectedIconId,
    );

    if (widget.existing == null) {
      await _service.createCategory(category);
    } else {
      await _service.updateCategory(category);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'Create Category' : 'Edit Category',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // Icon picker
          InkWell(
            onTap: _showIconPicker,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _selectedIconId != null
                          ? (TagIcons.getIconById(_selectedIconId!) ??
                                    TagIcons.defaultIcon)
                                .icon
                          : Icons.category,
                      color: const Color(0xFF43A047),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedIconId != null
                          ? (TagIcons.getIconById(_selectedIconId!)?.name ??
                                'Select Icon')
                          : 'Select Icon (Optional)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _selectedParentId,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No parent'),
              ),
              ..._availableParents.map(
                (p) =>
                    DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedParentId = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Parent Category (optional)',
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
          const SizedBox(height: 8),
        ],
      ),
    );
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
                          ? const Color(0xFF43A047)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? const Color(0xFF43A047).withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tagIcon.icon,
                        size: 28,
                        color: isSelected
                            ? const Color(0xFF43A047)
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tagIcon.name,
                        style: TextStyle(
                          fontSize: 8,
                          color: isSelected
                              ? const Color(0xFF43A047)
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
}

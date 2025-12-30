import 'package:flutter/material.dart';
import 'package:ledger/components/ui/layout/custom_app_drawer.dart';
import 'package:ledger/components/ui/buttons/custom_floating_action_button.dart';
import 'package:ledger/modals/tag_form_modal.dart';
import 'package:ledger/services/tag_service.dart';
import 'package:ledger/models/tag.dart';
import 'package:ledger/screens/tag_detail_screen.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/constants/tag_icons.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final TagService _tagService = TagService();
  late Future<List<Tag>> _tagsFuture;

  @override
  void initState() {
    super.initState();
    _fetchTags();
  }

  void _fetchTags() {
    _tagsFuture = _tagService.fetchTagsForUser('local');
  }

  Future<void> _refresh() async {
    setState(() {
      _fetchTags();
    });
    await _tagsFuture;
  }

  Future<void> _openCreateModal({Tag? editing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TagFormModal(existing: editing),
    );
    if (result == true) {
      await _refresh();
    }
  }

  Future<void> _deleteTag(String id) async {
    await _tagService.deleteTag(id);
    await _refresh();
  }

  Future<void> _showDeleteConfirmation(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: CustomColors.negative),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _deleteTag(id);
    }
  }

  Future<void> _showTagActions(Tag t) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Edit'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: CustomColors.negative),
              title: const Text('Delete'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );

    if (action == 'edit') {
      await _openCreateModal(editing: t);
    } else if (action == 'delete') {
      await _showDeleteConfirmation(t.id, t.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      drawer: const CustomAppDrawer(),
      floatingActionButton: CustomFloatingActionButton(
        icon: Icons.add,
        tooltip: 'Add Tag',
        onPressed: () => _openCreateModal(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Tag>>(
          future: _tagsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final tags = snapshot.data ?? [];
            if (tags.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 64,
                      color: CustomColors.textGreyLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tags found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: CustomColors.textGreyDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to create your first tag',
                      style: TextStyle(
                        fontSize: 14,
                        color: CustomColors.textGreyLight,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final t = tags[index];
                final tagIcon = TagIcons.getIconById(t.iconId);
                final tagColor = t.color != null
                    ? Color(t.color!)
                    : Theme.of(context).primaryColor;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tagColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          tagIcon?.icon ?? Icons.label,
                          color: tagColor,
                        ),
                      ),
                      title: Text(
                        t.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle:
                          t.description != null && t.description!.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                t.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : null,
                      onLongPress: () => _showTagActions(t),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TagDetailScreen(tag: t),
                          ),
                        );
                        await _refresh();
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

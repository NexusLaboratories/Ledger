import 'package:flutter/material.dart';

class FilterItem {
  final String id;
  final String name;
  final String? subtitle;
  final int depth;
  final String? parentId;
  final Set<String> childIds;

  FilterItem({
    required this.id,
    required this.name,
    this.subtitle,
    this.depth = 0,
    this.parentId,
    Set<String>? childIds,
  }) : childIds = childIds ?? {};
}

class FilterSelectionDialog extends StatefulWidget {
  final String title;
  final List<FilterItem> items;
  final Set<String> selectedIds;
  final bool includeMode;

  const FilterSelectionDialog({
    super.key,
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.includeMode,
  });

  @override
  State<FilterSelectionDialog> createState() => _FilterSelectionDialogState();
}

class _FilterSelectionDialogState extends State<FilterSelectionDialog> {
  late Set<String> _selectedIds;
  late bool _includeMode;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
    _includeMode = widget.includeMode;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FilterItem> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    final query = _searchQuery.toLowerCase();
    return widget.items.where((item) {
      return item.name.toLowerCase().contains(query) ||
          (item.subtitle?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop({
                'selectedIds': _selectedIds.toList(),
                'includeMode': _includeMode,
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Include/Exclude mode toggle
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Exclude'),
                        icon: Icon(Icons.block, size: 16),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Include Only'),
                        icon: Icon(Icons.filter_alt, size: 16),
                      ),
                    ],
                    selected: {_includeMode},
                    onSelectionChanged: (Set<bool> selected) {
                      setState(() {
                        _includeMode = selected.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedIds = filteredItems.map((i) => i.id).toSet();
                    });
                  },
                  icon: const Icon(Icons.select_all, size: 18),
                  label: const Text('All'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedIds.clear();
                    });
                  },
                  icon: const Icon(Icons.deselect, size: 18),
                  label: const Text('None'),
                ),
                const Spacer(),
                Text(
                  '${_selectedIds.length} selected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List of items
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No items available'
                          : 'No results found',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isSelected = _selectedIds.contains(item.id);
                      final indentation = item.depth * 20.0;
                      return CheckboxListTile(
                        value: isSelected,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.only(
                          left: 16 + indentation,
                          right: 16,
                        ),
                        title: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(item.name, textAlign: TextAlign.left),
                        ),
                        subtitle: item.subtitle != null
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.subtitle!,
                                  textAlign: TextAlign.left,
                                ),
                              )
                            : null,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              // Select this item and all its descendants
                              _selectedIds.add(item.id);
                              _selectedIds.addAll(item.childIds);
                            } else {
                              // Deselect this item and all its descendants
                              _selectedIds.remove(item.id);
                              _selectedIds.removeAll(item.childIds);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

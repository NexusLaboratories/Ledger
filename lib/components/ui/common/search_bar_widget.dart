import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledger/models/search_filter.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(SearchFilter) onSearch;
  final SearchFilter? initialFilter;
  final bool showFilters;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.initialFilter,
    this.showFilters = true,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _searchController;
  late SearchFilter _currentFilter;
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter ?? const SearchFilter();
    _searchController = TextEditingController(text: _currentFilter.query ?? '');
    _focusNode.addListener(() {
      setState(() {
        _focused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final filter = _currentFilter.copyWith(
      query: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
    widget.onSearch(filter);
  }

  bool get _hasActiveFilters {
    final f = _currentFilter;
    return f.startDate != null ||
        f.endDate != null ||
        f.minAmount != null ||
        f.maxAmount != null ||
        f.accountId != null ||
        f.categoryId != null ||
        (f.tagIds != null && f.tagIds!.isNotEmpty) ||
        f.transactionType != null;
  }

  Future<void> _openFilterSheet() async {
    final temp = _currentFilter;
    final result = await showModalBottomSheet<SearchFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SearchFilterSheet(existing: temp),
      ),
    );
    if (result != null) {
      setState(() {
        _currentFilter = result;
      });
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.search, color: hintColor, size: 20),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search transactions, accounts, tags...',
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: hintColor, fontSize: 15),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: hintColor, size: 20),
              onPressed: () {
                _searchController.clear();
                _performSearch();
                FocusScope.of(context).requestFocus(_focusNode);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (widget.showFilters) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _openFilterSheet,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(Icons.tune, color: hintColor, size: 20),
                  ),
                  if (_hasActiveFilters)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SearchFilterSheet extends StatefulWidget {
  final SearchFilter existing;
  const SearchFilterSheet({super.key, required this.existing});

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late DateTime? _start;
  late DateTime? _end;
  int? _txType;

  @override
  void initState() {
    super.initState();
    _start = widget.existing.startDate;
    _end = widget.existing.endDate;
    _txType = widget.existing.transactionType;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _end = picked);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickStart,
                    child: Text(
                      _start == null
                          ? 'Start date'
                          : DateFormat.yMMMd().format(_start!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickEnd,
                    child: Text(
                      _end == null
                          ? 'End date'
                          : DateFormat.yMMMd().format(_end!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _txType == null,
                    onSelected: (_) => setState(() => _txType = null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Expense'),
                    selected: _txType == 1,
                    onSelected: (_) => setState(() => _txType = 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Income'),
                    selected: _txType == 0,
                    onSelected: (_) => setState(() => _txType = 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(const SearchFilter()),
                  child: const Text('Reset'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    final out = widget.existing.copyWith(
                      startDate: _start,
                      endDate: _end,
                      transactionType: _txType,
                    );
                    Navigator.of(context).pop(out);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

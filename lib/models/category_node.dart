import 'package:ledger/models/category.dart';

class CategoryNode {
  final Category category;
  CategoryNode? parent;
  final List<CategoryNode> children = [];

  CategoryNode(this.category);

  /// Return a list of ancestors starting from the top-most ancestor
  /// down to the parent of this node. (root ancestor -> ... -> parent)
  List<Category> ancestors() {
    final List<Category> result = [];
    CategoryNode? current = parent;
    final stack = <Category>[];
    while (current != null) {
      stack.insert(0, current.category);
      current = current.parent;
    }
    result.addAll(stack);
    return result;
  }

  /// Return all descendants in a flat list
  List<Category> descendants() {
    final List<Category> result = [];
    for (final c in children) {
      result.add(c.category);
      result.addAll(c.descendants());
    }
    return result;
  }
}

/// Build a map id->CategoryNode for the flat category list. Parent relationships
/// will be wired up and children lists appended.
Map<String, CategoryNode> buildCategoryNodeMap(List<Category> categories) {
  final Map<String, CategoryNode> nodes = {};
  for (final c in categories) {
    nodes[c.id] = CategoryNode(c);
  }
  for (final c in categories) {
    final node = nodes[c.id]!;
    if (c.parentCategoryId != null) {
      final parent = nodes[c.parentCategoryId];
      if (parent != null) {
        node.parent = parent;
        parent.children.add(node);
      }
    }
  }
  return nodes;
}

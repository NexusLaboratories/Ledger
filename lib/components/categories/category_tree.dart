import 'package:flutter/material.dart';
import 'package:ledger/models/category_node.dart';

typedef NodeTapCallback = void Function(CategoryNode node);

class CategoryTree extends StatelessWidget {
  final CategoryNode root;
  final NodeTapCallback? onTap;
  final double nodeRadius;
  final double verticalSpacing;

  const CategoryTree({
    super.key,
    required this.root,
    this.onTap,
    this.nodeRadius = 26,
    this.verticalSpacing = 80,
  });

  List<List<CategoryNode>> _computeLevels(CategoryNode root) {
    final levels = <List<CategoryNode>>[];
    final queue = <CategoryNode>[root];
    while (queue.isNotEmpty) {
      final levelSize = queue.length;
      final level = <CategoryNode>[];
      for (int i = 0; i < levelSize; i++) {
        final node = queue.removeAt(0);
        level.add(node);
        queue.addAll(node.children);
      }
      levels.add(level);
    }
    return levels;
  }

  @override
  Widget build(BuildContext context) {
    final levels = _computeLevels(root);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final List<List<Offset>> positions = [];
        for (int i = 0; i < levels.length; i++) {
          final count = levels[i].length;
          final levelPositions = <Offset>[];
          for (int j = 0; j < count; j++) {
            final dx = ((j + 1) * (width / (count + 1))).clamp(
              nodeRadius,
              width - nodeRadius,
            );
            final dy = 40 + i * verticalSpacing;
            levelPositions.add(Offset(dx, dy));
          }
          positions.add(levelPositions);
        }

        final edges = <MapEntry<Offset, Offset>>[];
        for (int i = 0; i < levels.length - 1; i++) {
          final parentLevel = levels[i];
          final childLevel = levels[i + 1];
          for (int p = 0; p < parentLevel.length; p++) {
            final parentNode = parentLevel[p];
            // connect parent to each child in next level that has parent relationship
            for (int c = 0; c < childLevel.length; c++) {
              final childNode = childLevel[c];
              if (childNode.parent == parentNode) {
                edges.add(MapEntry(positions[i][p], positions[i + 1][c]));
              }
            }
          }
        }

        return SizedBox(
          height: levels.length * verticalSpacing + 120,
          child: Stack(
            children: [
              // Paint lines
              CustomPaint(
                size: Size(width, levels.length * verticalSpacing + 120),
                painter: _TreePainter(
                  edges,
                  Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              // Nodes
              for (int i = 0; i < levels.length; i++)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: nodeRadius * 2 + 20,
                      child: Stack(
                        children: [
                          for (int j = 0; j < levels[i].length; j++)
                            Positioned(
                              left: positions[i][j].dx - nodeRadius,
                              top: positions[i][j].dy - nodeRadius - 20,
                              child: GestureDetector(
                                onTap: () {
                                  if (onTap != null) onTap!(levels[i][j]);
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: nodeRadius * 2,
                                      height: nodeRadius * 2,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          levels[i][j].category.name.isNotEmpty
                                              ? levels[i][j].category.name[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: nodeRadius * 4,
                                      child: Text(
                                        levels[i][j].category.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                        key: Key(
                                          'category-node-${levels[i][j].category.id}',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TreePainter extends CustomPainter {
  final List<MapEntry<Offset, Offset>> edges;
  final Color strokeColor;
  _TreePainter(this.edges, this.strokeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final e in edges) {
      final start = e.key;
      final end = e.value;
      // Draw line with slight curve
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final path = Path();
      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(mid.dx, start.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

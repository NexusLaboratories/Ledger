import 'package:flutter/material.dart';

enum IconContainerSize { small, medium, large }

enum IconContainerShape { circle, rounded, square }

class IconContainer extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final IconContainerSize size;
  final IconContainerShape shape;
  final double? iconSize;
  final double? padding;
  final double? borderRadius;

  const IconContainer({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.size = IconContainerSize.medium,
    this.shape = IconContainerShape.rounded,
    this.iconSize,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).primaryColor;

    final (defaultIconSize, defaultPadding) = switch (size) {
      IconContainerSize.small => (16.0, 6.0),
      IconContainerSize.medium => (20.0, 8.0),
      IconContainerSize.large => (24.0, 12.0),
    };

    final effectiveIconSize = iconSize ?? defaultIconSize;
    final effectivePadding = padding ?? defaultPadding;

    final effectiveBorderRadius =
        borderRadius ??
        (switch (shape) {
          IconContainerShape.circle => effectiveIconSize + effectivePadding * 2,
          IconContainerShape.rounded => 8.0,
          IconContainerShape.square => 0.0,
        });

    return Container(
      padding: EdgeInsets.all(effectivePadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? effectiveColor.withAlpha(25),
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
      ),
      child: Icon(icon, size: effectiveIconSize, color: effectiveColor),
    );
  }
}

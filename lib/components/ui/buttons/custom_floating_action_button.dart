import 'package:flutter/material.dart';
import 'package:ledger/presets/theme.dart';

class CustomFloatingActionButton extends StatelessWidget {
  // final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final List<Map<String, dynamic>>? menuOptions;
  final void Function()? onPressed;

  const CustomFloatingActionButton({
    super.key,
    // required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
    this.menuOptions,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return (menuOptions == null)
        ? FloatingActionButton(
            shape: CircleBorder(),
            backgroundColor: CustomColors.primary,
            foregroundColor: Colors.white,
            onPressed: onPressed,
            child: Icon(icon),
          )
        : PopupMenuButton<String>(
            tooltip: tooltip,
            child: FloatingActionButton(
              onPressed: null,
              shape: CircleBorder(),
              backgroundColor: CustomColors.primary,
              foregroundColor: Colors.white,
              child: Icon(icon),
            ),
            onSelected: (value) {
              final selectedOption = menuOptions!.firstWhere(
                (option) => option['title'] == value,
              );
              selectedOption['onTap']();
            },
            itemBuilder: (context) => menuOptions!.map((option) {
              return PopupMenuItem<String>(
                value: option['title'],
                child: Text(option['title']),
              );
            }).toList(),
          );
  }
}

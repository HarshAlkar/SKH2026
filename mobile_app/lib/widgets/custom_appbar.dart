import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      actions: actions,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

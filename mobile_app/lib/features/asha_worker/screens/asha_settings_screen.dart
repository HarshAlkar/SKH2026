import 'package:flutter/material.dart';
import '../../profile/screens/settings_screen.dart';

class AshaSettingsScreen extends StatelessWidget {
  final bool embedded;
  const AshaSettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(embedded: embedded);
  }
}

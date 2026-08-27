import 'package:flutter/material.dart';
import '../../profile/screens/profile_screen.dart';

class DoctorProfileScreen extends StatelessWidget {
  final bool embedded;
  const DoctorProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(embedded: embedded);
  }
}

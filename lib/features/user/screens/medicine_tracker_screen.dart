import 'package:flutter/material.dart';

class MedicineTrackerScreen extends StatelessWidget {
  const MedicineTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Tracker')),
      body: const Center(child: Text('Track your daily medicines here')),
    );
  }
}

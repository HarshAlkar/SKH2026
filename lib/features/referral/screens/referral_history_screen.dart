import 'package:flutter/material.dart';

class ReferralHistoryScreen extends StatelessWidget {
  const ReferralHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Referral History",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2F4DB6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text("Referral history records will appear here."),
      ),
    );
  }
}

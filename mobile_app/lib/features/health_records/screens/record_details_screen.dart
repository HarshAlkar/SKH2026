import 'package:flutter/material.dart';

class RecordDetailsScreen extends StatelessWidget {
  const RecordDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Record Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2F4DB6),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text("Detailed Patient Statistics coming soon..."),
      ),
    );
  }
}

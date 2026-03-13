import 'package:flutter/material.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Support"),
        backgroundColor: const Color(0xFF2F4DB6),
      ),
      body: const Center(child: Text("Contact Support Screen Coming Soon")),
    );
  }
}

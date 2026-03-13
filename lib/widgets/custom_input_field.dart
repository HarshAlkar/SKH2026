import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final bool isPassword;
  final TextEditingController? controller;

  const CustomInputField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}

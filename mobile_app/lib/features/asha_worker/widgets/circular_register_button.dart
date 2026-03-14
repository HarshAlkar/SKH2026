import 'package:flutter/material.dart';

class CircularRegisterButton extends StatelessWidget {
  final VoidCallback onTap;

  const CircularRegisterButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const Color registerBlue = Color(0xFF2F4DB6);

    return Tooltip(
      message: "Register New Patient",
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: registerBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: registerBlue.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const Icon(
              Icons.person_add_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../screens/register_patient_screen.dart';

class AddPatientButton extends StatelessWidget {
  final VoidCallback? onPatientAdded;

  const AddPatientButton({super.key, this.onPatientAdded});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const RegisterPatientScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
          if (result == true) {
            onPatientAdded?.call();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2F4DB6),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2F4DB6).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: const Tooltip(
            message: "Add Patient",
            child: Icon(Icons.person_add, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

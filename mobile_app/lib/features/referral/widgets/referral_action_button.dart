import 'package:flutter/material.dart';

class ReferralActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  const ReferralActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2F4DB6);
    
    return SizedBox(
      width: double.infinity,
      child: isSecondary
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 24, color: primaryBlue),
              label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryBlue, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 24, color: Colors.white),
              label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
            ),
    );
  }
}

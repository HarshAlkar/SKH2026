import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class VillageDropdownField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String hint;
  final Color accentColor;
  final Color fillColor;
  final IconData icon;
  final String? Function(String?)? validator;

  const VillageDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Village',
    this.hint = 'Select village',
    this.accentColor = const Color(0xFF10B981),
    this.fillColor = const Color(0xFFF5F7FA),
    this.icon = Icons.home_outlined,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final items = AppConstants.villageDropdownItems(current: value);
    final selected = (value != null && items.contains(value)) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selected,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF94A3B8),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: Icon(icon, color: accentColor, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          items: items
              .map(
                (village) => DropdownMenuItem<String>(
                  value: village,
                  child: Text(village, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: validator ??
              (v) => (v == null || v.trim().isEmpty)
                  ? 'Please select a village'
                  : null,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class CustomDropdownField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData? prefixIcon;
  final List<String> items;
  final String? value;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.hintText,
    this.prefixIcon,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: const Color(0xFF2F4DB6))
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2F4DB6),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}

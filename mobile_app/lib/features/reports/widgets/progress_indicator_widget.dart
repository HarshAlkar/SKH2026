import 'package:flutter/material.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final String label;
  final String percentageText;
  final double percentageValue;
  final Color activeColor;
  final Color backgroundColor;

  const ProgressIndicatorWidget({
    super.key,
    required this.label,
    required this.percentageText,
    required this.percentageValue,
    this.activeColor = const Color(0xFF2F4DB6),
    this.backgroundColor = const Color(0xFFE8F1FF),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              percentageText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentageValue,
            minHeight: 8,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          ),
        ),
      ],
    );
  }
}

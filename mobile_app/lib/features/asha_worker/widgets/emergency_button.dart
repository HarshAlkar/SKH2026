import 'package:flutter/material.dart';

class EmergencyButton extends StatefulWidget {
  final VoidCallback onTap;

  const EmergencyButton({super.key, required this.onTap});

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color emergencyRed = Color(0xFFE53935);

    return ScaleTransition(
      scale: _animation,
      child: Tooltip(
        message: "Emergency Referral",
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: emergencyRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: emergencyRed.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 5,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              customBorder: const CircleBorder(),
              child: const Icon(
                Icons.emergency_share,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

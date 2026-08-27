import 'dart:io';

import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class ProfileAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;

  const ProfileAvatar({
    super.key,
    required this.user,
    this.radius = 40,
    this.onTap,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    final pendingPath = user?.pendingPhotoPath;
    ImageProvider? image;
    if (pendingPath != null && pendingPath.isNotEmpty) {
      final file = File(pendingPath);
      if (file.existsSync()) {
        image = FileImage(file);
      }
    }
    final url = image == null ? user?.resolvedPhotoUrl : null;
    if (image == null && url != null) {
      image = NetworkImage(url);
    }
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: image,
      child: image == null
          ? Icon(Icons.person, size: radius, color: iconColor)
          : null,
    );
    if (onTap == null) return avatar;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatar,
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF2A7DE1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(Icons.camera_alt, size: radius * 0.32, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class Patient {
  final String id;
  final String userId;
  final String name;
  final String age;
  final String village;
  final String lastVisit;
  final String status;
  final Color statusColor;
  final String abhaId;

  Patient({
    required this.id,
    required this.userId,
    required this.name,
    required this.age,
    required this.village,
    required this.lastVisit,
    required this.status,
    required this.statusColor,
    required this.abhaId,
  });
}

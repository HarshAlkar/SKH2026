import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage Service (Hive & SharedPreferences)
  await StorageService.init();

  runApp(const GraminHealthApp());
}

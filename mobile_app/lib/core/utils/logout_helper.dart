import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class LogoutHelper {
  LogoutHelper._();

  static Future<void> logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.roleSelection,
      (route) => false,
    );
  }
}

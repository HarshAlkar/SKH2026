import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';

class SessionSplashScreen extends StatefulWidget {
  const SessionSplashScreen({super.key});

  @override
  State<SessionSplashScreen> createState() => _SessionSplashScreenState();
}

class _SessionSplashScreenState extends State<SessionSplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    final auth = context.read<AuthProvider>();
    await auth.ensureLoaded();
    if (!mounted) return;

    String route = AppRoutes.roleSelection;
    if (auth.isAuthenticated) {
      switch (auth.user!.role) {
        case 'doctor':
          route = AppRoutes.doctorDashboard;
          break;
        case 'asha_worker':
          route = AppRoutes.ashaDashboard;
          break;
        default:
          route = AppRoutes.userDashboard;
      }
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

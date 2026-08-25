import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../widgets/asha_sidebar.dart';

class AshaSettingsScreen extends StatefulWidget {
  final bool embedded;
  const AshaSettingsScreen({super.key, this.embedded = false});

  @override
  State<AshaSettingsScreen> createState() => _AshaSettingsScreenState();
}

class _AshaSettingsScreenState extends State<AshaSettingsScreen> {
  late final TextEditingController _hostController;
  bool _savingHost = false;

  final Color primaryColor = const Color(0xFF2A7DE1);

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: AppConfig.host);
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _saveHost() async {
    final value = _hostController.text.trim();
    if (value.isEmpty) return;
    setState(() => _savingHost = true);
    await AppConfig.setHost(value);
    if (!mounted) return;
    setState(() => _savingHost = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Server host saved: $value'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: widget.embedded ? null : const AshaSidebar(),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: !widget.embedded,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'PROFILE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow(Icons.person_outline, 'Name', user?.name ?? '—'),
                  const Divider(height: 24),
                  _infoRow(
                    Icons.phone_outlined,
                    'Phone',
                    user?.phoneNumber ?? '—',
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    Icons.location_on_outlined,
                    'Village',
                    user?.village ?? '—',
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    Icons.badge_outlined,
                    'Role',
                    user?.role ?? 'asha_worker',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'SERVER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _hostController,
                    decoration: InputDecoration(
                      labelText: 'Server host',
                      hintText: '10.0.2.2 or PC Wi-Fi IP',
                      prefixIcon: const Icon(Icons.dns_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Emulator: 10.0.2.2 · Physical device: your PC LAN IP. '
                    'Django must listen on 0.0.0.0:8000.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _savingHost ? null : _saveHost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _savingHost
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Host'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../../chat/widgets/contact_action_row.dart';
import '../../chat/widgets/directory_contact_card.dart';
import '../widgets/user_sidebar.dart';

class AshaWorkersScreen extends StatefulWidget {
  const AshaWorkersScreen({super.key});

  @override
  State<AshaWorkersScreen> createState() => _AshaWorkersScreenState();
}

class _AshaWorkersScreenState extends State<AshaWorkersScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _workers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/users/asha-workers/');
      if (!mounted) return;
      setState(() {
        _workers = data is List ? List<Map<String, dynamic>>.from(data) : [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const UserSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'ASHA Workers',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatInboxScreen()),
              );
            },
            icon: const Icon(Icons.chat_outlined, color: AppColors.primary),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _workers.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              const Icon(Icons.health_and_safety_outlined, size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              const Text(
                                'No ASHA worker found for your village.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Village on your profile: ${context.read<AuthProvider>().user?.village.isNotEmpty == true ? context.read<AuthProvider>().user!.village : 'not set'}. Update it in Profile if this is wrong.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
                                child: const Text('Update profile village'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _workers.length,
                      itemBuilder: (context, index) {
                        final asha = _workers[index];
                        final details = asha['profile_details'] is Map
                            ? Map<String, dynamic>.from(asha['profile_details'] as Map)
                            : <String, dynamic>{};
                        final peerId = parseContactId(asha['id']);
                        if (peerId == null) return const SizedBox.shrink();
                        final village = details['assigned_village'] ?? asha['village'] ?? '—';
                        final phc = details['phc_center']?.toString() ?? '';
                        return DirectoryContactCard(
                          name: contactName(asha),
                          subtitle: [
                            'Village: $village',
                            if (phc.isNotEmpty) 'PHC: $phc',
                          ].join(' · '),
                          phone: contactPhone(asha),
                          peerUserId: peerId,
                          ashaId: peerId,
                          avatarIcon: Icons.health_and_safety_outlined,
                          accentColor: const Color(0xFF0F766E),
                        );
                      },
                    ),
            ),
    );
  }
}

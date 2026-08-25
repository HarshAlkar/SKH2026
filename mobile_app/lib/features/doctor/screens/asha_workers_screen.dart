import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../../chat/widgets/contact_action_row.dart';
import '../../chat/widgets/directory_contact_card.dart';

class DoctorAshaWorkersScreen extends StatefulWidget {
  final bool embedded;
  const DoctorAshaWorkersScreen({super.key, this.embedded = false});

  @override
  State<DoctorAshaWorkersScreen> createState() => _DoctorAshaWorkersScreenState();
}

class _DoctorAshaWorkersScreenState extends State<DoctorAshaWorkersScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _workers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? village}) async {
    setState(() => _loading = true);
    try {
      final query = (village ?? _searchController.text).trim();
      final path = query.isEmpty
          ? '/users/asha-workers/'
          : '/users/asha-workers/?village=${Uri.encodeQueryComponent(query)}';
      final data = await _api.get(path);
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
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          'ASHA Workers',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
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
            icon: const Icon(Icons.chat_outlined, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) => _load(village: value),
              decoration: InputDecoration(
                hintText: 'Search by village or district...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  onPressed: () => _load(village: _searchController.text),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _workers.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('No ASHA workers found')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _workers.length,
                            itemBuilder: (context, index) {
                              final asha = _workers[index];
                              final details = asha['profile_details'] is Map
                                  ? Map<String, dynamic>.from(
                                      asha['profile_details'] as Map,
                                    )
                                  : <String, dynamic>{};
                              final peerId = parseContactId(asha['id']);
                              if (peerId == null) return const SizedBox.shrink();
                              final village =
                                  details['assigned_village'] ?? asha['village'] ?? '—';
                              final district = details['district']?.toString() ?? '';
                              return DirectoryContactCard(
                                name: contactName(asha),
                                subtitle: [
                                  'Village: $village',
                                  if (district.isNotEmpty) district,
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
          ),
        ],
      ),
    );
  }
}

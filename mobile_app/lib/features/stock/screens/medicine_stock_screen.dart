import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/sync/offline_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../../models/medicine_stock_model.dart';
import '../../../providers/auth_provider.dart';
import '../../asha_worker/widgets/asha_sidebar.dart';
import '../../doctor/widgets/doctor_navigation_drawer.dart';
import '../../user/widgets/user_sidebar.dart';
import 'update_stock_screen.dart';

/// Shared stock list: ASHA can update; doctor/patient are read-only.
class MedicineStockScreen extends StatefulWidget {
  final bool canUpdate;

  const MedicineStockScreen({super.key, this.canUpdate = false});

  @override
  State<MedicineStockScreen> createState() => _MedicineStockScreenState();
}

class _MedicineStockScreenState extends State<MedicineStockScreen> {
  final _search = TextEditingController();
  List<MedicineStockModel> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = _search.text.trim();
      final path = q.isEmpty
          ? '/stock/batches/'
          : '/stock/batches/?q=${Uri.encodeQueryComponent(q)}';
      final data = await OfflineApi.instance.get(path);
      final list = data is List
          ? data
          : (data is Map && data['results'] is List)
              ? data['results'] as List
              : <dynamic>[];
      setState(() {
        _rows = list
            .whereType<Map>()
            .map((e) => MedicineStockModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'low_stock':
        return Colors.orange;
      case 'expiring':
        return Colors.deepOrange;
      case 'expired':
      case 'out_of_stock':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(String status) =>
      status.replaceAll('_', ' ').toUpperCase();

  Widget? _drawer(BuildContext context) {
    final role = context.read<AuthProvider>().user?.role;
    if (role == 'asha_worker') return const AshaSidebar();
    if (role == 'doctor') {
      return const DoctorNavigationDrawer(activeRoute: 'Medicine Stock');
    }
    return const UserSidebar();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.canUpdate ? 'Update Stock' : 'Medicine Stock';
    return Scaffold(
      drawer: _drawer(context),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: widget.canUpdate
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpdateStockScreen()),
                );
                _load();
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Adjust'),
            )
          : null,
      body: Column(
        children: [
          if (widget.canUpdate) const SyncStatusBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search medicine or batch…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _load,
                ),
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              ),
            )
          else if (_rows.isEmpty)
            const Expanded(child: Center(child: Text('No stock found')))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = _rows[i];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: widget.canUpdate
                            ? () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UpdateStockScreen(batch: r),
                                  ),
                                );
                                _load();
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _statusColor(r.status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.medication, color: _statusColor(r.status)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.medicineName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${r.batchNo} · ${r.facilityName.isEmpty ? r.facilityVillage : r.facilityName}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        Text(
                                          '${r.quantity} ${r.unit}',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _statusColor(r.status).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _statusLabel(r.status),
                                            style: TextStyle(
                                              color: _statusColor(r.status),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Exp: ${r.expiryDate}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: (r.daysToExpiry != null && r.daysToExpiry! <= 30)
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.canUpdate)
                                const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
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

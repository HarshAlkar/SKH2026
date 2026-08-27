import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/pdf_service.dart';
import '../../../core/sync/local_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../doctor/widgets/doctor_navigation_drawer.dart';
import '../../user/services/doctor_service.dart';

class CallHistoryScreen extends StatefulWidget {
  final bool showDoctorDrawer;

  const CallHistoryScreen({super.key, this.showDoctorDrawer = false});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final cached = await LocalStore.instance.getCache('consultation_history');
    if (cached is List && mounted) {
      setState(() {
        _records = cached
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoading = false;
      });
    }
    try {
      final list = await DoctorService().getConsultationHistory();
      await LocalStore.instance.putCache('consultation_history', list);
      if (!mounted) return;
      setState(() {
        _records = list;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _peerName(Map<String, dynamic> record) {
    final role = context.read<AuthProvider>().user?.role ?? 'user';
    if (role == 'doctor') {
      return (record['patient_name'] ?? record['asha_name'] ?? 'Patient').toString();
    }
    if (role == 'asha_worker') {
      final details = record['doctor_details'];
      final fromDetails = details is Map ? details['full_name'] : null;
      return (record['doctor_name'] ?? fromDetails ?? record['patient_name'] ?? 'Contact')
          .toString();
    }
    final details = record['doctor_details'];
    final fromDetails = details is Map ? details['full_name'] : null;
    return (record['doctor_name'] ?? fromDetails ?? record['asha_name'] ?? 'Doctor').toString();
  }

  String _callType(Map<String, dynamic> record) {
    return (record['call_type'] ?? 'VIDEO').toString().toUpperCase();
  }

  String _statusLabel(Map<String, dynamic> record) {
    final status = (record['status'] ?? 'PENDING').toString().toUpperCase();
    switch (status) {
      case 'COMPLETED':
        return 'Completed';
      case 'ONGOING':
        return 'Ongoing';
      case 'CANCELLED':
        return 'Missed';
      default:
        return record['end_time'] == null ? 'Missed' : 'Completed';
    }
  }

  String _dateLabel(Map<String, dynamic> record) {
    final raw = record['created_at']?.toString() ?? '';
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw.split('T').first;
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}  $hh:$mm';
  }

  String _durationLabel(Map<String, dynamic> record) {
    final start = DateTime.tryParse(record['created_at']?.toString() ?? '');
    final end = DateTime.tryParse(record['end_time']?.toString() ?? '');
    if (start == null || end == null) return '—';
    final d = end.difference(start);
    if (d.isNegative) return '—';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m <= 0) return '${s}s';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  List<Map<String, dynamic>> _filtered(String filter) {
    return _records.where((record) {
      final type = _callType(record);
      if (filter == 'VIDEO') return type == 'VIDEO';
      if (filter == 'AUDIO') return type == 'AUDIO';
      return true;
    }).toList();
  }

  Future<void> _download(Map<String, dynamic> record) async {
    try {
      final path = await PdfService.generateCallRecordPdf(
        {
          'id': record['id'],
          'peer_name': _peerName(record),
          'call_type': _callType(record),
          'status': _statusLabel(record),
          'date': _dateLabel(record),
          'duration': _durationLabel(record),
          'notes': record['notes'] ?? '',
        },
        context: context,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save record: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: (widget.showDoctorDrawer ||
              context.watch<AuthProvider>().user?.role == 'doctor')
          ? const DoctorNavigationDrawer(activeRoute: 'Consultations')
          : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Call History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: const Color(0xFF94A3B8),
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Video'),
              Tab(text: 'Audio'),
            ],
          ),
        ),
      ),
      body: _isLoading && _records.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList('ALL'),
                _buildList('VIDEO'),
                _buildList('AUDIO'),
              ],
            ),
    );
  }

  Widget _buildList(String filter) {
    final items = _filtered(filter);
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No call records yet.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildCard(items[index]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> record) {
    final isVideo = _callType(record) == 'VIDEO';
    final status = _statusLabel(record);
    final isCompleted = status == 'Completed';
    final badgeBg = isCompleted ? const Color(0xFFD1FAE5) : const Color(0xFFE8F1FF);
    final badgeFg = isCompleted ? const Color(0xFF059669) : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.lightBlue,
                child: Icon(
                  isVideo ? Icons.videocam : Icons.call,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _peerName(record),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isVideo ? 'Video call' : 'Audio call'} · ${_durationLabel(record)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: badgeFg,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  _dateLabel(record),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Download record',
                onPressed: () => _download(record),
                icon: const Icon(Icons.download_outlined, color: Color(0xFF475569)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

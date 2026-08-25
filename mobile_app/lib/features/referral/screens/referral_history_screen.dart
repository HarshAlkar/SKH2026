import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../asha_worker/widgets/asha_sidebar.dart';

class ReferralHistoryScreen extends StatefulWidget {
  const ReferralHistoryScreen({super.key});

  @override
  State<ReferralHistoryScreen> createState() => _ReferralHistoryScreenState();
}

class _ReferralHistoryScreenState extends State<ReferralHistoryScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get('/alerts/referrals/');
      final list = response is List ? response : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _rows = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load referrals. Pull to retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AshaSidebar(),
      appBar: AppBar(
        title: const Text(
          'Referral History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2F4DB6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(child: Text(_error!)),
                        const SizedBox(height: 12),
                        Center(
                          child: ElevatedButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    )
                  : _rows.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No referrals yet')),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _rows.length,
                          itemBuilder: (context, index) {
                            final row = _rows[index];
                            return ListTile(
                              title: Text(
                                row['patient_name']?.toString() ?? 'Patient',
                              ),
                              subtitle: Text(
                                '${row['severity']} • ${row['status']}\n${row['symptoms'] ?? ''}',
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
            ),
    );
  }
}

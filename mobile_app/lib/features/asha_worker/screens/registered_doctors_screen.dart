import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../chat/widgets/contact_action_row.dart';
import '../widgets/asha_sidebar.dart';

class RegisteredDoctorsScreen extends StatefulWidget {
  final int? forPatientId;
  const RegisteredDoctorsScreen({super.key, this.forPatientId});

  @override
  State<RegisteredDoctorsScreen> createState() => _RegisteredDoctorsScreenState();
}

class _RegisteredDoctorsScreenState extends State<RegisteredDoctorsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _doctors = [];
  bool _isLoading = true;

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color textPrimary = const Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get('/doctors/');
      setState(() {
        _doctors = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AshaSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Registered Doctors',
          style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDoctors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDoctors,
              child: _doctors.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No doctors registered yet')),
                      ],
                    )
                  : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.medical_services, color: primaryBlue, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctor['full_name'] ?? doctor['name'] ?? 'Dr. Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      doctor['specialization'] ?? 'General Physician',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if ((doctor['phone_number'] ?? '').toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          doctor['phone_number'].toString(),
                                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (doctor['is_available'] ?? true) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  (doctor['is_available'] ?? true) ? 'Available' : 'Busy',
                                  style: TextStyle(
                                    color: (doctor['is_available'] ?? true) ? Colors.green : Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ContactActionRow(
                            peerName: doctor['full_name']?.toString() ?? doctor['name']?.toString() ?? 'Doctor',
                            peerUserId: parseContactId(doctor['user_id']) ?? 0,
                            doctorId: parseContactId(doctor['id']),
                            patientId: widget.forPatientId,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }
}

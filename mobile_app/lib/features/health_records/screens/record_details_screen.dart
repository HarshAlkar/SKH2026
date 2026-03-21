import 'package:flutter/material.dart';
import '../../patient/models/patient_model.dart';
import '../models/health_record_model.dart';
import '../widgets/health_record_card.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class RecordDetailsScreen extends StatefulWidget {
  final PatientModel patient;

  const RecordDetailsScreen({super.key, required this.patient});

  @override
  State<RecordDetailsScreen> createState() => _RecordDetailsScreenState();
}

class _RecordDetailsScreenState extends State<RecordDetailsScreen> {
  final ApiService _apiService = ApiService();
  List<HealthRecordModel> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
     try {
       // Append patient_id as a query param
       final patientIdStr = widget.patient.id?.toString() ?? '';
       final response = await _apiService.get('${ApiConstants.recordsEndpoint}?patient_id=$patientIdStr');
       final List<HealthRecordModel> fetched = (response as List)
          .map((data) => HealthRecordModel.fromJson(data))
          .toList();

       if (mounted) {
         setState(() {
           _records = fetched;
           _isLoading = false;
         });
       }
     } catch (e) {
       if (mounted) {
         setState(() {
           _error = e.toString();
           _isLoading = false;
         });
       }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.patient.name}'s Records",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2F4DB6),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Stats
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                   const CircleAvatar(
                     backgroundColor: Color(0xFFE8F1FF),
                     radius: 30,
                     child: Icon(Icons.person, size: 30, color: Color(0xFF005BBC)),
                   ),
                   const SizedBox(width: 20),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(widget.patient.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 4),
                         Text("Age: ${widget.patient.age}  •  ${widget.patient.village}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                       ],
                     )
                   )
                ]
              )
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            
            // Background List Section
            Expanded(
              child: Container(
                color: const Color(0xFFF5F7FA),
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null 
                    ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                    : _records.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.monitor_heart_outlined, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("No health records found for this patient.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          )
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            return HealthRecordCard(record: _records[index]);
                          }
                        )
              ),
            )
          ]
        )
      ),
    );
  }
}

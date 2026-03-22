import 'package:flutter/material.dart';
import 'package:hs053/core/widgets/common_appbar.dart';
import 'package:hs053/core/routes/app_routes.dart';
import 'package:hs053/features/asha_worker/widgets/asha_drawer.dart';
import 'package:hs053/shared/models/health_record_model.dart';
import '../widgets/health_record_card.dart';
import 'package:hs053/features/patient/screens/register_patient_screen.dart';
import 'package:hs053/core/services/api_service.dart';
import 'package:hs053/core/constants/api_constants.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<HealthRecordModel> _allRecords = [];
  List<HealthRecordModel> _filteredRecords = [];
  bool _isLoading = true;
  String? _error;

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get(ApiConstants.recordsEndpoint);
      final List<HealthRecordModel> fetched = (response as List)
          .map((data) => HealthRecordModel.fromJson(data))
          .toList();

      setState(() {
        _allRecords = fetched;
        _filteredRecords = _allRecords;
        _isLoading = false;
      });
      _filterRecords(_searchController.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = _allRecords;
      } else {
        _filteredRecords = _allRecords
            .where((record) =>
                record.patientName.toLowerCase().contains(query.toLowerCase()) ||
                record.village.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CommonAppBar(title: "Health Records"),
      drawer: const AshaDrawer(currentRoute: AppRoutes.healthRecords),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegisterPatientScreen(),
            ),
          ).then((value) {
            if (value == true) {
              _fetchRecords();
            }
          });
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterRecords,
                  decoration: InputDecoration(
                    hintText: 'Search patient records...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ),
            
            // Health Record List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                              const SizedBox(height: 16),
                              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchRecords,
                                child: const Text('Retry'),
                              )
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchRecords,
                          child: _filteredRecords.isEmpty
                              ? ListView(
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(40.0),
                                      child: Center(
                                        child: Text(
                                          "No health records found.",
                                          style: TextStyle(color: Colors.grey, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _filteredRecords.length,
                                  itemBuilder: (context, index) {
                                    return HealthRecordCard(record: _filteredRecords[index]);
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

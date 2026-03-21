import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/report_model.dart';
import '../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  final ImagePicker _picker = ImagePicker();

  List<ReportModel> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final reports = await _reportService.getUserReports();
      if (mounted) {
        setState(() {
          _reports = reports;
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

  Future<void> _pickAndUpload() async {
    final XFile? image = await showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Upload Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take Photo'),
            onTap: () async {
              final picked = await _picker.pickImage(source: ImageSource.camera);
              Navigator.pop(ctx, picked);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              final picked = await _picker.pickImage(source: ImageSource.gallery);
              Navigator.pop(ctx, picked);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (image != null) {
      _showUploadDialog(File(image.path));
    }
  }

  void _showUploadDialog(File file) {
    final titleCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'Lab Report');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isUploading = false;
          return AlertDialog(
            title: const Text('Report Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title (e.g., Blood Test)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: typeCtrl.text,
                  items: ['Lab Report', 'Prescription', 'X-Ray', 'Other']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) typeCtrl.text = val;
                  },
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  if (titleCtrl.text.isEmpty) return;
                  setDialogState(() => isUploading = true);
                  try {
                    await _reportService.uploadReport(
                      title: titleCtrl.text,
                      reportType: typeCtrl.text,
                      description: '',
                      file: file,
                    );
                    Navigator.pop(context);
                    _loadReports();
                    Helpers.showSnackBar(this.context, 'Report uploaded successfully');
                  } catch (e) {
                    setDialogState(() => isUploading = false);
                    Helpers.showSnackBar(this.context, 'Upload failed: $e', isError: true);
                  }
                },
                child: isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Upload'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _deleteReport(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _reportService.deleteReport(id);
        _loadReports();
        Helpers.showSnackBar(context, 'Report deleted');
      } catch (e) {
        Helpers.showSnackBar(context, 'Delete failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Reports'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUpload,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload New', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      return _buildReportCard(report);
                    },
                  ),
                ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  '${report.reportType} · ${DateFormat('MMM d, yyyy').format(DateTime.parse(report.createdAt))}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            onPressed: () => _deleteReport(report.id),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No reports found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            'Upload your lab reports, prescriptions, or\nmedical documents to keep them safe.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadReports,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

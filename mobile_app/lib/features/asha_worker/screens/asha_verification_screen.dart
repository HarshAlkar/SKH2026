import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../providers/auth_provider.dart';

class AshaVerificationScreen extends StatefulWidget {
  const AshaVerificationScreen({super.key});

  @override
  State<AshaVerificationScreen> createState() => _AshaVerificationScreenState();
}

class _AshaVerificationScreenState extends State<AshaVerificationScreen> {
  final ApiService _api = ApiService();
  bool _isUploading = false;
  String? _uploadingType;

  PlatformFile? _idProofFile;
  PlatformFile? _assignmentProofFile;

  bool _idProofUploaded = false;
  bool _assignmentProofUploaded = false;

  @override
  void initState() {
    super.initState();
    _checkUploadedDocs();
  }

  void _checkUploadedDocs() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final docs = user.getDetail('documents');
      if (docs is List) {
        for (var doc in docs) {
          if (doc is Map) {
            if (doc['document_type'] == 'id_proof') _idProofUploaded = true;
            if (doc['document_type'] == 'assignment_proof') _assignmentProofUploaded = true;
          }
        }
      }
    }
  }

  Future<List<int>> _fileBytes(PlatformFile pfile) async {
    return pfile.readAsBytes();
  }

  Future<void> _pickAndUpload(String type) async {
    try {
      final List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result.isEmpty) return;
      final picked = result.first;
      setState(() {
        if (type == 'id_proof') {
          _idProofFile = picked;
        } else {
          _assignmentProofFile = picked;
        }
      });
      await _uploadDocument(type, picked);
    } catch (e) {
      if (!mounted) return;
      if (e.toString().toLowerCase().contains('cancel')) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick file: $e')));
    }
  }

  Future<void> _uploadDocument(String type, PlatformFile pfile) async {
    setState(() {
      _isUploading = true;
      _uploadingType = type;
    });
    try {
      final bytes = await _fileBytes(pfile);
      if (bytes.isEmpty) {
        throw Exception('Could not read the selected file. Try another image or PDF.');
      }
      await _api.postMultipart(
        '/asha_workers/upload_document/',
        fileBytes: bytes,
        fileName: pfile.name,
        field: 'file',
        fields: {'document_type': type},
      );

      setState(() {
        if (type == 'id_proof') _idProofUploaded = true;
        if (type == 'assignment_proof') _assignmentProofUploaded = true;
      });
      await context.read<AuthProvider>().refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingType = null;
        });
      }
    }
  }

  Future<void> _submitVerification() async {
    setState(() { _isUploading = true; });
    try {
      await _api.post('/asha_workers/submit_verification/', body: {});
      await context.read<AuthProvider>().refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification submitted. An admin will review your documents.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() { _isUploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Complete Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete Your ASHA Worker Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload your ID and assignment proof. After you submit, the request appears on the web admin portal for approval.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),

            _buildDocSection(
              title: 'Government ID Proof',
              type: 'id_proof',
              file: _idProofFile,
              isUploaded: _idProofUploaded,
            ),
            const SizedBox(height: 16),
            _buildDocSection(
              title: 'Village/Health Center Assignment Proof',
              type: 'assignment_proof',
              file: _assignmentProofFile,
              isUploaded: _assignmentProofUploaded,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isUploading || (!_idProofUploaded || !_assignmentProofUploaded)) ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2A7DE1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUploading && _uploadingType == null
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit for Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocSection({required String title, required String type, PlatformFile? file, required bool isUploaded}) {
    final busy = _isUploading && _uploadingType == type;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Text('Required', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (isUploaded)
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(child: Text('Uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                TextButton(
                  onPressed: _isUploading ? null : () => _pickAndUpload(type),
                  child: const Text('Replace'),
                ),
              ],
            )
          else if (busy)
            const Row(
              children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Uploading…'),
              ],
            )
          else ...[
            if (file != null)
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          file.extension?.toLowerCase() == 'pdf'
                            ? Icons.picture_as_pdf
                            : Icons.image,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(file.name, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cloud_upload, color: Color(0xFF2A7DE1)),
                    onPressed: _isUploading ? null : () => _uploadDocument(type, file),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _isUploading ? null : () => _pickAndUpload(type),
                icon: const Icon(Icons.attach_file),
                label: const Text('Select & Upload Document'),
              ),
          ],
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/permission_dialog_service.dart';
import '../../../core/sync/offline_api.dart';
import '../../../core/sync/pending_upload_store.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  final String? patientName;
  final String? patientId;
  const CreatePrescriptionScreen({super.key, this.patientName, this.patientId});

  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  late TextEditingController _patientNameController;
  final _medicineNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _handwrittenNoteController = TextEditingController();

  final List<String> _timingOptions = ['Before Breakfast', 'After Meals', 'At Bedtime'];
  final Set<String> _selectedTimings = {};

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE2E8F0);

  List<dynamic> _patients = [];
  String? _selectedPatientId;
  bool _isLoading = false;

  /// null = choose mode, digital | handwritten
  String? _mode;
  File? _previewFile;
  bool _previewIsPdf = false;

  @override
  void initState() {
    super.initState();
    _patientNameController = TextEditingController(text: widget.patientName);
    _selectedPatientId = widget.patientId;
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final data = await _api.get('/users/patients/');
      setState(() {
        _patients = data;
      });
    } catch (e) {
      debugPrint('Error fetching patients: $e');
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _medicineNameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    _diagnosisController.dispose();
    _handwrittenNoteController.dispose();
    super.dispose();
  }

  int? _patientPk(String? selected) {
    if (selected == null) return null;
    Map? match;
    for (final p in _patients) {
      if (p is Map && p['id'].toString() == selected) {
        match = p;
        break;
      }
    }
    if (match != null) {
      final details = match['profile_details'];
      if (details is Map && details['patient_id'] != null) {
        return int.tryParse(details['patient_id'].toString());
      }
    }
    return int.tryParse(selected);
  }

  void _generatePrescription() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => _buildPrescriptionSummaryDialog(),
      );
    }
  }

  Future<void> _savePrescription() async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final patientPk = _patientPk(_selectedPatientId);
      if (patientPk == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid patient')),
        );
        return;
      }

      final medications =
          "${_medicineNameController.text} (${_dosageController.text}) - ${_durationController.text}\nTimings: ${_selectedTimings.join(', ')}\nInstructions: ${_instructionsController.text}";

      final body = {
        'patient': patientPk,
        'medications': medications,
        'dosage_instructions': _instructionsController.text,
        'notes': _diagnosisController.text,
        'prescription_type': 'digital',
      };

      try {
        await _api.post('/prescriptions/', body: body);
      } catch (_) {
        final result = await OfflineApi.instance.post('/prescriptions/', body: body);
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.synced
                  ? 'Prescription Saved & Sent Successfully'
                  : 'Saved locally — will upload when internet returns.',
            ),
            backgroundColor: result.synced ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription Saved & Sent Successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error saving prescription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save prescription: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickHandwrittenSource() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Choose PDF'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    if (choice == 'pdf') {
      try {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['pdf'],
        );
        if (result.isEmpty) return;
        final path = result.first.path;
        if (path == null) return;
        setState(() {
          _previewFile = File(path);
          _previewIsPdf = true;
        });
      } catch (e) {
        if (!mounted) return;
        if (e.toString().toLowerCase().contains('cancel')) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick PDF: $e')),
        );
      }
      return;
    }

    final source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final permission = source == ImageSource.camera ? Permission.camera : Permission.photos;
    final allowed = await PermissionDialogService.ensure(
      context,
      permission: permission,
      title: 'Allow photos',
      message: 'Allow camera or gallery to capture the handwritten prescription.',
    );
    if (!allowed || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _previewFile = File(picked.path);
      _previewIsPdf = false;
    });
  }

  Future<void> _uploadHandwritten() async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient')),
      );
      return;
    }
    final file = _previewFile;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a prescription image or PDF')),
      );
      return;
    }

    final patientPk = _patientPk(_selectedPatientId);
    if (patientPk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid patient')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final fields = {
      'patient': patientPk.toString(),
      'prescription_type': 'handwritten',
      'notes': _handwrittenNoteController.text.trim(),
    };

    try {
      try {
        await _api.postMultipart(
          '/prescriptions/',
          file: file,
          field: 'file',
          fields: fields,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription uploaded successfully.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
        return;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final isNetwork = msg.contains('socket') ||
            msg.contains('timeout') ||
            msg.contains('connection') ||
            msg.contains('network') ||
            msg.contains('failed host lookup') ||
            msg.contains('unreachable');
        if (!isNetwork) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        final saved = await PendingUploadStore.instance.savePrescriptionScan(file);
        final result = await OfflineApi.instance.postMultipart(
          '/prescriptions/',
          filePath: saved.path,
          field: 'file',
          fields: fields,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.synced
                  ? 'Prescription uploaded successfully.'
                  : 'Saved locally — will upload when internet returns.',
            ),
            backgroundColor: result.synced ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (result.synced || result.savedLocally) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPrescriptionSummaryDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description, color: primaryBlue, size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Confirm Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSummaryRow(
              'PATIENT',
              _patients
                  .firstWhere(
                    (p) => p['id'].toString() == _selectedPatientId,
                    orElse: () => {'name': 'Unknown'},
                  )['name']
                  .toString()
                  .toUpperCase(),
            ),
            const Divider(height: 24),
            Text(
              'Rx',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('MEDICINE', _medicineNameController.text),
            _buildSummaryRow('DOSAGE', _dosageController.text),
            _buildSummaryRow('DURATION', _durationController.text),
            const SizedBox(height: 12),
            Text(
              'INSTRUCTIONS',
              style: TextStyle(
                color: textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _instructionsController.text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (_selectedTimings.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _selectedTimings
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePrescription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm & Send',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () {
            if (_mode != null) {
              setState(() {
                _mode = null;
                _previewFile = null;
                _previewIsPdf = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _mode == 'handwritten'
              ? 'Handwritten Prescription'
              : _mode == 'digital'
                  ? 'Digital Prescription'
                  : 'Prescription',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(Icons.person_outline, 'PATIENT INFORMATION'),
              const SizedBox(height: 12),
              _buildPatientInfoCard(),
              const SizedBox(height: 28),
              if (_mode == null) ..._buildModeChooser(),
              if (_mode == 'digital') ..._buildDigitalForm(),
              if (_mode == 'handwritten') ..._buildHandwrittenForm(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _mode == 'digital'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generatePrescription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryBlue.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.assignment_outlined, size: 22),
                    label: const Text(
                      'Review Prescription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  List<Widget> _buildModeChooser() {
    return [
      _buildSectionTitle(Icons.medical_information_outlined, 'PRESCRIPTION'),
      const SizedBox(height: 16),
      _modeButton(
        icon: Icons.edit_note,
        title: 'Create Digital Prescription',
        subtitle: 'Enter medicines, dosage, and instructions',
        onTap: () => setState(() => _mode = 'digital'),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text('or', style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(height: 12),
      _modeButton(
        icon: Icons.document_scanner_outlined,
        title: 'Upload Handwritten Prescription',
        subtitle: 'Camera, gallery, or PDF — preview before upload',
        onTap: () => setState(() => _mode = 'handwritten'),
      ),
    ];
  }

  Widget _modeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF4F8FB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBF1F6)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDigitalForm() {
    return [
      _buildSectionTitle(Icons.add_box_outlined, 'DIAGNOSIS'),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _diagnosisController,
        placeholder: 'Enter diagnosis findings...',
        validatorError: 'Please enter diagnosis',
        maxLines: 2,
      ),
      const SizedBox(height: 24),
      _buildSectionTitle(Icons.medication_outlined, 'MEDICATION DETAILS'),
      const SizedBox(height: 16),
      _buildLabel('Medicine Name'),
      _buildTextField(
        controller: _medicineNameController,
        placeholder: 'e.g. Amoxicillin',
        validatorError: 'Please enter medicine name',
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Dosage'),
                _buildTextField(
                  controller: _dosageController,
                  placeholder: 'e.g. 500mg',
                  validatorError: 'Required',
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Duration'),
                _buildTextField(
                  controller: _durationController,
                  placeholder: 'e.g. 7 days',
                  validatorError: 'Required',
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildLabel('Instructions'),
      _buildTextField(
        controller: _instructionsController,
        placeholder: 'e.g. Take twice daily after meals',
        validatorError: 'Please enter instructions',
        maxLines: 3,
      ),
      const SizedBox(height: 20),
      _buildTimingTags(),
      const SizedBox(height: 40),
    ];
  }

  List<Widget> _buildHandwrittenForm() {
    return [
      _buildSectionTitle(Icons.document_scanner_outlined, 'HANDWRITTEN PRESCRIPTION'),
      const SizedBox(height: 12),
      Text(
        'Capture or select the prescription, preview it, then upload. Nothing is sent until you confirm.',
        style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
      ),
      const SizedBox(height: 20),
      if (_previewFile == null)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _pickHandwrittenSource,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Camera / Gallery / PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: BorderSide(color: primaryBlue.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        )
      else ...[
        _buildLabel('Prescription Preview'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 360),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: _previewIsPdf
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 56, color: Colors.redAccent),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _previewFile!.path.split(Platform.pathSeparator).last,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              : Image.file(_previewFile!, fit: BoxFit.contain),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _previewFile = null;
                          _previewIsPdf = false;
                        });
                        _pickHandwrittenSource();
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retake'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadHandwritten,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Upload Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 24),
      _buildLabel('Optional note'),
      TextField(
        controller: _handwrittenNoteController,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'Follow-up prescription...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBlue, width: 1.5),
          ),
        ),
      ),
      const SizedBox(height: 40),
    ];
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: primaryBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBF1F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Select Patient'),
          _patients.isEmpty
              ? const Text("Loading patients...")
              : DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  items: _patients
                      .map(
                        (p) => DropdownMenuItem(
                          value: p['id'].toString(),
                          child: Text(p['name'] ?? 'Unknown'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPatientId = val;
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  validator: (val) => val == null ? 'Please select a patient' : null,
                ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required String validatorError,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: (value) {
        if (_mode != 'digital') return null;
        if (value == null || value.trim().isEmpty) {
          return validatorError;
        }
        return null;
      },
    );
  }

  Widget _buildTimingTags() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _timingOptions.map((timing) {
        final isSelected = _selectedTimings.contains(timing);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTimings.remove(timing);
              } else {
                _selectedTimings.add(timing);
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? primaryBlue.withOpacity(0.08) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? primaryBlue.withOpacity(0.3) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              timing,
              style: TextStyle(
                color: isSelected ? primaryBlue : const Color(0xFF475569),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

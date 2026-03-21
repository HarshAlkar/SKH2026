import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_service.dart';
import '../services/history_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final QRService _qrService = QRService();
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;
  bool _isFetching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scan Health QR', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isScanned || _isFetching) return;
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => _isScanned = true);
                  _processQR(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Scan overlay
          _buildOverlay(),
          // Fetching indicator
          if (_isFetching)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Fetching patient data...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Scan frame
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Corner decorations
                _corner(Alignment.topLeft),
                _corner(Alignment.topRight),
                _corner(Alignment.bottomLeft),
                _corner(Alignment.bottomRight),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Align VitalReach QR code inside the frame',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner(Alignment alignment) {
    final x = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    final y = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    return Align(
      alignment: alignment,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            left: x ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            right: !x ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            top: y ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            bottom: !y ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _processQR(String rawValue) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.user?.role;
    
    // 1. Security Check: Only Doctors/ASHA can view full patient history
    if (role != 'doctor' && role != 'asha_worker') {
       if (mounted) {
         Helpers.showSnackBar(context, 'Access Denied: Specialized role required to view patient history', isError: true);
         await Future.delayed(const Duration(seconds: 2));
         if (mounted) setState(() => _isScanned = false);
       }
       return;
    }

    setState(() => _isFetching = true);
    
    // Fetch and validate token
    final token = auth.token ?? "";
    final historyService = HistoryService();
    
    final data = await historyService.getFullHistoryByAbha(rawValue, token);
    
    if (mounted) {
      setState(() {
        _isFetching = false;
      });
    }

    if (data == null) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Patient not found or invalid ABHA ID', isError: true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _isScanned = false);
      }
      return;
    }

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QRUserDetailsScreen(data: data)),
      );
      setState(() => _isScanned = false);
    }
  }
}


class QRUserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const QRUserDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final phone = data['phone_number'] ?? data['phone'] ?? 'N/A';
    final abhaId = data['abha_id'] ?? 'N/A';
    final profileDetails = data['profile_details'] as Map<String, dynamic>? ?? {};
    final bloodGroup = profileDetails['blood_group'] ?? 'N/A';
    final prescriptions = data['prescriptions'] as List<dynamic>? ?? [];
    final reports = data['reports'] as List<dynamic>? ?? [];
    final aiHistory = data['ai_history'] as List<dynamic>? ?? [];
    final emergencyContact = data['emergency_contact'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Patient Health Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Share logic could be here
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Primary Identity Card ──
            _buildSection(
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ABHA: $abhaId',
                            style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Vital Information (Emergency & Medical) ──
            _buildSectionTitle('Emergency & Medical Info', Icons.medical_services_rounded, color: Colors.redAccent),
            _buildSection(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _infoTile(
                    Icons.bloodtype_rounded, 
                    'Blood Group', 
                    bloodGroup, 
                    valueColor: Colors.redAccent, 
                    iconBg: Colors.redAccent.withOpacity(0.1)
                  ),
                  const Divider(height: 1),
                  if (emergencyContact != null) ...[
                    _infoTile(Icons.person_outline_rounded, 'Emergency Contact', '${emergencyContact['contact_name'] ?? 'N/A'}'),
                    const Divider(height: 1),
                    _infoTile(Icons.phone_iphone_rounded, 'Contact Phone', '${emergencyContact['phone_number'] ?? 'N/A'}'),
                    const Divider(height: 1),
                    if ((emergencyContact['medical_notes'] ?? '').isNotEmpty)
                      _infoTile(Icons.history_edu_rounded, 'Critical Notes', emergencyContact['medical_notes'], isLong: true),
                    if ((emergencyContact['allergies'] ?? '').isNotEmpty)
                      _infoTile(Icons.warning_amber_rounded, 'Allergies', emergencyContact['allergies'], valueColor: Colors.orange, isLong: true),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No specialized emergency data available.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── AI Symptom History ──
            if (aiHistory.isNotEmpty) ...[
              _buildSectionTitle('AI Symptom Analysis History', Icons.psychology_rounded, color: Colors.purple),
              _buildSection(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: aiHistory.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final ai = aiHistory[index];
                    final severity = ai['severity_level'] ?? 'Low';
                    final color = (severity == 'Critical' || severity == 'High') ? Colors.red : Colors.orange;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(ai['predicted_disease'] ?? 'Unknown Condition', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Text(severity.toUpperCase(), 
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(ai['symptoms_text'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(Helpers.formatDate(ai['created_at']) ?? 'Recently', 
                            style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Clinical Prescriptions ──
            if (prescriptions.isNotEmpty) ...[
              _buildSectionTitle('Clinical Prescriptions', Icons.receipt_long_rounded, color: Colors.blue),
              _buildSection(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prescriptions.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final p = prescriptions[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p['medications'] ?? 'Standard Prescription', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (p['dosage_instructions'] != null)
                          _historyDetail('Dosage', p['dosage_instructions']),
                        if (p['notes'] != null && p['notes'].toString().isNotEmpty)
                          _historyDetail('Doctor Notes', p['notes']),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('Issued by: ${p['doctor_name'] ?? 'Medical Staff'}', 
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const Spacer(),
                            Text(Helpers.formatDate(p['issued_at']) ?? '', 
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Lab Reports & Documents ──
            if (reports.isNotEmpty) ...[
              _buildSectionTitle('Health Reports & Documents', Icons.folder_shared_rounded),
              _buildSection(
                padding: const EdgeInsets.all(0),
                child: Column(
                  children: reports.map<Widget>((r) {
                    final hasFile = r['file_url'] != null;
                    return InkWell(
                      onTap: hasFile ? () {
                        // Open URL logic
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: reports.last == r ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.description_rounded, color: Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['title'] ?? 'Report', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(r['type'] ?? 'General', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            if (hasFile)
                              const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.blueAccent)
                            else
                              const Text('NO FILE', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 40),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('FINISH REVIEW', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.primary),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color ?? const Color(0xFF334155), letterSpacing: 0.2)),
        ],
      ),
    );
  }

  Widget _buildSection({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {Color? valueColor, Color? iconBg, bool isLong = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: isLong ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg ?? Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: valueColor ?? Colors.blueGrey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(
                  value, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15, 
                    color: valueColor ?? const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }
}

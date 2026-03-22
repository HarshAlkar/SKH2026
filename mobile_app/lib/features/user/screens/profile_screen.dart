import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hs053/core/theme/app_colors.dart';
import 'package:hs053/shared/providers/auth_provider.dart';
import 'package:hs053/shared/providers/profile_provider.dart';
import 'package:hs053/core/routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isGeneratingCard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchFamilyMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = Provider.of<ProfileProvider>(context);
    final user = auth.user;
    
    // Extract patient details if user role is 'user'
    final details = user?.profileDetails;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(user),
                const SizedBox(height: 30),
                
                // QR Code Section
                _buildQRSection(user),
                const SizedBox(height: 30),
                
                // Emergency Info
                _buildEmergencyInfoSection(profile, details),
                const SizedBox(height: 30),
                
                // Family Members
                _buildFamilySection(profile),
                const SizedBox(height: 30),
                
                // Logout Button
                _buildLogoutButton(auth),
                const SizedBox(height: 40),
              ],
            ),
          ),
          // Hidden ID Card for Generation
          Positioned(
            left: -1000, // Off-screen
            child: RepaintBoundary(
              key: _cardKey,
              child: _buildIdentityCard(user),
            ),
          ),
          if (_isGeneratingCard)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF2F4DB6).withOpacity(0.1),
          child: const Icon(Icons.person, size: 50, color: Color(0xFF2F4DB6)),
        ),
        const SizedBox(height: 16),
        Text(
          user?.name ?? 'Loading...',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          user?.phoneNumber ?? 'No Phone',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
        if (user?.abhaId != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ABHA ID: ${user?.abhaId}',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildQRSection(dynamic user) {
    final abhaId = user?.abhaId ?? "N/A";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text('Your Medical Identity QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          QrImageView(
            data: abhaId,
            version: QrVersions.auto,
            size: 180.0,
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _showFullQRDialog(abhaId);
                    },
                    icon: const Icon(Icons.fullscreen),
                    label: const Text('View Full'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Share.share('My Medical ABHA ID: $abhaId');
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share Text'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingCard ? null : _captureAndShareCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F4DB6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.badge_outlined, color: Colors.white),
                  label: const Text(
                    'Download QR ID Card',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullQRDialog(String abhaId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scan for Medical Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              QrImageView(
                data: abhaId,
                version: QrVersions.auto,
                size: 250.0,
              ),
              const SizedBox(height: 20),
              Text(abhaId, style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
              const SizedBox(height: 20),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureAndShareCard() async {
    setState(() => _isGeneratingCard = true);
    try {
      // Small delay to ensure widget is painted
      await Future.delayed(const Duration(milliseconds: 100));
      
      RenderRepaintBoundary? boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/medical_id_card.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Professional Medical ID Card - VitalReach',
      );
    } catch (e) {
      debugPrint('Error generating card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate card: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingCard = false);
    }
  }

  Widget _buildIdentityCard(dynamic user) {
    const primaryColor = Color(0xFF2F4DB6);
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.08), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.health_and_safety, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VITALREACH',
                      style: TextStyle(
                        letterSpacing: 2, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 20, 
                        color: Colors.white
                      ),
                    ),
                    Text(
                      'NATIONAL HEALTH IDENTITY',
                      style: TextStyle(
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600, 
                        fontSize: 8, 
                        color: Colors.white70
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // User Photo & Name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.person, size: 50, color: primaryColor),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name?.toUpperCase() ?? 'NAME NOT FOUND',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 18, 
                              color: Color(0xFF1E293B)
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ABHA ID: ${user?.abhaId ?? "N/A"}',
                              style: const TextStyle(
                                color: Color(0xFF2563EB), 
                                fontWeight: FontWeight.bold, 
                                fontSize: 11
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Phone: +91 ${user?.phoneNumber ?? "N/A"}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: user?.abhaId ?? "N/A",
                    version: QrVersions.auto,
                    size: 150.0,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'This is a digital health identity card.',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Emergency Helpline: 108',
                        style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyInfoSection(ProfileProvider profile, dynamic details) {
    return _buildSectionCard(
      title: 'Emergency & Medical Info',
      icon: Icons.emergency_outlined,
      child: Column(
        children: [
          _buildInfoRow('Blood Group', details?['blood_group'] ?? 'Not Set'),
          _buildInfoRow('Allergies', details?['allergies'] ?? 'None Reported'),
          _buildInfoRow('Medical History', details?['medical_history'] ?? 'No records'),
          const Divider(),
          TextButton(
            onPressed: () => _showUpdateEmergencyDialog(details),
            child: const Text('Edit Medical Info'),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilySection(ProfileProvider profile) {
    return _buildSectionCard(
      title: 'Family Members',
      icon: Icons.family_restroom,
      child: Column(
        children: [
          if (profile.familyMembers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No family members added yet.', style: TextStyle(fontStyle: FontStyle.italic)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: profile.familyMembers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final member = profile.familyMembers[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${member['relationship']} • ${member['phone_number']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => profile.deleteFamilyMember(member['id']),
                  ),
                );
              },
            ),
          const Divider(),
          TextButton.icon(
            onPressed: () => _showAddFamilyDialog(profile),
            icon: const Icon(Icons.add),
            label: const Text('Add Family Member'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2F4DB6)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          auth.logout();
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddFamilyDialog(ProfileProvider profile) {
    String name = "";
    String relation = "";
    String phone = "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Family Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Name'), onChanged: (v) => name = v),
            TextField(decoration: const InputDecoration(labelText: 'Relationship'), onChanged: (v) => relation = v),
            TextField(decoration: const InputDecoration(labelText: 'Phone'), onChanged: (v) => phone = v, keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty && relation.isNotEmpty && phone.isNotEmpty) {
                profile.addFamilyMember(name, relation, phone);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showUpdateEmergencyDialog(dynamic details) {
    String bloodGroup = details?['blood_group'] ?? "";
    String allergies = details?['allergies'] ?? "";
    String notes = details?['emergency_notes'] ?? "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Medical Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Blood Group'), 
              controller: TextEditingController(text: bloodGroup),
              onChanged: (v) => bloodGroup = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Allergies'), 
              controller: TextEditingController(text: allergies),
              onChanged: (v) => allergies = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Notes'), 
              controller: TextEditingController(text: notes),
              onChanged: (v) => notes = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<ProfileProvider>().updateEmergencyInfo(
                bloodGroup: bloodGroup,
                allergies: allergies,
                notes: notes,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

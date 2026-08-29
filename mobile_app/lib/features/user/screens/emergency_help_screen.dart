import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/emergency_comms/emergency_comms.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/emergency_contact_model.dart';
import '../../../providers/auth_provider.dart';


class EmergencyHelpScreen extends StatefulWidget {
  const EmergencyHelpScreen({super.key});

  @override
  State<EmergencyHelpScreen> createState() => _EmergencyHelpScreenState();
}

class _EmergencyHelpScreenState extends State<EmergencyHelpScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String _currentLocation = "Fetching location...";
  bool _isLoadingLocation = true;
  bool _sending = false;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _determinePosition();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = "Location services disabled";
          _isLoadingLocation = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = "Permission denied";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = "Permission permanently denied";
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _currentLocation =
            "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _currentLocation = "Location unavailable";
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _sendOfflineEmergency() async {
    if (_sending) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to send an emergency alert')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await _postOnlineEmergency();
      final comms = EmergencyComms.instance;
      if (!comms.isReady) {
        await comms.initialize();
      }
      final packet = await comms.buildPatientPacket(
        user: user,
        latitude: _lat,
        longitude: _lng,
      );
      debugPrint('EMERGENCY [ui] send ${packet.encode()}');
      final result = await comms.send(packet);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.delivered ? Colors.green : const Color(0xFFFFA000),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send offline emergency: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _postOnlineEmergency() async {
    try {
      await ApiService().post('/alerts/emergencies/', body: {
        'alert_type': 'Emergency SOS',
        'location': _lat != null && _lng != null
            ? '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}'
            : _currentLocation,
        if (_lat != null) 'latitude': _lat,
        if (_lng != null) 'longitude': _lng,
      });
    } catch (_) {
      // Offline or API unavailable — LoRa path still runs.
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number saved')),
      );
      return;
    }
    final uri = Uri.parse('tel:$cleaned');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open phone dialer for $cleaned')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start call: $e')),
      );
    }
  }

  Future<void> _openHospitalMap() async {
    final lat = _lat;
    final lng = _lng;
    final uri = (lat != null && lng != null)
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=hospital&center=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=hospital+near+me');
    // Prefer a location-biased hospital search.
    final search = (lat != null && lng != null)
        ? Uri.parse('https://www.google.com/maps/search/hospital/@$lat,$lng,14z')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=hospital');
    try {
      await launchUrl(search, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: $e')),
        );
      }
    }
  }

  Future<void> _callFamily() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    List<EmergencyContactModel> contacts = user?.emergencyContacts ?? [];

    if (contacts.isEmpty) {
      try {
        final res = await ApiService().get('/patients/emergency-contacts/');
        if (res is List) {
          contacts = res
              .whereType<Map>()
              .map((m) => EmergencyContactModel.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      } catch (_) {}
    }

    if (contacts.isEmpty) {
      final legacyPhone = user?.detail('emergency_contact_phone').trim() ?? '';
      if (legacyPhone.isNotEmpty) {
        await _makePhoneCall(legacyPhone);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency family contact is available. Please add one to your profile.'),
        ),
      );
      return;
    }

    if (contacts.length == 1) {
      await _makePhoneCall(contacts.first.phone);
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Call Family',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Who would you like to call?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ...contacts.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person, color: AppColors.primary),
                      ),
                      title: Text(
                        c.relationship.isNotEmpty ? '${c.name} (${c.relationship})' : c.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: Text(
                        c.phone,
                        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569)),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call, color: Colors.green, size: 20),
                      ),
                      onTap: () {
                        Navigator.pop(bottomCtx);
                        _makePhoneCall(c.phone);
                      },
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _notifyAsha() async {
    try {
      final response = await ApiService().post('/alerts/notifications/', body: {
        'disease': 'Emergency',
        'severity': 'High',
      });
      if (!mounted) return;
      final map = response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};
      final notified = map['notified'] == true;
      final village = map['village']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notified
                ? 'ASHA worker notified'
                : 'No ASHA worker found${village.isNotEmpty ? ' for $village' : ''}. Update your village in Profile.',
          ),
          backgroundColor: notified ? Colors.green : const Color(0xFFFFA000),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not notify ASHA: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);
    const emergencyRed = Color(0xFFE53935);
    const backgroundColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Emergency Help",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: emergencyRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  color: emergencyRed,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Immediate Assistance",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Press the button below to send an offline emergency alert over the local network. Internet is not required.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // Emergency Pulse Button — fixed box so pulse does not grow the scroll view
            SizedBox(
              width: 260,
              height: 260,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Container(
                          width: 180 + (_pulseController.value * 60),
                          height: 180 + (_pulseController.value * 60),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: emergencyRed.withOpacity(1.0 - _pulseController.value),
                          ),
                        ),
                        Container(
                          width: 180 + (_pulseController.value * 30),
                          height: 180 + (_pulseController.value * 30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: emergencyRed.withOpacity(0.5 * (1.0 - _pulseController.value)),
                          ),
                        ),
                        child!,
                      ],
                    );
                  },
                  child: GestureDetector(
                    onTap: _sending ? null : _sendOfflineEmergency,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: emergencyRed,
                        boxShadow: [
                          BoxShadow(
                            color: emergencyRed.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_sending)
                            const CircularProgressIndicator(color: Colors.white)
                          else
                            const Icon(
                              Icons.emergency,
                              color: Colors.white,
                              size: 48,
                            ),
                          const SizedBox(height: 12),
                          Text(
                            _sending ? "SENDING..." : "SEND\nEMERGENCY",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Location Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlue.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Current Location: $_currentLocation",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  if (_isLoadingLocation)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: EmergencyComms.instance,
              builder: (context, _) {
                final comms = EmergencyComms.instance;
                return Text(
                  comms.statusLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                );
              },
            ),

            const SizedBox(height: 32),

            // Quick Contact Options
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Contact Options",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              title: "Call 102",
              subtitle: "Ambulance / emergency phone (cellular)",
              icon: Icons.phone_in_talk,
              iconColor: emergencyRed,
              onTap: () => _makePhoneCall('102'),
            ),
            _buildContactCard(
              title: "Call Family",
              subtitle: "Emergency contact from your profile",
              icon: Icons.personal_video_outlined,
              iconColor: primaryBlue,
              onTap: _callFamily,
            ),
            _buildContactCard(
              title: "Notify ASHA Worker",
              subtitle: "Alert local health volunteer",
              icon: Icons.notification_important_outlined,
              iconColor: primaryBlue,
              onTap: _notifyAsha,
            ),
            _buildContactCard(
              title: "Nearest Hospital",
              subtitle: _lat == null
                  ? "Search hospitals near you"
                  : "Hospitals near ${_lat!.toStringAsFixed(3)}, ${_lng!.toStringAsFixed(3)}",
              icon: Icons.local_hospital_outlined,
              iconColor: primaryBlue,
              onTap: _openHospitalMap,
            ),

            const SizedBox(height: 24),

            // Map Section
            GestureDetector(
              onTap: _openHospitalMap,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage("https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=1000"),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black26,
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    // Green overlay like design
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.green.withOpacity(0.3),
                            Colors.green.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Text(
                        "View detailed route to Hospital",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),

        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

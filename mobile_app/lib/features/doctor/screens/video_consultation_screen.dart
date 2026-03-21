import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/consultation_provider.dart';

class VideoConsultationScreen extends StatefulWidget {
  final String consultationId;
  
  const VideoConsultationScreen({
    super.key,
    required this.consultationId,
  });

  @override
  State<VideoConsultationScreen> createState() => _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> {
  bool _isMuted = false;
  bool _isCameraOff = false;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2A7DE1);

    return Scaffold(
      backgroundColor: Colors.black, // Full screen video background
      body: SafeArea(
        child: Stack(
          children: [
            // 1. simulated background video feed
            Positioned.fill(
              child: Container(
                color: const Color(0xFF1E293B), // Dark slate fallback if no image
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 150,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),

            // 2. Top Header Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Video Consultation',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981), // Green dot
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '08:42 · Live',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Color(0xFF4B5563), size: 20),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.signal_cellular_alt, color: primaryBlue, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Stable',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Floating Doctor Preview
            Positioned(
              top: 90,
              right: 20,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.teal.shade700,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Stack(
                  children: [
                    if (!_isCameraOff)
                      const Center(
                        child: Icon(Icons.person, size: 60, color: Colors.white54),
                      ),
                    if (_isCameraOff)
                      const Center(
                        child: Icon(Icons.videocam_off, size: 40, color: Colors.white),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Patient Name Tag
            Positioned(
              bottom: 160,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sarah Jenkins (Patient)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // 5. Connection Message & Control Panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Connection Message
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.info_outline, color: Color(0xFFFBBF24), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'If internet is slow, call will switch to audio.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Control Panel Bottom Area
                  Container(
                    padding: const EdgeInsets.only(top: 20, bottom: 30, left: 16, right: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chat Button
                        _buildControlButton(
                          icon: Icons.chat_bubble_outline,
                          label: '',
                          onTap: () {},
                          isSmall: true,
                        ),
                        
                        // Notes Button
                        _buildControlButton(
                          icon: Icons.note_add_outlined,
                          label: '',
                          onTap: () {},
                          isSmall: true,
                        ),

                        // Mute Button
                        _buildControlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic_none,
                          label: 'MUTE',
                          isActive: _isMuted,
                          onTap: () {
                            setState(() {
                              _isMuted = !_isMuted;
                            });
                          },
                        ),

                        // Camera Button
                        _buildControlButton(
                          icon: _isCameraOff ? Icons.videocam_off : Icons.videocam_outlined,
                          label: 'CAMERA',
                          isActive: _isCameraOff,
                          onTap: () {
                            setState(() {
                              _isCameraOff = !_isCameraOff;
                            });
                          },
                        ),

                        // End Call Button
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                _showEndCallDialog();
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'END CALL',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Consultation'),
        content: const Text('Are you sure you want to end this consultation and mark it as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close video screen
              await context.read<ConsultationProvider>().endConsultation(widget.consultationId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isSmall = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: isSmall ? 48 : 56,
            height: isSmall ? 48 : 56,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF3F4F6) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.transparent : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF374151),
              size: isSmall ? 20 : 24,
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

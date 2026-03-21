import 'package:flutter/material.dart';
import 'patient_details_screen.dart';
import '../../user/services/doctor_service.dart';

class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  State<DoctorNotificationsScreen> createState() => _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color primaryBlue = const Color(0xFF2A7DE1);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  final DoctorService _doctorService = DoctorService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await _doctorService.getNotifications();
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBlue,
          unselectedLabelColor: textSecondary,
          indicatorColor: primaryBlue,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Requests'),
            Tab(text: 'Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList('all'),
          _buildNotificationList('request'),
          _buildNotificationList('alert'),
        ],
      ),
    );
  }

  Widget _buildNotificationList(String type) {
    final filtered = _notifications.where((n) {
      if (type == 'all') return true;
      return (n['type'] ?? '').toString().toLowerCase() == type;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No notifications found'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final n = filtered[index];
        return NotificationCard(
          iconContent: _buildIconForType(n['type'] ?? ''),
          title: n['title'] ?? 'Notification',
          message: n['message'] ?? '',
          time: n['created_at'] != null 
              ? n['created_at'].toString().split('T').first 
              : 'Recently',
          hasUnreadDot: !(n['is_read'] ?? true),
          unreadDotColor: (n['type'] == 'emergency' || n['type'] == 'alert') 
              ? Colors.red 
              : primaryBlue,
          backgroundColor: (n['type'] == 'emergency' || n['type'] == 'alert')
              ? const Color(0xFFFFE9E9)
              : Colors.white,
        );
      },
    );
  }

  Widget _buildIconForType(String type) {
    IconData icon = Icons.notifications;
    Color color = primaryBlue;
    Color bgColor = const Color(0xFFE8F1FF);

    if (type == 'emergency' || type == 'alert') {
      icon = Icons.emergency;
      color = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEE2E2);
    } else if (type == 'request') {
      icon = Icons.medical_services;
      color = Colors.teal;
      bgColor = Colors.teal.withOpacity(0.1);
    }

    return _buildIconContainer(icon: icon, color: color, bgColor: bgColor);
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: const Color(0xFFF9FAFB), // Very light grey
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildIconContainer({required IconData icon, required Color color, required Color bgColor}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildAcceptButton(VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(0, 36),
      ),
      onPressed: onPressed,
      child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildDeclineButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6B7280), // Grey text
        side: const BorderSide(color: Color(0xFFE5E7EB)), // Grey border
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(0, 36),
      ),
      onPressed: () {},
      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildEmergencyButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 36),
      ),
      onPressed: () {},
      icon: const Icon(Icons.phone, size: 16),
      label: const Text('Call ASHA Worker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final Widget iconContent;
  final String title;
  final String message;
  final String time;
  final Color? backgroundColor;
  final Color? titleColor;
  final bool hasUnreadDot;
  final Color? unreadDotColor;
  final List<Widget>? actionButtons;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.iconContent,
    required this.title,
    required this.message,
    required this.time,
    this.backgroundColor = Colors.white,
    this.titleColor = const Color(0xFF1F2937),
    this.hasUnreadDot = false,
    this.unreadDotColor = const Color(0xFF2A7DE1),
    this.actionButtons,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        color: const Color(0xFFEF4444),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconContent,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                            ),
                          ),
                          if (hasUnreadDot) ...[
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: unreadDotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      if (actionButtons != null) ...[
                        const SizedBox(height: 12),
                        Row(children: actionButtons!),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

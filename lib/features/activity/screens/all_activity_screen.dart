import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../widgets/activity_card.dart';
import './activity_details_screen.dart';
import '../../../features/asha_worker/widgets/asha_drawer.dart';

class AllActivityScreen extends StatefulWidget {
  const AllActivityScreen({super.key});

  @override
  State<AllActivityScreen> createState() => _AllActivityScreenState();
}

class _AllActivityScreenState extends State<AllActivityScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<ActivityModel> _allActivities = [
    ActivityModel(
      patientName: "Ramesh Patil",
      activityType: "Fever reported",
      description:
          "Patient reported high fever during routine checkup. Temperature recorded at 101°F.",
      timestamp: "10 mins ago",
      village: "Rampur",
      reportedBy: "ASHA Worker",
    ),
    ActivityModel(
      patientName: "Sita Devi",
      activityType: "Vaccination completed",
      description:
          "Child vaccination drive: BCG and Hepatitis B administered. No immediate adverse reactions noted.",
      timestamp: "2 hrs ago",
      village: "Kaman",
      reportedBy: "ASHA Worker",
    ),
    ActivityModel(
      patientName: "Arjun Kumar",
      activityType: "BP update",
      description:
          "Routine BP check. Recorded 130/85 mmHg. Patient advised to reduce salt intake and walk daily.",
      timestamp: "5 hrs ago",
      village: "Rampur",
      reportedBy: "ASHA Worker",
    ),
    ActivityModel(
      patientName: "Meera Singh",
      activityType: "Health checkup",
      description:
          "General wellness check. All vitals normal. Patient's daughter noted as underweight.",
      timestamp: "Yesterday",
      village: "Kaman",
      reportedBy: "ASHA Worker",
    ),
  ];

  List<ActivityModel> _filteredActivities = [];

  @override
  void initState() {
    super.initState();
    _filteredActivities = _allActivities;
  }

  void _filterActivities(String query) {
    setState(() {
      _filteredActivities = _allActivities
          .where(
            (activity) =>
                activity.patientName.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                activity.activityType.toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2F4DB6);
    const Color backgroundColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "All Patient Activities",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AshaDrawer(),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: primaryColor,
            child: TextField(
              controller: _searchController,
              onChanged: _filterActivities,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search patient activity...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // LIST OF ACTIVITIES
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: _filteredActivities.length,
              itemBuilder: (context, index) {
                final activity = _filteredActivities[index];
                return ActivityCard(
                  activity: activity,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ActivityDetailsScreen(activity: activity),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/symptom_tag.dart';
import '../widgets/severity_badge.dart';
import '../widgets/referral_action_button.dart';
import '../../../routes/app_routes.dart';

class EmergencyReferralScreen extends StatelessWidget {
  const EmergencyReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F4DB6);
    const Color lightRed = Color(0xFFFFEBEE);
    const Color textColor = Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        title: const Text(
          "Emergency Referral",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2F4DB6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Urgent Alert Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightRed,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "URGENT ACTION REQUIRED",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Patient requires immediate medical intervention.",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Patient Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline, color: primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Patient Information",
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Name", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            SizedBox(height: 4),
                            Text(
                              "Lakshmi Devi",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Patient ID", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            SizedBox(height: 4),
                            Text(
                              "ASHA-2023-4491",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A90E2), fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Reported Symptoms", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SymptomTag(symptom: "Acute Chest Pain"),
                        SymptomTag(symptom: "Difficulty Breathing"),
                        SymptomTag(symptom: "High Perspiration"),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Reported Severity",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SeverityBadge(label: "CRITICAL", color: Colors.red),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              ReferralActionButton(
                icon: Icons.phone,
                label: "Call Doctor",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Simulating call to doctor...')),
                  );
                },
              ),
              const SizedBox(height: 16),
              ReferralActionButton(
                icon: Icons.assignment_outlined,
                label: "Send Referral",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Emergency referral sent successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ReferralActionButton(
                icon: Icons.share_outlined,
                label: "Share Patient Data",
                isSecondary: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sharing patient report with doctor...')),
                  );
                },
              ),

              const SizedBox(height: 32),
              
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.referralHistory);
                  },
                  child: const Text(
                    "View Past Referrals for Lakshmi Devi",
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              const Center(
                child: Text(
                  "ASHA Digital Care Protocol v2.4.1",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

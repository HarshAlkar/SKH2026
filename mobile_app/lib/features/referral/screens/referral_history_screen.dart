import 'package:flutter/material.dart';
import '../../../core/widgets/common_appbar.dart';

class ReferralHistoryScreen extends StatelessWidget {
  const ReferralHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(title: "Referral History"),
      body: Center(
        child: Text("Past referrals will be displayed here."),
      ),
    );
  }
}

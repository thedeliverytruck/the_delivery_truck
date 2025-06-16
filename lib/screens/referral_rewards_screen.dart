import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class ReferralRewardsScreen extends StatefulWidget {
  const ReferralRewardsScreen({super.key});

  @override
  State<ReferralRewardsScreen> createState() => _ReferralRewardsScreenState();
}

class _ReferralRewardsScreenState extends State<ReferralRewardsScreen> {
  int totalPoints = 0;
  List<Map<String, dynamic>> referredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final uid = currentUser.uid;
    final refDoc = await FirebaseFirestore.instance.collection('referrals').doc(uid).get();

    if (refDoc.exists) {
      final data = refDoc.data()!;
      setState(() {
        totalPoints = data['points'] ?? 0;
        referredUsers = List<Map<String, dynamic>>.from(data['referred'] ?? []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'My Referral Rewards'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You’ve earned $totalPoints reward point${totalPoints == 1 ? '' : 's'}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Referred People:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: referredUsers.isEmpty
                  ? const Text('No referrals yet.')
                  : ListView.builder(
                      itemCount: referredUsers.length,
                      itemBuilder: (context, index) {
                        final user = referredUsers[index];
                        final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
                        final role = user['role'] ?? 'Unknown';
                        final isPro = user['isPro'] == true;

                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(name.isNotEmpty ? name : 'Unnamed'),
                          subtitle: Text('Role: $role'),
                          trailing: isPro
                              ? const Icon(Icons.verified, color: Colors.amber, size: 28)
                              : const Icon(Icons.verified_outlined, color: Colors.grey),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

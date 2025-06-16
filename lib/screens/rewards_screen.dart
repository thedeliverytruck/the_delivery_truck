import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  int totalPoints = 0;
  List<Map<String, dynamic>> referredUsers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('referrals')
        .where('referrerUid', isEqualTo: uid)
        .get();

    int points = 0;
    List<Map<String, dynamic>> users = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final fullName = data['name'] ?? 'Unnamed';
      final isPro = data['isPro'] == true;

      final parts = fullName.trim().split(' ');
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastInitial = parts.length > 1 ? '${parts.last[0]}.' : '';
      final displayName = '$firstName $lastInitial';

      points += isPro ? 5 : 1;
      users.add({
        'name': displayName,
        'isPro': isPro,
      });
    }

    setState(() {
      totalPoints = points;
      referredUsers = users;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'My Referral Rewards',
        showBackButton: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Total Points: $totalPoints',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Referred Users:',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    if (referredUsers.isEmpty)
                      const Text(
                        'No referrals yet.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    if (referredUsers.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: referredUsers.length,
                          itemBuilder: (context, index) {
                            final user = referredUsers[index];
                            return Card(
                              color: Colors.grey[850],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: Colors.yellow),
                                title: Text(
                                  user['name'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                trailing: Text(
                                  user['isPro'] ? '+5 pts' : '+1 pt',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

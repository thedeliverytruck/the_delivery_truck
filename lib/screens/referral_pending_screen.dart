import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReferralPendingScreen extends StatelessWidget {
  final String referralCode;

  const ReferralPendingScreen({super.key, required this.referralCode});

  Future<Map<String, dynamic>?> _fetchReferrerData() async {
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      return userQuery.docs.first.data();
    }

    final driverQuery = await FirebaseFirestore.instance
        .collection('drivers')
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (driverQuery.docs.isNotEmpty) {
      return driverQuery.docs.first.data();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Referral Acknowledged"),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchReferrerData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.yellow));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                "Referral code found, but no referrer details available.",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            );
          }

          final referrer = snapshot.data!;
          final firstName = referrer['firstName'] ?? 'Someone';
          final lastInitial = (referrer['lastName'] ?? '').isNotEmpty
              ? "${referrer['lastName'][0]}."
              : '';
          final profilePhoto = referrer['photoUrl'];

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (profilePhoto != null)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(profilePhoto),
                  ),
                const SizedBox(height: 16),
                Text(
                  "$firstName $lastInitial invited you!",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Thanks for joining through their referral. You’ll both earn rewards after you complete your first delivery or subscribe to PRO!",
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Got it!"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

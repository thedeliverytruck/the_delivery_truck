// lib/screens/driver_home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String welcomeName = '';
  String? activeJobId;

  @override
  void initState() {
    super.initState();
    fetchDriverName();
    checkActiveJob();
  }

  Future<void> fetchDriverName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        final lastInitial = lastName.isNotEmpty ? '${lastName[0]}.' : '';
        setState(() {
          welcomeName = '$firstName $lastInitial';
        });
      }
    }
  }

  Future<void> checkActiveJob() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final query = await FirebaseFirestore.instance
          .collection('jobs')
          .where('driverId', isEqualTo: uid)
          .where('status', whereIn: ['accepted', 'en_route'])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          activeJobId = query.docs.first.id;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Driver Dashboard',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset('assets/icon/icon2.png', width: 120, height: 120)),
              const SizedBox(height: 24),
              Text(
                welcomeName.isNotEmpty ? 'Welcome, $welcomeName' : 'Welcome, Driver!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Ready to deliver?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (activeJobId != null) ...[
                PrimaryButton(
                  text: '📍 Live Tracking',
                  onPressed: () {
                    Navigator.pushNamed(context, '/live_tracking_driver', arguments: {
                      'jobId': activeJobId,
                    });
                  },
                ),
                const SizedBox(height: 24),
              ],

              PrimaryButton(
                text: 'View Available Jobs',
                onPressed: () => Navigator.pushNamed(context, '/available_jobs'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'My Accepted Jobs',
                onPressed: () => Navigator.pushNamed(context, '/my_accepted_jobs'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Earnings Dashboard',
                onPressed: () => Navigator.pushNamed(context, '/driver_earnings'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'View / Edit My Profile',
                onPressed: () => Navigator.pushNamed(context, '/edit_driver_profile'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: '⭐ My Driver Reviews',
                onPressed: () => Navigator.pushNamed(context, '/driver_reviews'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Refer My Friends',
                onPressed: () => Navigator.pushNamed(context, '/referral_share'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'View My Rewards',
                onPressed: () => Navigator.pushNamed(context, '/rewards'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Logout',
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

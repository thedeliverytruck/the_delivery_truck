import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String fullName = '';

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        setState(() {
          fullName = '$firstName $lastName';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'User Dashboard',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset('assets/icon/icon2.png', width: 120, height: 120)),
              const SizedBox(height: 24),
              Text(
                fullName.isNotEmpty ? 'Welcome, $fullName!' : 'Welcome!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'What would you like to do today?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Request a Delivery',
                onPressed: () => Navigator.pushNamed(context, '/request_job'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'My Jobs',
                onPressed: () => Navigator.pushNamed(context, '/my_jobs'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'View / Edit My Profile',
                onPressed: () => Navigator.pushNamed(context, '/edit_user_profile'),
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

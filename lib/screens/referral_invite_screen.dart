import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class ReferralInviteScreen extends StatefulWidget {
  const ReferralInviteScreen({super.key});

  @override
  State<ReferralInviteScreen> createState() => _ReferralInviteScreenState();
}

class _ReferralInviteScreenState extends State<ReferralInviteScreen> {
  String? referralCode;
  String displayName = '';
  String shareMessage = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();

    final data = userDoc.exists ? userDoc.data() : driverDoc.exists ? driverDoc.data() : null;

    if (data != null) {
      final code = data['referralCode'] ?? 'TDTRUCK';
      final name = data['firstName'] ?? '';
      setState(() {
        referralCode = code;
        displayName = name;
        shareMessage =
            "Hey! Check out The Delivery Truck app – it's perfect for moving big stuff. Use my code **$code** when you sign up to support me! Get it at www.thedeliverytruck.com 🚛📦";
        isLoading = false;
      });
    }
  }

  void _shareReferral() {
    if (referralCode != null) {
      Share.share(shareMessage);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: shareMessage));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Referral message copied to clipboard!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invite Friends"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Invite Code:",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      referralCode ?? '',
                      style: const TextStyle(fontSize: 22, color: Colors.yellow, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Share This Message:",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          shareMessage,
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy),
                          label: const Text("Copy"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareReferral,
                          icon: const Icon(Icons.share),
                          label: const Text("Share"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}

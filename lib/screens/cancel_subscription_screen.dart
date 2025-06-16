import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class CancelSubscriptionScreen extends StatefulWidget {
  const CancelSubscriptionScreen({super.key});

  @override
  State<CancelSubscriptionScreen> createState() => _CancelSubscriptionScreenState();
}

class _CancelSubscriptionScreenState extends State<CancelSubscriptionScreen> {
  bool _loading = false;
  String _status = '';

  Future<void> _cancelPro() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("Not logged in.");

      final doc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
      final subscriptionId = doc.data()?['subscriptionId'];

      if (subscriptionId == null) throw Exception("No subscription ID found.");

      final callable = FirebaseFunctions.instance.httpsCallable('cancelProSubscription');
      final result = await callable.call({'subscriptionId': subscriptionId});

      if (result.data['success']) {
        await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
          'isPro': false,
          'subscriptionStatus': 'canceled',
        });

        setState(() => _status = '✅ Subscription canceled successfully.');
      } else {
        setState(() => _status = '⚠️ Failed: ${result.data['error']}');
      }
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Cancel PRO Subscription', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              "Are you sure you want to cancel your PRO membership?",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
                : PrimaryButton(
                    text: 'Cancel PRO Subscription',
                    icon: Icons.cancel,
                    onPressed: _cancelPro,
                  ),
            const SizedBox(height: 24),
            if (_status.isNotEmpty)
              Text(
                _status,
                style: TextStyle(
                  color: _status.contains('Error') || _status.contains('Failed')
                      ? Colors.red
                      : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

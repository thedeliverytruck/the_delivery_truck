import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PaymentAuthorizationScreen extends StatefulWidget {
  final String jobId;
  final String driverId;

  const PaymentAuthorizationScreen({
    super.key,
    required this.jobId,
    required this.driverId,
  });

  @override
  State<PaymentAuthorizationScreen> createState() => _PaymentAuthorizationScreenState();
}

class _PaymentAuthorizationScreenState extends State<PaymentAuthorizationScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? driverName;
  String? dropoff;
  String? itemDescription;

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
    final driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(widget.driverId).get();

    if (jobDoc.exists && driverDoc.exists) {
      setState(() {
        dropoff = jobDoc['dropoffAddress'] ?? 'N/A';
        itemDescription = jobDoc['itemDescription'] ?? 'Item';
        driverName = "${driverDoc['firstName'] ?? ''} ${driverDoc['lastName']?[0] ?? ''}.";
      });
    }
  }

  Future<void> _authorizePayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Step 1: Call Cloud Function to create a payment hold
      final result = await FirebaseFunctions.instance
          .httpsCallable('createPaymentHold')
          .call({
        'userId': user.uid,
        'jobId': widget.jobId,
        'driverId': widget.driverId,
      });

      final data = result.data;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Payment authorization failed');
      }

      // Step 2: Update job with payment hold confirmation
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'paymentAuthorized': true,
        'paymentHoldId': data['paymentIntentId'],
        'status': 'payment_authorized',
      });

      // Step 3: Navigate to live tracking screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/live_tracking', arguments: {
          'jobId': widget.jobId,
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Payment Authorization'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset('assets/icon/icon2.png', width: 120)),
              const SizedBox(height: 24),
              const Text(
                "Authorize Payment Hold",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "A temporary hold will be placed on your card. You won't be charged until delivery is complete.",
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              if (driverName != null || dropoff != null || itemDescription != null) ...[
                const SizedBox(height: 16),
                if (driverName != null)
                  Text(
                    "Selected Driver: $driverName",
                    style: const TextStyle(color: Colors.white),
                  ),
                if (dropoff != null)
                  Text(
                    "Delivery Location: $dropoff",
                    style: const TextStyle(color: Colors.white),
                  ),
                if (itemDescription != null)
                  Text(
                    "Item: $itemDescription",
                    style: const TextStyle(color: Colors.white),
                  ),
              ],
              const Spacer(),
              PrimaryButton(
                text: "Authorize Payment",
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _authorizePayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

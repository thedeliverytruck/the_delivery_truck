import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReferralCodeEntryScreen extends StatefulWidget {
  final Function(String code)? onCodeValidated;

  const ReferralCodeEntryScreen({super.key, this.onCodeValidated});

  @override
  State<ReferralCodeEntryScreen> createState() => _ReferralCodeEntryScreenState();
}

class _ReferralCodeEntryScreenState extends State<ReferralCodeEntryScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> _validateReferralCode() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final code = _codeController.text.trim().toUpperCase();

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();

      final driverQuery = await FirebaseFirestore.instance
          .collection('drivers')
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty || driverQuery.docs.isNotEmpty) {
        // Valid referral code
        widget.onCodeValidated?.call(code);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Referral code '$code' applied successfully!")),
        );
        Navigator.pop(context); // return to previous screen
      } else {
        setState(() {
          errorMessage = "Referral code not found. Please double-check and try again.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error validating code. Please try again.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Referral Code"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Have a referral code? Enter it below to credit the person who invited you!",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Referral Code',
                labelStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _validateReferralCode,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text("Apply Code"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

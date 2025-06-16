import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/primary_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isSending = false;
  bool _isChecking = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
  }

  Future<void> _sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      setState(() {
        _isSending = true;
        _message = '';
      });
      try {
        await user.sendEmailVerification();
        setState(() {
          _message = 'Verification email sent to ${user.email}.';
        });
      } catch (e) {
        setState(() {
          _message = 'Failed to send verification email: ${e.toString()}';
        });
      } finally {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _isChecking = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser != null && refreshedUser.emailVerified) {
        // Determine role and redirect accordingly
        final uid = refreshedUser.uid;
        final driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (!mounted) return;

        if (driverDoc.exists) {
          Navigator.pushReplacementNamed(context, '/driver_home');
        } else if (userDoc.exists) {
          Navigator.pushReplacementNamed(context, '/user_home');
        } else {
          setState(() => _message = 'No role assigned. Contact support.');
        }
      } else {
        setState(() {
          _message = 'Email not verified yet. Please check your inbox.';
        });
      }
    }
    setState(() => _isChecking = false);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '[your email]';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Verify Your Email', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hi $email,\n\nPlease verify your email address before continuing.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Resend Verification Email',
              onPressed: _isSending ? null : _sendVerificationEmail,
              isLoading: _isSending,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'I Verified My Email',
              onPressed: _isChecking ? null : _checkEmailVerified,
              isLoading: _isChecking,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Sign Out',
              onPressed: _signOut,
            ),
            const SizedBox(height: 24),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: const TextStyle(color: Colors.yellow),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

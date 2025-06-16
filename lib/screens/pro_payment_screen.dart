import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class ProPaymentScreen extends StatefulWidget {
  const ProPaymentScreen({super.key});

  @override
  State<ProPaymentScreen> createState() => _ProPaymentScreenState();
}

class _ProPaymentScreenState extends State<ProPaymentScreen> {
  bool _isLoading = false;
  bool _agreedToTerms = false;

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createProCheckoutSession');
      final result = await callable();
      final url = result.data['url'];

      if (url != null && mounted) {
        // Navigate to WebView screen
        await Navigator.pushNamed(context, '/webview', arguments: {'url': url});

        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
        final fromInsuranceScreen = args['fromInsuranceScreen'] == true;

        if (!mounted) return;
        if (fromInsuranceScreen) {
          Navigator.pushReplacementNamed(context, '/referral_share', arguments: {'role': 'driver'});
        } else {
          Navigator.pushReplacementNamed(context, '/driver_home');
        }
      }
    } catch (e) {
      debugPrint('Error during subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start subscription process.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final fromInsuranceScreen = args['fromInsuranceScreen'] == true;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Go PRO',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unlock PRO benefits for your driver account.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              '• Priority access to jobs\n'
              '• Enhanced earnings visibility\n'
              '• Free PRO for the first 6 months (if eligible)',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/webview', arguments: {
                        'url': 'https://www.thedeliverytruck.com/terms',
                      });
                    },
                    child: const Text(
                      'I agree to the Terms and Conditions',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Subscribe Now',
              icon: Icons.star,
              isLoading: _isLoading,
              onPressed: _agreedToTerms
                  ? () async {
                      final user = FirebaseAuth.instance.currentUser;
                      await user?.reload();
                      if (user != null && user.emailVerified) {
                        _handleSubscribe();
                      } else {
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/verify_email');
                        }
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

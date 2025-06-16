import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class ShareAfterSignupScreen extends StatelessWidget {
  final String role; // 'user' or 'driver'

  const ShareAfterSignupScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final String message = '''
I just signed up as a ${role == 'driver' ? 'driver' : 'user'} on The Delivery Truck 🚛📦

The Delivery Truck app makes it super easy to move big stuff fast — no waiting, no hassle!

Whether you're hauling something or need help moving an item, this app connects drivers and users instantly.

Try it now:
👉 https://www.TheDeliveryTruck.com
''';

    void _shareMessage() {
      Share.share(message);
    }

    void _copyToClipboard() {
      Clipboard.setData(const ClipboardData(text: 'https://www.TheDeliveryTruck.com'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard!')),
      );
    }

    void _skipAndContinue() {
      Navigator.pushReplacementNamed(
        context,
        role == 'driver' ? '/driver_home' : '/user_home',
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Spread the Word',
        showBackButton: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.campaign, size: 64, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              "Thanks for joining The Delivery Truck!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Help us grow the network by sharing this app with friends.",
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Share This App',
              onPressed: _shareMessage,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Copy App Link',
              onPressed: _copyToClipboard,
            ),
            const Spacer(),
            TextButton(
              onPressed: _skipAndContinue,
              child: const Text(
                "Skip",
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

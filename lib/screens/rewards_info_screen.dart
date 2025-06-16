import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class RewardsInfoScreen extends StatelessWidget {
  const RewardsInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Rewards Info',
        showBackButton: true,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Image(
                  image: AssetImage('assets/icon/icon.png'),
                  height: 100,
                ),
              ),
            ),
            const Text(
              'Earn Points with The Delivery Truck!',
              style: TextStyle(
                fontSize: 24,
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'You earn rewards every time you refer a friend:',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              '• 1 point for every user or driver that signs up using your code.\n'
              '• 3 points every time a referred user completes a delivery.\n'
              '• 5 bonus points for every PRO driver you refer.\n'
              '• Use points for future discounts and exclusive offers!',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 32),
            const Text(
              'Get Started:',
              style: TextStyle(fontSize: 18, color: Colors.blueAccent),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Sign Up as a User',
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Sign Up as a Driver',
              onPressed: () {
                Navigator.pushNamed(context, '/signup_driver_personal');
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Already signed up?\nLog in from the AppBar to see your rewards.',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

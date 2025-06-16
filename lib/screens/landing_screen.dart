import 'package:flutter/material.dart';
import 'package:the_delivery_truck/widgets/primary_button.dart';
import 'package:the_delivery_truck/widgets/custom_app_bar.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'The Delivery Truck',
        showBackButton: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/icon/icon2.png', // Updated logo with house/shop/truck
                    width: 180,
                    height: 180,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'The Delivery Truck',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Fast, local or long-distance delivery.\nDrivers with trucks standing by — ready to go!',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // PRO Membership Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '🚛 Free PRO membership!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The first 1,000 drivers in each state get 6 months free.\nNo fees. No risk.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use promo code "FIRST1000"',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            isMobile
                ? Column(
                    children: [
                      _descriptionBox(),
                      const SizedBox(height: 16),
                      _reviewsBox(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _descriptionBox()),
                      const SizedBox(width: 16),
                      Expanded(child: _reviewsBox()),
                    ],
                  ),

            const SizedBox(height: 40),
            PrimaryButton(
              text: 'Sign Up as User',
              onPressed: () {
                Navigator.pushNamed(context, '/signup_user'); // Ensure this is the correct route
              },
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Sign Up as Driver',
              onPressed: () => Navigator.pushNamed(context, '/signup_driver_personal'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text(
                'Already have an account? Log in',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _descriptionBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📦 What is The Delivery Truck?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'The Delivery Truck is your on-demand delivery solution for big or bulky items. Whether it\'s a couch from a furniture store or a haul from Costco, our network of truck-owning drivers is ready to help.\n\nSign up is completely free. Users only pay when they need a delivery, and drivers earn money for every job they complete. No subscriptions, no commitments—just fast and easy delivery.',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _reviewsBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🌟 What users are saying:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '⭐️⭐️⭐️⭐️⭐️ "So easy to use and super fast!" — Amanda T.',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            '⭐️⭐️⭐️⭐️⭐️ "Got my Costco haul delivered in 30 minutes!" — Jason R.',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            '⭐️⭐️⭐️⭐️⭐️ "Finally — a delivery app for big items!" — Lisa G.',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            '⭐️⭐️⭐️⭐️⭐️ "Great experience, highly recommended!" — Brian S.',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

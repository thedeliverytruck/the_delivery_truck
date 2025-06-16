import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class TermsAndConditionsUser extends StatelessWidget {
  const TermsAndConditionsUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'User Terms & Conditions'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: const [
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Image(
                  image: AssetImage('assets/icon/icon.png'),
                  height: 100,
                ),
              ),
            ),
            Text(
              "User Terms & Conditions",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
            ),
            SizedBox(height: 24),
            Text(
              "By using The Delivery Truck (“the App”) as a user, you agree to the following legally binding terms and conditions...",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              "1. Use of Services\nYou agree to provide accurate pickup and drop-off information...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "2. No Warranty or Guarantee\nThe App provides a platform to connect users with independent drivers...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "3. Risk of Loss or Damage\nYou acknowledge that all deliveries carry risk...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "4. Indemnification\nYou agree to indemnify and hold harmless The Delivery Truck...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "5. Conduct and Communication\nYou agree to communicate respectfully and lawfully...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "6. Payments and Disputes\nAll payments are processed through third-party providers...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "7. Modifications to Terms\nWe may update these terms at any time...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 32),
            Divider(color: Colors.grey),
            SizedBox(height: 12),
            Center(
              child: Text(
                "For legal inquiries, contact legal@thedeliverytruck.com",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

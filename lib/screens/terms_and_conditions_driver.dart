import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class TermsAndConditionsDriver extends StatelessWidget {
  const TermsAndConditionsDriver({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Driver Terms & Conditions'),
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
              "Driver Terms & Conditions",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
            ),
            SizedBox(height: 24),
            Text(
              "By registering as a driver with The Delivery Truck (“the App”), you agree to the following legally binding terms and conditions. Your use of the App is at your own risk and subject to the disclaimers, limitations of liability, and indemnification obligations below.",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              "1. Independent Contractor Status\nYou acknowledge that you are an independent contractor and not an employee, agent, or partner of The Delivery Truck...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "2. Vehicle and Insurance Requirements\nYou must maintain valid driver’s licenses...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "3. Service Quality and Conduct\nYou agree to provide safe, respectful, and timely services...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "4. No Liability\nThe Delivery Truck is not liable for any injury, accident...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "5. Indemnification\nYou agree to indemnify and hold harmless The Delivery Truck...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "6. Payment and Subscription\nIf you enroll in a PRO Membership or pay any subscription fees...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "7. Modification of Terms\nWe reserve the right to update these Terms at any time...",
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

import 'package:flutter/material.dart';

class TheTestPage extends StatelessWidget {
  const TheTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> userRoutes = [
      {'name': 'User Home', 'route': '/user_home'},
      {'name': 'Signup User', 'route': '/signup_user'},
      {'name': 'Request Job', 'route': '/request_job'},
      {'name': 'Job Quote', 'route': '/job_quote'},
      {'name': 'Select Driver', 'route': '/select_driver'},
      {'name': 'Payment Authorization', 'route': '/payment_authorization'},
      {'name': 'My Jobs', 'route': '/my_jobs'},
      {'name': 'Edit Job', 'route': '/edit_job'},
      {'name': 'Live Tracking', 'route': '/live_tracking'},
      {'name': 'Review Screen', 'route': '/review'},
      {'name': 'Chat Screen', 'route': '/chat'},
      {'name': 'Confirm Delivery', 'route': '/confirm_delivery'},
      {'name': 'Referral Share', 'route': '/referral_share'},
      {'name': 'Rewards', 'route': '/rewards'},
      {'name': 'Referral Rewards', 'route': '/referral_rewards'},
      {'name': 'Referral Activity', 'route': '/referral_activity'},
      {'name': 'Edit User Profile', 'route': '/edit_user_profile'},
    ];

    final List<Map<String, String>> driverRoutes = [
      {'name': 'Driver Home', 'route': '/driver_home'},
      {'name': 'Signup Driver (Personal)', 'route': '/signup_driver_personal'},
      {'name': 'Signup Driver (Vehicle)', 'route': '/signup_driver_vehicle'},
      {'name': 'Signup Driver (Insurance)', 'route': '/signup_driver_insurance'},
      {'name': 'Available Jobs', 'route': '/available_jobs'},
      {'name': 'My Accepted Jobs', 'route': '/my_accepted_jobs'},
      {'name': 'Upload Pickup Photo', 'route': '/upload_pickup'},
      {'name': 'Mark Delivered', 'route': '/mark_delivered'},
      {'name': 'Driver Earnings', 'route': '/driver_earnings'},
      {'name': 'Edit Driver Profile', 'route': '/edit_driver_profile'},
      {'name': 'Pro Payment', 'route': '/pro_payment'},
    ];

    final List<Map<String, String>> adminRoutes = [
      {'name': 'Admin Dashboard', 'route': '/admin_dashboard'},
      {'name': 'Admin Disputes', 'route': '/admin_disputes'},
      {'name': 'Admin Driver Deactivation', 'route': '/admin_driver_deactivation'},
      {'name': 'Admin Referral History', 'route': '/admin_referral_history'},
    ];

    final List<Map<String, String>> utilityRoutes = [
      {'name': 'Splash Screen', 'route': '/'},
      {'name': 'Landing Screen', 'route': '/landing'},
      {'name': 'Login', 'route': '/login'},
      {'name': 'Forgot Password', 'route': '/forgot_password'},
      {'name': 'Verify Email', 'route': '/verify_email'},
      {'name': 'Report Dispute', 'route': '/report_dispute'},
      {'name': 'Rewards Info', 'route': '/rewards_info'},
      {'name': 'Terms (User)', 'route': '/terms_user'},
      {'name': 'Terms (Driver)', 'route': '/terms_driver'},
      {'name': 'Test Animation', 'route': '/test_animation'},
    ];

    final allRoutes = [
      {'header': '🧍 User Screens', 'routes': userRoutes},
      {'header': '🚚 Driver Screens', 'routes': driverRoutes},
      {'header': '🛠️ Admin Screens', 'routes': adminRoutes},
      {'header': '🧪 Utility & Shared Screens', 'routes': utilityRoutes},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test All Screens'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allRoutes.length,
        itemBuilder: (context, sectionIndex) {
          final section = allRoutes[sectionIndex];
          final header = section['header'] as String;
          final routes = section['routes'] as List<Map<String, String>>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...routes.map((screen) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, screen['route']!, arguments: {
                          'jobId': '123',
                          'driverId': 'demoDriver',
                          'deliveryPhotoUrl': null,
                          'recipientName': 'Test User',
                          'recipientPhone': '555-1234',
                          'jobData': {},
                          'url': 'https://www.thedeliverytruck.com',
                        });
                      },
                      child: Text(screen['name']!),
                    ),
                  )),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

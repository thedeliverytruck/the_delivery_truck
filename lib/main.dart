import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';

// Screens
import 'screens/landing_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_user_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/request_job_screen.dart';
import 'screens/job_summary_screen.dart';
import 'screens/my_jobs_screen.dart';
import 'screens/available_jobs_screen.dart';
import 'screens/my_accepted_jobs_screen.dart';
import 'screens/mark_delivered_screen.dart';
import 'screens/live_tracking_user_screen.dart';
import 'screens/live_tracking_driver_screen.dart';
import 'screens/review_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/edit_job_screen.dart';
import 'screens/upload_pickup_photo_screen.dart';
import 'screens/select_driver_screen.dart';
import 'screens/driver_earnings_screen.dart';
import 'screens/confirm_delivery_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_disputes_screen.dart';
import 'screens/report_dispute_screen.dart';
import 'screens/pro_payment_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/referral_share_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/rewards_info_screen.dart';
import 'screens/referral_rewards_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/terms_and_conditions_user.dart';
import 'screens/terms_and_conditions_driver.dart';
import 'screens/payment_authorization_screen.dart';
import 'screens/job_quote_screen.dart';
import 'screens/admin_driver_location_debug_screen.dart';
import 'screens/admin_driver_location_log_screen.dart';
import 'screens/admin_driver_deactivation_screen.dart';
import 'screens/admin_fraud_alert_screen.dart';
import 'screens/admin_heatmap_screen.dart';
import 'screens/admin_analytics_dashboard_screen.dart';
import 'screens/driver_accept_enroute_screen.dart';
import 'screens/pickup_confirmation_screen.dart';
import 'screens/user_delivery_confirmation_screen.dart';
import 'screens/driver_review_screen.dart';
import 'screens/driver_review_dashboard_screen.dart';
import 'screens/admin_referral_history_screen.dart';
import 'screens/referral_code_entry_screen.dart';

// Driver signup flow
import 'screens/driver_personal_info_screen.dart';
import 'screens/driver_vehicle_info_screen.dart';
import 'screens/driver_insurance_info_screen.dart';

// Profile edit
import 'screens/edit_user_profile_screen.dart';
import 'screens/edit_driver_profile_screen.dart';

// Testing
import 'screens/test_animation_screen.dart';
import 'screens/The_Test_Page.dart';

// Services
import 'services/notification_service.dart';
import 'services/location_update_service.dart';
import 'services/background_fetch_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    Stripe.publishableKey = 'pk_test_51RSzAnFHNqUk7cFRk2qyZ9KP06BqNACsBB1oy9DnB7JjZjruhaz8WcATaawZUsuaLplpPTWU68pf8Hs2AcbWFYfE00a2mKc8pt';
  }

  await NotificationService.initializeFCM();
  await LocationUpdateService.initializeBackgroundFetch();
  BackgroundFetchService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Delivery Truck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.red,
          secondary: Colors.blue,
          background: Colors.black,
          surface: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.yellow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ),
      home: const TheTestPage(),
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>? ?? {};

        switch (settings.name) {
          case '/': return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/landing': return MaterialPageRoute(builder: (_) => const LandingScreen());
          case '/login': return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup_user': return MaterialPageRoute(builder: (_) => const SignUpUserScreen());
          case '/signup_driver_personal': return MaterialPageRoute(builder: (_) => const DriverPersonalInfoScreen());
          case '/signup_driver_vehicle': return MaterialPageRoute(builder: (_) => DriverVehicleInfoScreen(previousData: args));
          case '/signup_driver_insurance': return MaterialPageRoute(builder: (_) => DriverInsuranceInfoScreen(previousData: args));
          case '/user_home': return MaterialPageRoute(builder: (_) => const UserHomeScreen());
          case '/driver_home': return MaterialPageRoute(builder: (_) => const DriverHomeScreen());
          case '/request_job': return MaterialPageRoute(builder: (_) => const RequestJobScreen());
          case '/my_jobs': return MaterialPageRoute(builder: (_) => const MyJobsScreen());
          case '/available_jobs': return MaterialPageRoute(builder: (_) => const AvailableJobsScreen());
          case '/my_accepted_jobs': return MaterialPageRoute(builder: (_) => const MyAcceptedJobsScreen());
          case '/mark_delivered': return MaterialPageRoute(builder: (_) => MarkDeliveredScreen(jobId: args['jobId']));
          case '/live_tracking': return MaterialPageRoute(builder: (_) => LiveTrackingUserScreen(jobId: args['jobId']));
          case '/live_tracking_driver': return MaterialPageRoute(builder: (_) => LiveTrackingDriverScreen(jobId: args['jobId']));
          case '/review': return MaterialPageRoute(builder: (_) => ReviewScreen(jobId: args['jobId'], driverId: args['driverId']));
          case '/chat': return MaterialPageRoute(builder: (_) => ChatScreen(jobId: args['jobId'], recipientName: args['recipientName'], recipientPhone: args['recipientPhone']));
          case '/edit_job': return MaterialPageRoute(builder: (_) => EditJobScreen(jobId: args['jobId'], jobData: args['jobData']));
          case '/upload_pickup': return MaterialPageRoute(builder: (_) => UploadPickupPhotoScreen(jobId: args['jobId']));
          case '/select_driver': return MaterialPageRoute(builder: (_) => SelectDriverScreen(jobId: args['jobId']));
          case '/driver_earnings': return MaterialPageRoute(builder: (_) => const DriverEarningsScreen());
          case '/confirm_delivery': return MaterialPageRoute(builder: (_) => ConfirmDeliveryScreen(jobId: args['jobId'], driverId: args['driverId'], deliveryPhotoUrl: args['deliveryPhotoUrl']));
          case '/pickup_confirm': return MaterialPageRoute(builder: (_) => PickupConfirmationScreen(jobId: args['jobId'], userId: args['userId']));
          case '/user_delivery_confirm': return MaterialPageRoute(builder: (_) => UserDeliveryConfirmationScreen(jobId: args['jobId'], driverId: args['driverId'], deliveryPhotoUrl: args['deliveryPhotoUrl']));
          case '/driver_reviews': return MaterialPageRoute(builder: (_) => DriverReviewScreen(driverId: args['driverId']));
          case '/driver_review_dashboard': return MaterialPageRoute(builder: (_) => const DriverReviewDashboardScreen());
          case '/admin_dashboard': return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
          case '/admin_disputes': return MaterialPageRoute(builder: (_) => const AdminDisputesScreen());
          case '/admin_driver_debug': return MaterialPageRoute(builder: (_) => const AdminDriverLocationDebugScreen());
          case '/admin_driver_log': return MaterialPageRoute(builder: (_) => const AdminDriverLocationLogScreen());
          case '/admin_fraud_alerts': return MaterialPageRoute(builder: (_) => const AdminFraudAlertScreen());
          case '/admin_deactivate_driver': return MaterialPageRoute(builder: (_) => const AdminDriverDeactivationScreen());
          case '/admin_heatmap': return MaterialPageRoute(builder: (_) => const AdminHeatmapScreen());
          case '/admin_analytics': return MaterialPageRoute(builder: (_) => const AdminAnalyticsDashboardScreen());
          case '/admin_referral_history': return MaterialPageRoute(builder: (_) => const AdminReferralHistoryScreen());
          case '/referral_code_entry': return MaterialPageRoute(builder: (_) => const ReferralCodeEntryScreen());
          case '/report_dispute': return MaterialPageRoute(builder: (_) => ReportDisputeScreen(jobId: args['jobId']));
          case '/pro_payment': return MaterialPageRoute(builder: (_) => const ProPaymentScreen());
          case '/webview': return MaterialPageRoute(builder: (_) => WebviewScreen(url: args['url']));
          case '/referral_share': return MaterialPageRoute(builder: (_) => const ReferralShareScreen());
          case '/rewards': return MaterialPageRoute(builder: (_) => const RewardsScreen());
          case '/rewards_info': return MaterialPageRoute(builder: (_) => const RewardsInfoScreen());
          case '/referral_rewards': return MaterialPageRoute(builder: (_) => const ReferralRewardsScreen());
          case '/edit_user_profile': return MaterialPageRoute(builder: (_) => const EditUserProfileScreen());
          case '/edit_driver_profile': return MaterialPageRoute(builder: (_) => const EditDriverProfileScreen());
          case '/forgot_password': return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
          case '/verify_email': return MaterialPageRoute(builder: (_) => const VerifyEmailScreen());
          case '/terms_user': return MaterialPageRoute(builder: (_) => const TermsAndConditionsUser());
          case '/terms_driver': return MaterialPageRoute(builder: (_) => const TermsAndConditionsDriver());
          case '/test_animation': return MaterialPageRoute(builder: (_) => const TestAnimationScreen());
          case '/test_page': return MaterialPageRoute(builder: (_) => const TheTestPage());
          case '/job_quote': return MaterialPageRoute(builder: (_) => JobQuoteScreen(jobId: args['jobId']));
          case '/payment_authorization': return MaterialPageRoute(builder: (_) => PaymentAuthorizationScreen(jobId: args['jobId'], driverId: args['driverId']));
          case '/driver_accept': return MaterialPageRoute(builder: (_) => DriverAcceptEnRouteScreen(jobId: args['jobId']));
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Page not found')),
              ),
            );
        }
      },
    );
  }
}

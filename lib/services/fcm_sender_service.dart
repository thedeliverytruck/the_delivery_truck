import 'dart:convert';
import 'package:http/http.dart' as http;

class FcmSenderService {
  static const String _fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

  // WARNING: For testing only. Do not hardcode server key in production builds.
  static const String _serverKey = 'AIzaSyB3aiaORbRanOQ1ottLSHHnUca6pSmeHW8';

  static Future<void> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
  }) async {
    final message = {
      'to': token,
      'notification': {
        'title': title,
        'body': body,
      },
      'priority': 'high',
    };

    try {
      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('FCM notification sent successfully');
      } else {
        print('FCM send failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Notification Error: $e');
    }
  }
}

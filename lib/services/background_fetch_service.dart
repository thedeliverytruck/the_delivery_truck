import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class BackgroundFetchService {
  static void initialize() {
    BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15, // in minutes
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiredNetworkType: NetworkType.ANY,
      ),
      _onBackgroundFetch,
      _onBackgroundFetchTimeout,
    );
  }

  static Future<void> _onBackgroundFetch(String taskId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      BackgroundFetch.finish(taskId);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('drivers').doc(user.uid).update({
        'currentLocation': locationData,
      });

      debugPrint('📦 Background location update complete.');
    } catch (e) {
      debugPrint('⚠️ Background fetch failed: $e');
    }

    BackgroundFetch.finish(taskId);
  }

  static void _onBackgroundFetchTimeout(String taskId) {
    debugPrint('⏱ BackgroundFetch TIMEOUT: $taskId');
    BackgroundFetch.finish(taskId);
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class LocationUpdateService {
  static StreamSubscription<Position>? _positionStream;

  /// 🔧 Add this method to fix the missing member error
  static Future<void> initializeBackgroundFetch() async {
    debugPrint('✅ initializeBackgroundFetch() called');
    // Add any future background fetch setup logic here
  }

  static Future<void> startLocationUpdates(String jobId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final permission = await _getLocationPermission();
    if (permission == null) return;

    final jobRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((Position position) async {
      final jobSnapshot = await jobRef.get();
      if (!jobSnapshot.exists) return;
      final jobData = jobSnapshot.data();
      if (jobData == null || jobData['status'] != 'accepted') return;

      final timestamp = DateTime.now().toIso8601String();
      final data = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'accuracy': position.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await jobRef.update({'driverLocation': data});
      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'currentLocation': data,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lastLat', position.latitude);
      await prefs.setDouble('lastLng', position.longitude);
      await prefs.setDouble('lastSpeed', position.speed);
      await prefs.setDouble('lastHeading', position.heading);

      debugPrint('📍 Location updated: ${position.latitude}, ${position.longitude}');

      final dropOff = jobData['dropoffLocation'];
      if (dropOff != null) {
        final eta = await _calculateETAWithTraffic(
          position.latitude,
          position.longitude,
          dropOff['latitude'],
          dropOff['longitude'],
        );
        if (eta != null) {
          await jobRef.update({'estimatedArrival': eta});
          debugPrint('⏱ ETA (with traffic): $eta minutes');
        }
      }

      await FirebaseFirestore.instance.collection('driver_location_logs').add({
        'driverId': uid,
        'jobId': jobId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'accuracy': position.accuracy,
        'loggedAt': FieldValue.serverTimestamp(),
        'deviceTime': timestamp,
      });
    });
  }

  static Future<LocationPermission?> _getLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
      debugPrint('❌ Location permission not granted.');
      return null;
    }

    return permission;
  }

  static void stopLocationUpdates() {
    _positionStream?.cancel();
    _positionStream = null;
    debugPrint('🛑 Location updates stopped');
  }

  static Future<int?> _calculateETAWithTraffic(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    const apiKey = 'AIzaSyCh-O9NUty2VEG6R0nQIbl5MQFV6GgHXVg'; // Replace if needed
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=$originLat,$originLng&destinations=$destLat,$destLng'
      '&mode=driving&departure_time=now&traffic_model=best_guess&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' &&
          data['rows'][0]['elements'][0]['status'] == 'OK') {
        final duration = data['rows'][0]['elements'][0]['duration_in_traffic']['value'];
        return (duration / 60).round();
      }
    } catch (e) {
      debugPrint('⚠️ ETA calculation failed: $e');
    }
    return null;
  }

  static Future<void> updateOnceIfActiveJob(String jobId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final permission = await _getLocationPermission();
    if (permission == null) return;

    final position = await Geolocator.getCurrentPosition();
    final jobRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);
    final jobSnapshot = await jobRef.get();

    if (!jobSnapshot.exists || jobSnapshot.data()?['status'] != 'accepted') {
      debugPrint('⏸ No active job. Skipping location update.');
      return;
    }

    final data = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': position.speed,
      'heading': position.heading,
      'accuracy': position.accuracy,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await jobRef.update({'driverLocation': data});
    await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
      'currentLocation': data,
    });

    debugPrint('✅ One-time background location update complete.');
  }
}

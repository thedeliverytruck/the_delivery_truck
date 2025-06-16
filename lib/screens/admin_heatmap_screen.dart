import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/custom_app_bar.dart';

class AdminHeatmapScreen extends StatefulWidget {
  const AdminHeatmapScreen({super.key});

  @override
  State<AdminHeatmapScreen> createState() => _AdminHeatmapScreenState();
}

class _AdminHeatmapScreenState extends State<AdminHeatmapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Circle> _pickupCircles = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // Default: San Francisco
    zoom: 10,
  );

  @override
  void initState() {
    super.initState();
    _loadPickupLocations();
  }

  Future<void> _loadPickupLocations() async {
    final snapshot = await FirebaseFirestore.instance.collection('jobs').get();

    Set<Circle> circles = {};
    int circleId = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final lat = data['pickupLat'];
      final lng = data['pickupLng'];

      if (lat != null && lng != null) {
        circles.add(Circle(
          circleId: CircleId('pickup_$circleId'),
          center: LatLng(lat, lng),
          radius: 200, // meters
          fillColor: Colors.red.withOpacity(0.4),
          strokeColor: Colors.red,
          strokeWidth: 1,
        ));
        circleId++;
      }
    }

    setState(() {
      _pickupCircles.clear();
      _pickupCircles.addAll(circles);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Admin Heatmap', showHome: true, showDriverHome: true, showUserHome: true),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: (controller) => _mapController.complete(controller),
        circles: _pickupCircles,
        mapType: MapType.normal,
        myLocationEnabled: false,
        zoomControlsEnabled: true,
        compassEnabled: true,
      ),
    );
  }
}

import 'dart:math';
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
  GoogleMapController? mapController;
  List<LatLng> driverLocations = [];
  bool showHeatmap = true;

  @override
  void initState() {
    super.initState();
    _fetchDriverLocations();
  }

  Future<void> _fetchDriverLocations() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collectionGroup('driver_location_logs')
        .get();

    final locations = querySnapshot.docs.map((doc) {
      final data = doc.data();
      return LatLng(data['latitude'], data['longitude']);
    }).toList();

    setState(() {
      driverLocations = locations;
    });
  }

  Set<Circle> _generateHeatmapCircles() {
    Map<String, int> gridCounts = {};

    for (var loc in driverLocations) {
      final key = '${(loc.latitude * 10).round()},${(loc.longitude * 10).round()}';
      gridCounts[key] = (gridCounts[key] ?? 0) + 1;
    }

    return gridCounts.entries.map((entry) {
      final parts = entry.key.split(',');
      final lat = int.parse(parts[0]) / 10;
      final lng = int.parse(parts[1]) / 10;
      final intensity = entry.value;
      final radius = min(300 + intensity * 10, 1000.0);

      return Circle(
        circleId: CircleId(entry.key),
        center: LatLng(lat, lng),
        radius: radius,
        fillColor: Colors.red.withOpacity(min(0.1 + intensity * 0.05, 0.6)),
        strokeColor: Colors.transparent,
      );
    }).toSet();
  }

  Set<Marker> _buildMarkers() {
    return driverLocations.asMap().entries.map((entry) {
      return Marker(
        markerId: MarkerId('m${entry.key}'),
        position: entry.value,
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final center = driverLocations.isNotEmpty
        ? driverLocations.first
        : const LatLng(37.7749, -122.4194); // fallback to SF

    return Scaffold(
      appBar: const CustomAppBar(title: 'Driver Heatmap'),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Show Heatmap', style: TextStyle(color: Colors.white)),
            value: showHeatmap,
            onChanged: (value) => setState(() => showHeatmap = value),
            activeColor: Colors.red,
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(target: center, zoom: 10),
              markers: showHeatmap ? {} : _buildMarkers(),
              circles: showHeatmap ? _generateHeatmapCircles() : {},
              myLocationEnabled: false,
              mapToolbarEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}

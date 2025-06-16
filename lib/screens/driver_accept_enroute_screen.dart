import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class DriverAcceptEnRouteScreen extends StatefulWidget {
  final String jobId;

  const DriverAcceptEnRouteScreen({super.key, required this.jobId});

  @override
  State<DriverAcceptEnRouteScreen> createState() => _DriverAcceptEnRouteScreenState();
}

class _DriverAcceptEnRouteScreenState extends State<DriverAcceptEnRouteScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? jobData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
      if (doc.exists) {
        setState(() {
          jobData = doc.data();
          _isLoading = false;
        });
      } else {
        throw Exception("Job not found");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error loading job: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptJob() async {
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null) return;

    await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
      'driverAccepted': true,
      'driverAcceptedAt': FieldValue.serverTimestamp(),
      'status': 'accepted',
    });

    _fetchJobDetails(); // Refresh UI
  }

  Future<void> _goEnRoute() async {
    bool permission = await _requestLocationPermission();
    if (!permission) return;

    await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
      'status': 'en_route',
      'enrouteAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/live_tracking_driver', arguments: {
      'jobId': widget.jobId,
    });
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 12),
      ],
    );
  }

  double _calculateDriverPayout(double miles, bool indoor, bool multiFloor) {
    double payout = 20 + (5 * miles);
    if (indoor) payout += 10;
    if (multiFloor) payout += 15;
    return payout;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: const CustomAppBar(title: 'Job Details'),
        body: Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),
      );
    }

    final pickup = jobData!['pickupAddress'] ?? 'N/A';
    final dropoff = jobData!['dropoffAddress'] ?? 'N/A';
    final item = jobData!['itemDescription'] ?? 'N/A';
    final instructions = jobData!['specialInstructions'] ?? '';
    final userName = jobData!['userFirstName'] ?? 'User';
    final userLastInitial = jobData!['userLastName'] != null ? jobData!['userLastName'][0] : '';
    final miles = jobData!['distance']?.toDouble() ?? 0.0;
    final indoor = jobData!['deliveryLocation'] == 'Inside First Floor';
    final multiFloor = jobData!['deliveryLocation'] == 'Inside Multi-Floor';
    final payout = _calculateDriverPayout(miles, indoor, multiFloor).toStringAsFixed(2);
    final status = jobData!['status'] ?? 'unknown';
    final length = jobData!['length']?.toString() ?? 'N/A';
    final width = jobData!['width']?.toString() ?? 'N/A';
    final depth = jobData!['depth']?.toString() ?? 'N/A';
    final barcode = jobData!['barcode'] ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Job Assignment'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(child: Image.asset('assets/icon/icon2.png', height: 80)),
            const SizedBox(height: 24),
            _buildInfoRow("Pickup Location", pickup),
            _buildInfoRow("Drop-off Location", dropoff),
            _buildInfoRow("Special Instructions", instructions),
            _buildInfoRow("Item Description", item),
            _buildInfoRow("Package Dimensions", "$length x $width x $depth in."),
            _buildInfoRow("Barcode", barcode),
            _buildInfoRow("Distance (miles)", miles.toStringAsFixed(1)),
            _buildInfoRow("User", "$userName $userLastInitial."),
            const SizedBox(height: 12),
            if (jobData!['images'] != null && (jobData!['images'] as List).isNotEmpty)
              _buildImagePreviews(jobData!['images']),
            const SizedBox(height: 20),
            Text(
              "Driver Payout: \$$payout",
              style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            if (status == 'assigned' || status == 'driver_selected')
              PrimaryButton(text: "✅ Accept Job", onPressed: _acceptJob, isLoading: false),
            if (status == 'accepted')
              PrimaryButton(text: "🚗 Go En Route", onPressed: _goEnRoute, isLoading: false),
            if (status == 'en_route')
              PrimaryButton(
                text: "📍 View Live Tracking",
                onPressed: () {
                  Navigator.pushNamed(context, '/live_tracking_driver', arguments: {
                    'jobId': widget.jobId,
                  });
                },
                isLoading: false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviews(List images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Item Photos", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: images.map<Widget>((imgUrl) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.network(imgUrl, height: 100),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/fcm_sender_service.dart';
import 'driver_reviews_screen.dart';
import '../widgets/custom_app_bar.dart';

class SelectDriverScreen extends StatefulWidget {
  final String jobId;

  const SelectDriverScreen({super.key, required this.jobId});

  @override
  State<SelectDriverScreen> createState() => _SelectDriverScreenState();
}

class _SelectDriverScreenState extends State<SelectDriverScreen> {
  List<Map<String, dynamic>> allDrivers = [];
  Position? currentPosition;
  String selectedTrailerType = 'Any';
  int selectedRadius = 15;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => currentPosition = position);
  }

  double _calculateDistance(double lat, double lng) {
    if (currentPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      lat,
      lng,
    ) / 1609.34;
  }

  Future<void> _fetchDrivers() async {
    final snapshot = await FirebaseFirestore.instance.collection('drivers').get();
    final fetched = snapshot.docs.map((doc) {
      final data = doc.data();
      final lat = data['location']?['latitude'];
      final lng = data['location']?['longitude'];
      final distance = (lat != null && lng != null) ? _calculateDistance(lat, lng) : double.infinity;
      return {
        'id': doc.id,
        ...data,
        'distance': distance,
      };
    }).toList();

    setState(() {
      allDrivers = fetched;
    });
  }

  Future<void> _selectDriver(
    BuildContext context,
    String driverId,
    String driverName,
    String? fcmToken,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'driverId': driverId,
        'status': 'driver_selected',
        'selectionTimestamp': FieldValue.serverTimestamp(),
      });

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await FcmSenderService.sendNotificationToToken(
          token: fcmToken,
          title: "You've been selected!",
          body: "A user has chosen you for their delivery request.",
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver "$driverName" has been selected.')),
        );

        Navigator.pushNamed(context, '/driver_job_acceptance', arguments: {
          'jobId': widget.jobId,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting driver: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _filteredDrivers() {
    return allDrivers.where((driver) {
      final distance = driver['distance'] ?? double.infinity;
      if (distance > selectedRadius) return false;

      if (selectedTrailerType != 'Any') {
        final trailers = List<String>.from(driver['trailerTypes'] ?? []);
        if (!trailers.contains(selectedTrailerType)) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final aIsPro = a['isPro'] == true;
        final bIsPro = b['isPro'] == true;
        if (aIsPro && !bIsPro) return -1;
        if (!aIsPro && bIsPro) return 1;
        return (a['distance'] ?? double.infinity).compareTo(b['distance'] ?? double.infinity);
      });
  }

  Widget _greenCheck(bool condition) {
    return condition
        ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
        : const Icon(Icons.cancel, color: Colors.grey, size: 20);
  }

  @override
  Widget build(BuildContext context) {
    final filteredDrivers = _filteredDrivers();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Select a Driver',
        showBackButton: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Center(child: Image.asset('assets/icon/icon2.png', height: 80)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text("Radius:", style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: selectedRadius,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  items: [10, 15, 20, 30].map((radius) {
                    return DropdownMenuItem<int>(
                      value: radius,
                      child: Text("$radius mi"),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedRadius = value!),
                ),
                const Spacer(),
                const Text("Trailer:", style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedTrailerType,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  items: ['Any', 'Open', 'Enclosed', 'Dump Style'].map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedTrailerType = value!),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredDrivers.isEmpty
                ? const Center(child: Text("No matching drivers.", style: TextStyle(color: Colors.white)))
                : ListView.builder(
                    itemCount: filteredDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = filteredDrivers[index];
                      final name = driver['firstName'] != null && driver['lastName'] != null
                          ? "${driver['firstName']} ${driver['lastName'][0]}."
                          : driver['name'] ?? 'Unnamed';
                      final distance = driver['distance']?.toStringAsFixed(1) ?? 'N/A';
                      final photoUrl = driver['headshotUrl'];
                      final vehicle = "${driver['vehicleMake'] ?? ''} ${driver['vehicleModel'] ?? ''}";
                      final rating = driver['rating'] ?? 5.0;
                      final deliveries = driver['completedDeliveries'] ?? 0;

                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                  backgroundColor: Colors.yellow,
                                  child: photoUrl == null
                                      ? Text(name[0], style: const TextStyle(color: Colors.black))
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 18)),
                                    const SizedBox(width: 8),
                                    if (driver['isPro'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          "PRO",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Vehicle: $vehicle", style: const TextStyle(color: Colors.white70)),
                                    Text("Distance: $distance mi", style: const TextStyle(color: Colors.white70)),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.yellow, size: 16),
                                        Text(" $rating", style: const TextStyle(color: Colors.white70)),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.local_shipping, color: Colors.green, size: 16),
                                        Text(" $deliveries delivered", style: const TextStyle(color: Colors.white70)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                  onPressed: () => _selectDriver(
                                    context,
                                    driver['id'],
                                    name,
                                    driver['fcmToken'],
                                  ),
                                  child: const Text("Select"),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _greenCheck(driver['hasInsurance'] == true),
                                  const SizedBox(width: 4),
                                  const Text("Insurance", style: TextStyle(color: Colors.white70)),
                                  const SizedBox(width: 12),
                                  _greenCheck(driver['hasGLInsurance'] == true),
                                  const SizedBox(width: 4),
                                  const Text("GL", style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.reviews, color: Colors.blue),
                                  label: const Text("View Reviews", style: TextStyle(color: Colors.blue)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DriverReviewsScreen(driverId: driver['id']),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

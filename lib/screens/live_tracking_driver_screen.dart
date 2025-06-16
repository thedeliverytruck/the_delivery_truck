// FULLY UPDATED FILE

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_app_bar.dart';

class LiveTrackingDriverScreen extends StatefulWidget {
  final String jobId;

  const LiveTrackingDriverScreen({super.key, required this.jobId});

  @override
  State<LiveTrackingDriverScreen> createState() => _LiveTrackingDriverScreenState();
}

class _LiveTrackingDriverScreenState extends State<LiveTrackingDriverScreen> {
  GoogleMapController? _mapController;
  Map<String, dynamic>? jobData;
  Position? currentPosition;
  StreamSubscription<DocumentSnapshot>? jobSubscription;
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _fetchJobAndListen();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    jobSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchJobAndListen() async {
    final jobRef = FirebaseFirestore.instance.collection('jobs').doc(widget.jobId);
    jobSubscription = jobRef.snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        setState(() => jobData = snapshot.data());
        await _drawRoutePolylines();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => currentPosition = position);
  }

  Future<void> _drawRoutePolylines() async {
    if (jobData == null || currentPosition == null) return;

    final pickupLat = jobData!['pickupLat'];
    final pickupLng = jobData!['pickupLng'];
    final dropoffLat = jobData!['dropoffLat'];
    final dropoffLng = jobData!['dropoffLng'];

    if (pickupLat == null || pickupLng == null || dropoffLat == null || dropoffLng == null) return;

    final origin = "${currentPosition!.latitude},${currentPosition!.longitude}";
    final pickup = "$pickupLat,$pickupLng";
    final dropoff = "$dropoffLat,$dropoffLng";

    final poly1 = await _fetchPolyline(origin, pickup, Colors.green, "driver_to_pickup");
    final poly2 = await _fetchPolyline(pickup, dropoff, Colors.blue, "pickup_to_dropoff");

    setState(() {
      polylines = {if (poly1 != null) poly1, if (poly2 != null) poly2};
    });
  }

  Future<Polyline?> _fetchPolyline(String origin, String dest, Color color, String id) async {
    const apiKey = "AIzaSyCh-O9NUty2VEG6R0nQIbl5MQFV6GgHXVg";
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&key=$apiKey",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final points = json['routes'][0]['overview_polyline']['points'];
      final polylinePoints = _decodePolyline(points);
      return Polyline(
        polylineId: PolylineId(id),
        points: polylinePoints,
        color: color,
        width: 6,
      );
    }

    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : result >> 1);
      lng += deltaLng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void _openGoogleMapsDirections(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _notifyDelay() async {
    await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
      'driverNotifiedDelay': true,
      'delayAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User notified of delay.")),
    );
  }

  Future<void> _requestCancelJob() async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Request Cancellation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Why are you canceling this job?"),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Unsafe location, vehicle problem, etc.",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Nevermind"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Submit"),
          ),
        ],
      ),
    );

    if (confirm == true && reasonController.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'status': 'cancel_requested_by_driver',
        'cancelRequestedReason': reasonController.text.trim(),
        'cancelRequestedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cancellation request submitted.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (jobData == null || currentPosition == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pickupLat = jobData!['pickupLat'];
    final pickupLng = jobData!['pickupLng'];
    final dropoffLat = jobData!['dropoffLat'];
    final dropoffLng = jobData!['dropoffLng'];
    final userName = jobData!['userFirstName'] ?? 'User';
    final pickupAddress = jobData!['pickupAddress'] ?? 'N/A';
    final dropoffAddress = jobData!['dropoffAddress'] ?? 'N/A';
    final itemDescription = jobData!['itemDescription'] ?? 'N/A';
    final deliveryLocation = jobData!['deliveryLocation'] ?? 'Curbside';

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(currentPosition!.latitude, currentPosition!.longitude),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      if (pickupLat != null && pickupLng != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickupLat, pickupLng),
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      if (dropoffLat != null && dropoffLng != null)
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(dropoffLat, dropoffLng),
          infoWindow: const InfoWindow(title: 'Drop-off'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Live Delivery Tracking', showBackButton: true),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                zoom: 13,
              ),
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[900],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("User: $userName", style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Pickup: $pickupAddress", style: const TextStyle(color: Colors.white)),
                  Text("Drop-off: $dropoffAddress", style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Item: $itemDescription", style: const TextStyle(color: Colors.white)),
                  Text("Delivery: $deliveryLocation", style: const TextStyle(color: Colors.white)),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (dropoffLat != null && dropoffLng != null) {
                              _openGoogleMapsDirections(dropoffLat, dropoffLng);
                            }
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text("Directions"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _notifyDelay,
                          icon: const Icon(Icons.access_time),
                          label: const Text("Notify Delay"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _requestCancelJob,
                      icon: const Icon(Icons.cancel, color: Colors.redAccent),
                      label: const Text("Request Cancel", style: TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

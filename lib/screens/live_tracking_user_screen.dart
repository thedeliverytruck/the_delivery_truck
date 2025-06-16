import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../widgets/custom_app_bar.dart';

class LiveTrackingUserScreen extends StatefulWidget {
  final String jobId;

  const LiveTrackingUserScreen({super.key, required this.jobId});

  @override
  State<LiveTrackingUserScreen> createState() => _LiveTrackingUserScreenState();
}

class _LiveTrackingUserScreenState extends State<LiveTrackingUserScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  LatLng? _driverLatLng;
  String? _eta;
  Polyline? _routeLine;

  StreamSubscription<DocumentSnapshot>? _jobSubscription;
  Map<String, dynamic>? _jobData;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final String _apiKey = 'AIzaSyCh-O9NUty2VEG6R0nQIbl5MQFV6GgHXVg';

  @override
  void initState() {
    super.initState();
    _loadJobDataAndListen();
  }

  @override
  void dispose() {
    _jobSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadJobDataAndListen() async {
    final docRef = FirebaseFirestore.instance.collection('jobs').doc(widget.jobId);

    _jobSubscription = docRef.snapshots().listen((doc) async {
      final data = doc.data();
      if (data == null) return;
      _jobData = data;

      if (_pickupLatLng == null && data['pickupAddress'] != null) {
        final places = await locationFromAddress(data['pickupAddress']);
        if (places.isNotEmpty) {
          _pickupLatLng = LatLng(places[0].latitude, places[0].longitude);
        }
      }

      if (_dropoffLatLng == null && data['deliveryAddress'] != null) {
        final places = await locationFromAddress(data['deliveryAddress']);
        if (places.isNotEmpty) {
          _dropoffLatLng = LatLng(places[0].latitude, places[0].longitude);
        }
      }

      final driverData = data['driverLocation'];
      if (driverData != null) {
        _driverLatLng = LatLng(driverData['latitude'], driverData['longitude']);
        await _fetchEtaAndRoute();
      }

      _updateMarkers();

      if (_driverLatLng != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_driverLatLng!),
        );
      }
    });
  }

  void _updateMarkers() {
    final newMarkers = <Marker>{};

    if (_pickupLatLng != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLatLng!,
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (_dropoffLatLng != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: _dropoffLatLng!,
        infoWindow: const InfoWindow(title: 'Drop-off'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    if (_driverLatLng != null) {
      final speed = _jobData?['driverLocation']?['speed'];
      final accuracy = _jobData?['driverLocation']?['accuracy'];

      newMarkers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _driverLatLng!,
        infoWindow: InfoWindow(
          title: 'Driver',
          snippet:
              'Speed: ${speed?.toStringAsFixed(1) ?? 'N/A'} m/s\nAccuracy: ${accuracy?.toStringAsFixed(1) ?? 'N/A'} m',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  Future<void> _fetchEtaAndRoute() async {
    if (_driverLatLng == null || _dropoffLatLng == null) return;

    final origin = '${_driverLatLng!.latitude},${_driverLatLng!.longitude}';
    final destination = '${_dropoffLatLng!.latitude},${_dropoffLatLng!.longitude}';

    final etaUrl =
        'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$origin&destinations=$destination&key=$_apiKey';
    final etaResponse = await http.get(Uri.parse(etaUrl));
    final etaData = json.decode(etaResponse.body);

    if (etaData['rows'] != null &&
        etaData['rows'][0]['elements'][0]['duration'] != null) {
      setState(() {
        _eta = etaData['rows'][0]['elements'][0]['duration']['text'];
      });
    }

    final directionsUrl =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$_apiKey';
    final directionsResponse = await http.get(Uri.parse(directionsUrl));
    final directionsData = json.decode(directionsResponse.body);

    if (directionsData['routes'].isNotEmpty) {
      final points = directionsData['routes'][0]['overview_polyline']['points'];
      final List<LatLng> polylineCoords = _decodePolyline(points);
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: polylineCoords,
        color: Colors.blue,
        width: 5,
      );

      setState(() {
        _routeLine = polyline;
        _polylines.clear();
        _polylines.add(polyline);
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length, lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  void _manualRefresh() {
    _fetchEtaAndRoute();
    _updateMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final user = _jobData?['userFirstName'];
    final driverPhoto = _jobData?['driverPhotoUrl'];
    final vehiclePhoto = _jobData?['vehiclePhotoUrl'];

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Live Delivery Tracking',
        showBackButton: true,
        extraWidget: Row(
          children: [
            if (_eta != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "ETA: $_eta",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _manualRefresh,
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(37.7749, -122.4194),
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationButtonEnabled: true,
              myLocationEnabled: false,
            ),
          ),
          if (_jobData != null)
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[900],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Driver: $user", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    if (driverPhoto != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.network(driverPhoto, height: 60),
                      ),
                    if (vehiclePhoto != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.network(vehiclePhoto, height: 60),
                      ),
                    const SizedBox(height: 8),
                    Text("Pickup: ${_jobData!['pickupAddress'] ?? 'N/A'}",
                        style: const TextStyle(color: Colors.white70)),
                    Text("Drop-off: ${_jobData!['deliveryAddress'] ?? 'N/A'}",
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text("Status: ${_jobData!['status'] ?? 'N/A'}",
                        style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

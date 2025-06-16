import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';

class AvailableJobsScreen extends StatefulWidget {
  const AvailableJobsScreen({super.key});

  @override
  State<AvailableJobsScreen> createState() => _AvailableJobsScreenState();
}

class _AvailableJobsScreenState extends State<AvailableJobsScreen> {
  Position? _driverPosition;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);

    try {
      _driverPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('status', isEqualTo: 'requested')
          .get();

      final jobs = snapshot.docs;

      jobs.sort((a, b) {
        final aLat = a['pickupLat'];
        final aLng = a['pickupLng'];
        final bLat = b['pickupLat'];
        final bLng = b['pickupLng'];

        final aDistance = (aLat != null && aLng != null)
            ? Geolocator.distanceBetween(_driverPosition!.latitude, _driverPosition!.longitude, aLat, aLng)
            : double.infinity;

        final bDistance = (bLat != null && bLng != null)
            ? Geolocator.distanceBetween(_driverPosition!.latitude, _driverPosition!.longitude, bLat, bLng)
            : double.infinity;

        return aDistance.compareTo(bDistance);
      });

      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load jobs: $e')),
      );
    }
  }

  Future<void> _acceptJob(String jobId) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 'accepted',
        'driverId': AuthService.currentUser!.uid,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job accepted!')),
        );
        _loadJobs();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept job: $e')),
      );
    }
  }

  String _formatDistance(double meters) {
    final miles = meters * 0.000621371;
    return '${miles.toStringAsFixed(1)} mi away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Available Jobs'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : _jobs.isEmpty
              ? const Center(
                  child: Text(
                    'No available jobs at the moment.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: _jobs.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final job = _jobs[index].data();
                    final jobId = _jobs[index].id;
                    final pickupLat = job['pickupLat'];
                    final pickupLng = job['pickupLng'];

                    double? distance;
                    if (_driverPosition != null && pickupLat != null && pickupLng != null) {
                      distance = Geolocator.distanceBetween(
                        _driverPosition!.latitude,
                        _driverPosition!.longitude,
                        pickupLat,
                        pickupLng,
                      );
                    }

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (job['imageUrl'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  job['imageUrl'],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              job['description'] ?? 'No Description',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pickup: ${job['pickupLocationName'] ?? 'Unknown'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Drop-off: ${job['dropoffLocationName'] ?? 'Unknown'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if (distance != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _formatDistance(distance),
                                  style: const TextStyle(color: Colors.yellow),
                                ),
                              ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              text: 'Accept Job',
                              icon: Icons.check_circle,
                              onPressed: () => _acceptJob(jobId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

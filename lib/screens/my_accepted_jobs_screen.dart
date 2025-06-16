import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class MyAcceptedJobsScreen extends StatefulWidget {
  const MyAcceptedJobsScreen({super.key});

  @override
  State<MyAcceptedJobsScreen> createState() => _MyAcceptedJobsScreenState();
}

class _MyAcceptedJobsScreenState extends State<MyAcceptedJobsScreen> {
  late Future<List<Map<String, dynamic>>> _acceptedJobsFuture;

  @override
  void initState() {
    super.initState();
    _acceptedJobsFuture = _fetchAcceptedJobs();
  }

  Future<List<Map<String, dynamic>>> _fetchAcceptedJobs() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['accepted', 'in_progress'])
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'My Accepted Jobs',
        showBackButton: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _acceptedJobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You have no accepted jobs.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final jobs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['itemDescription'] ?? 'No Description',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pickup: ${job['pickupLocation'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Drop-off: ${job['dropoffLocation'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        text: 'Mark Delivered',
                        icon: Icons.delivery_dining,
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/mark_delivered',
                            arguments: {'jobId': job['id']},
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

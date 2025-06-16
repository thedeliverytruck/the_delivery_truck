import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/location_update_service.dart';
import 'live_tracking_user_screen.dart';
import 'upload_pickup_photo_screen.dart';
import 'confirm_delivery_screen.dart';
import 'report_dispute_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class JobSummaryScreen extends StatelessWidget {
  final String jobId;

  const JobSummaryScreen({super.key, required this.jobId});

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchJob() async {
    return FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat.yMd().add_jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Job Summary'),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _fetchJob(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text("Job not found.", style: TextStyle(color: Colors.white)));
          }

          final job = snapshot.data!.data()!;
          final status = job['status'] ?? 'pending';

          // Handle driver cancellation request
          if (status == 'cancel_requested_by_driver') {
            Future.microtask(() async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Driver Requested Cancellation"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("The driver has requested to cancel this delivery."),
                      const SizedBox(height: 12),
                      if (job['cancelRequestedReason'] != null)
                        Text("Reason: ${job['cancelRequestedReason']}", style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Keep Driver"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Find Another Driver"),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
                  'status': 'driver_cancelled',
                  'cancelledAt': FieldValue.serverTimestamp(),
                  'cancelledBy': 'user_accept',
                });

                Navigator.pushReplacementNamed(
                  context,
                  '/select_driver',
                  arguments: {'jobId': jobId},
                );
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (job['itemPhotoUrl'] != null)
                  Center(
                    child: Image.network(
                      job['itemPhotoUrl'],
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                _infoText("Pickup Name", job['pickupName']),
                _infoText("Pickup Address", job['pickupAddress']),
                _infoText("Item", job['itemDescription']),
                _infoText("Size", job['itemSize']),
                _infoText("Weight", job['itemWeight']),
                _infoText("Delivery Type", job['deliveryType']),
                if ((job['deliveryFloors'] ?? '').toString().isNotEmpty)
                  _infoText("Floors", job['deliveryFloors']),
                const SizedBox(height: 12),
                _highlightText("Status: $status"),
                _highlightText("Estimated Price: \$${(job['estimatedPrice'] ?? 0).toStringAsFixed(2)}"),
                if (job['createdAt'] != null)
                  _infoText("Created", _formatDate(job['createdAt'])),
                const SizedBox(height: 24),

                // Action Buttons
                if (status == 'accepted' || status == 'en_route')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (status == 'accepted')
                        PrimaryButton(
                          text: "Start Delivery (Send Location)",
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
                              'status': 'en_route',
                            });
                            LocationUpdateService.startLocationUpdates(jobId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Started delivery & tracking location.')),
                              );
                            }
                          },
                        ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        text: "Track Driver",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveTrackingUserScreen(jobId: jobId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                if (status == 'en_route')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: "Upload Pickup Photo",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UploadPickupPhotoScreen(jobId: jobId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                if (status == 'picked_up')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: "Confirm Delivery",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfirmDeliveryScreen(
                                jobId: jobId,
                                driverId: job['driverId'] ?? '',
                                deliveryPhotoUrl: job['deliveryPhotoUrl'],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                const SizedBox(height: 24),
                PrimaryButton(
                  text: "Report a Problem",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportDisputeScreen(jobId: jobId),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoText(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.white),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value?.toString() ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _highlightText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.yellow),
      ),
    );
  }
}

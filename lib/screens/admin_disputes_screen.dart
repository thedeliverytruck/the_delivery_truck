import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  Future<List<Map<String, dynamic>>> _getDisputes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('disputes')
        .where('status', isNotEqualTo: 'archived')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
  }

  Future<Map<String, dynamic>?> _getJob(String jobId) async {
    final doc = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> _updateDisputeStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('disputes').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Dispute marked as $status.")),
    );
    setState(() {});
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat.yMd().add_jm().format(timestamp.toDate());
  }

  void _showJobDetailsDialog(Map<String, dynamic> dispute, Map<String, dynamic> jobData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Job Details"),
        backgroundColor: Colors.grey[900],
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pickup Location: ${jobData['pickupAddress'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text("Drop-off Location: ${jobData['dropoffAddress'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              if (jobData['pickupPhotoUrl'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Pickup Photo:", style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 6),
                    Image.network(jobData['pickupPhotoUrl'], height: 120),
                  ],
                ),
              const SizedBox(height: 12),
              if (jobData['deliveryPhotoUrl'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Delivery Photo:", style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 6),
                    Image.network(jobData['deliveryPhotoUrl'], height: 120),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.yellow)),
          ),
        ],
      ),
    );
  }

  void _showDisputeActionsDialog(Map<String, dynamic> dispute) async {
    final jobId = dispute['jobId'];
    final jobData = await _getJob(jobId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Dispute Actions"),
        backgroundColor: Colors.grey[900],
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        content: jobData == null
            ? const Text("Job data not found.", style: TextStyle(color: Colors.white))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dispute['photoUrl'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Dispute Photo:", style: TextStyle(color: Colors.white)),
                          const SizedBox(height: 6),
                          Image.network(dispute['photoUrl'], height: 100),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _updateDisputeStatus(dispute['id'], 'resolved'),
                      icon: const Icon(Icons.check),
                      label: const Text("Mark Resolved"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text("Reassign Driver (Placeholder)"),
                            content: const Text("This will open reassignment flow."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c), child: const Text("Close"))
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text("Reassign Driver"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final jobRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);
                        final driverId = jobData['driverId'];
                        await jobRef.update({'status': 'refunded'});
                        if (driverId != null) {
                          await FirebaseFirestore.instance.collection('drivers').doc(driverId).update({
                            'active': false,
                          });
                        }
                        await _updateDisputeStatus(dispute['id'], 'resolved');
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text("Refund & Deactivate"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _showJobDetailsDialog(dispute, jobData),
                      child: const Text("View Job Details", style: TextStyle(color: Colors.yellow)),
                    ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.yellow)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: "Reported Disputes"),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getDisputes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }

          final disputes = snapshot.data!;
          if (disputes.isEmpty) {
            return const Center(
              child: Text("No active disputes.", style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            itemCount: disputes.length,
            itemBuilder: (context, index) {
              final d = disputes[index];

              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    "Job ID: ${d['jobId']}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Role: ${d['role']}", style: const TextStyle(color: Colors.white70)),
                      Text("Reason: ${d['reason']}", style: const TextStyle(color: Colors.orangeAccent)),
                      Text("Message: ${d['message']}", style: const TextStyle(color: Colors.white70)),
                      Text("Submitted: ${_formatDate(d['createdAt'])}", style: const TextStyle(color: Colors.white38)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.yellow),
                    tooltip: "Manage Dispute",
                    onPressed: () => _showDisputeActionsDialog(d),
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

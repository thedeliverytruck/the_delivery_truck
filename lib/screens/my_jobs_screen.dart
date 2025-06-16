import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'job_summary_screen.dart';
import 'edit_job_screen.dart';
import '../widgets/custom_app_bar.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _getUserJobs() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('jobs')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'My Jobs',
        showBackButton: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getUserJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data?.docs ?? [];

          if (jobs.isEmpty) {
            return const Center(
              child: Text(
                "No jobs submitted yet.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: jobs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final job = jobs[index].data();
              final jobId = jobs[index].id;

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: job['itemPhotoUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            job['itemPhotoUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.local_shipping, size: 40, color: Colors.white),
                  title: Text(
                    job['itemDescription'] ?? 'No description',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    "Status: ${job['status'] ?? 'pending'}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: (job['status'] == 'pending')
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.yellow),
                              tooltip: 'Edit Job',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditJobScreen(
                                      jobId: jobId,
                                      jobData: job,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Cancel Job',
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Cancel Job?"),
                                    content: const Text("Are you sure you want to cancel this job?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text("No"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text("Yes"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  await FirebaseFirestore.instance
                                      .collection('jobs')
                                      .doc(jobId)
                                      .delete();
                                }
                              },
                            ),
                          ],
                        )
                      : const Icon(Icons.check_circle, color: Colors.green),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobSummaryScreen(jobId: jobId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

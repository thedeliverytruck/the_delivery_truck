import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  Future<List<Map<String, dynamic>>> _getCompletedJobs() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'delivered')
        .orderBy('deliveredAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final price = (data['estimatedPrice'] ?? 0).toDouble();
      final tip = (data['tip'] ?? 0).toDouble();
      final date = data['deliveredAt'] != null
          ? (data['deliveredAt'] as Timestamp).toDate()
          : DateTime.now();

      return {
        'id': doc.id,
        'price': price,
        'tip': tip,
        'earned': price - 5 + tip, // $5 service fee retained by app
        'date': date,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Earnings Dashboard'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getCompletedJobs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.yellow));
          }

          final jobs = snapshot.data!;
          double totalEarnings = 0;
          double totalTips = 0;

          for (var job in jobs) {
            totalEarnings += job['earned'];
            totalTips += job['tip'];
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blueGrey[900],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text("Total Earned", style: TextStyle(fontSize: 16, color: Colors.yellow)),
                        const SizedBox(height: 4),
                        Text("\$${totalEarnings.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text("Total Tips", style: TextStyle(fontSize: 16, color: Colors.yellow)),
                        const SizedBox(height: 4),
                        Text("\$${totalTips.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ListTile(
                        title: Text(
                          "Job ID: ${job['id']}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Delivered: ${DateFormat.yMMMd().format(job['date'])}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Earned: \$${job['earned'].toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Tip: \$${job['tip'].toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';
import 'admin_disputes_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> jobs = [];
  String statusFilter = 'All';
  String searchQuery = '';
  double totalRevenue = 0;
  double totalTips = 0;
  double totalNet = 0;

  final statusOptions = ['All', 'pending', 'accepted', 'en_route', 'picked_up', 'delivered'];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    Query query = FirebaseFirestore.instance.collection('jobs');

    if (statusFilter != 'All') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    final snapshot = await query.orderBy('createdAt', descending: true).get();

    List<Map<String, dynamic>> fetchedJobs = [];

    double revenue = 0;
    double tips = 0;
    double net = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data is! Map<String, dynamic>) continue;

      final estimated = (data['estimatedPrice'] ?? 0).toDouble();
      final tip = (data['tip'] ?? 0).toDouble();
      const serviceFee = 5.0;

      final itemDescription = (data['itemDescription'] ?? '').toString().toLowerCase();
      final userEmail = (data['userEmail'] ?? '').toString().toLowerCase();

      if (searchQuery.isEmpty ||
          itemDescription.contains(searchQuery) ||
          userEmail.contains(searchQuery)) {
        revenue += estimated;
        tips += tip;
        net += (estimated - serviceFee + tip);

        fetchedJobs.add({
          'id': doc.id,
          ...data,
        });
      }
    }

    setState(() {
      jobs = fetchedJobs;
      totalRevenue = revenue;
      totalTips = tips;
      totalNet = net;
    });
  }

  Future<void> _deleteJob(String jobId) async {
    await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job deleted.")));
    _fetchJobs();
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    return DateFormat.yMd().add_jm().format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: "Admin Dashboard"),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueGrey[900],
            child: Column(
              children: [
                Row(
                  children: [
                    const Text("Status: ", style: TextStyle(color: Colors.white)),
                    DropdownButton<String>(
                      value: statusFilter,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      items: statusOptions
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          statusFilter = value!;
                        });
                        _fetchJobs();
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                          _fetchJobs();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by item or email',
                          hintStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.grey[800],
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [
                      const Text("Total Revenue", style: TextStyle(color: Colors.grey)),
                      Text("\$${totalRevenue.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                    ]),
                    Column(children: [
                      const Text("Tips", style: TextStyle(color: Colors.grey)),
                      Text("\$${totalTips.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    ]),
                    Column(children: [
                      const Text("Net Payout", style: TextStyle(color: Colors.grey)),
                      Text("\$${totalNet.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            icon: const Icon(Icons.report),
            label: const Text("View Disputes"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDisputesScreen()),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[800]),
            icon: const Icon(Icons.map),
            label: const Text("Driver Location Debug"),
            onPressed: () {
              Navigator.pushNamed(context, '/admin_driver_debug');
            },
          ),
          const Divider(height: 0),
          Expanded(
            child: jobs.isEmpty
                ? const Center(
                    child: Text("No jobs match your filters.",
                        style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return Card(
                        color: Colors.grey[850],
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text("Job: ${job['itemDescription'] ?? 'No Description'}",
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("User: ${job['userEmail'] ?? 'N/A'}",
                                  style: const TextStyle(color: Colors.white70)),
                              Text("Pickup: ${job['pickupAddress'] ?? 'N/A'}",
                                  style: const TextStyle(color: Colors.white70)),
                              Text("Dropoff: ${job['dropoffAddress'] ?? 'N/A'}",
                                  style: const TextStyle(color: Colors.white70)),
                              Text("Status: ${job['status'] ?? 'pending'}",
                                  style: const TextStyle(color: Colors.amber)),
                              Text("Created: ${_formatDate(job['createdAt'])}",
                                  style: const TextStyle(color: Colors.white38)),
                            ],
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("Total: \$${(job['estimatedPrice'] ?? 0).toStringAsFixed(2)}",
                                  style: const TextStyle(color: Colors.greenAccent)),
                              Text("Tip: \$${(job['tip'] ?? 0).toStringAsFixed(2)}",
                                  style: const TextStyle(color: Colors.blueAccent)),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () => _deleteJob(job['id']),
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
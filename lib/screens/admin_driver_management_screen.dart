import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class AdminDriverManagementScreen extends StatefulWidget {
  const AdminDriverManagementScreen({super.key});

  @override
  State<AdminDriverManagementScreen> createState() => _AdminDriverManagementScreenState();
}

class _AdminDriverManagementScreenState extends State<AdminDriverManagementScreen> {
  String filter = 'all'; // all, inactive, warned

  Future<void> _toggleDriverStatus(String driverId, bool isActive) async {
    final action = isActive ? "Deactivate" : "Reactivate";
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$action Driver?'),
        content: Text('Are you sure you want to $action this driver?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('drivers').doc(driverId).update({'isActive': !isActive});
    }
  }

  Future<void> _warnDriver(String driverId) async {
    final snapshot = await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
    final warnings = (snapshot.data()?['warnings'] ?? 0) + 1;

    await FirebaseFirestore.instance.collection('drivers').doc(driverId).update({'warnings': warnings});
  }

  Stream<QuerySnapshot> _filteredDriversStream() {
    final base = FirebaseFirestore.instance.collection('drivers');

    switch (filter) {
      case 'inactive':
        return base.where('isActive', isEqualTo: false).snapshots();
      case 'warned':
        return base.where('warnings', isGreaterThan: 0).snapshots();
      default:
        return base.snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Driver Management"),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filter == 'all',
                  onSelected: (_) => setState(() => filter = 'all'),
                ),
                FilterChip(
                  label: const Text('Inactive'),
                  selected: filter == 'inactive',
                  onSelected: (_) => setState(() => filter = 'inactive'),
                ),
                FilterChip(
                  label: const Text('Warned'),
                  selected: filter == 'warned',
                  onSelected: (_) => setState(() => filter = 'warned'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filteredDriversStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final drivers = snapshot.data!.docs;

                if (drivers.isEmpty) {
                  return const Center(child: Text('No drivers found.', style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final data = drivers[index].data() as Map<String, dynamic>;
                    final driverId = drivers[index].id;
                    final name = "${data['firstName'] ?? 'Unnamed'} ${data['lastName'] ?? ''}";
                    final isActive = data['isActive'] ?? true;
                    final warnings = data['warnings'] ?? 0;

                    return Card(
                      color: isActive ? Colors.grey[900] : Colors.red[900],
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(name, style: const TextStyle(color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email: ${data['email'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
                            Text("Status: ${isActive ? 'Active' : 'Inactive'}",
                                style: TextStyle(color: isActive ? Colors.green : Colors.red)),
                            Text("Warnings: $warnings", style: const TextStyle(color: Colors.orange)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (_) => _toggleDriverStatus(driverId, isActive),
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                            ),
                            IconButton(
                              icon: const Icon(Icons.warning, color: Colors.yellow),
                              tooltip: 'Issue Warning',
                              onPressed: () => _warnDriver(driverId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

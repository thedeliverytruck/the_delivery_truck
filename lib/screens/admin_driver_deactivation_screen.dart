import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class AdminDriverDeactivationScreen extends StatefulWidget {
  const AdminDriverDeactivationScreen({super.key});

  @override
  State<AdminDriverDeactivationScreen> createState() => _AdminDriverDeactivationScreenState();
}

class _AdminDriverDeactivationScreenState extends State<AdminDriverDeactivationScreen> {
  List<DocumentSnapshot> drivers = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final snapshot = await FirebaseFirestore.instance.collection('drivers').get();
    setState(() {
      drivers = snapshot.docs;
    });
  }

  Future<void> _deactivateDriver(String driverId) async {
    await FirebaseFirestore.instance.collection('drivers').doc(driverId).update({
      'isActive': false,
      'deactivatedByAdmin': true,
      'deactivatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Driver deactivated successfully')),
    );

    _loadDrivers();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDrivers = drivers.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['firstName'] ?? '';
      return name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Driver Deactivation', showHome: true, showDriverHome: true, showUserHome: true),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Search by First Name',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredDrivers.length,
                itemBuilder: (context, index) {
                  final data = filteredDrivers[index].data() as Map<String, dynamic>;
                  final driverId = filteredDrivers[index].id;
                  final name = "${data['firstName']} ${data['lastName'] ?? ''}";
                  final isActive = data['isActive'] ?? true;

                  return Card(
                    color: isActive ? Colors.grey[850] : Colors.red[900],
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(driverId, style: const TextStyle(color: Colors.white70)),
                      trailing: isActive
                          ? ElevatedButton(
                              onPressed: () => _deactivateDriver(driverId),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Deactivate'),
                            )
                          : const Text("Inactive", style: TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDriverLocationDebugScreen extends StatefulWidget {
  const AdminDriverLocationDebugScreen({super.key});

  @override
  State<AdminDriverLocationDebugScreen> createState() => _AdminDriverLocationDebugScreenState();
}

class _AdminDriverLocationDebugScreenState extends State<AdminDriverLocationDebugScreen> {
  String? selectedDriverId;
  List<String> driverIds = [];
  List<Map<String, dynamic>> locationLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchDriverIds();
  }

  Future<void> _fetchDriverIds() async {
    final snapshot = await FirebaseFirestore.instance.collection('drivers').get();
    setState(() {
      driverIds = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _loadLogs(String driverId) async {
    final logsSnapshot = await FirebaseFirestore.instance
        .collection('driver_location_logs')
        .where('driverId', isEqualTo: driverId)
        .orderBy('loggedAt', descending: true)
        .limit(50)
        .get();

    setState(() {
      locationLogs = logsSnapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  void _launchMaps(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Location Debug'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: selectedDriverId,
              hint: const Text('Select a Driver'),
              items: driverIds
                  .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDriverId = value;
                });
                if (value != null) {
                  _loadLogs(value);
                }
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: locationLogs.isEmpty
                  ? const Center(child: Text('No logs found.'))
                  : ListView.builder(
                      itemCount: locationLogs.length,
                      itemBuilder: (context, index) {
                        final log = locationLogs[index];
                        final lat = log['latitude']?.toStringAsFixed(5);
                        final lng = log['longitude']?.toStringAsFixed(5);
                        final speed = log['speed']?.toStringAsFixed(1);
                        final time = log['loggedAt'] != null
                            ? (log['loggedAt'] as Timestamp).toDate().toLocal().toString()
                            : 'No timestamp';

                        return ListTile(
                          title: Text('📍 $lat, $lng'),
                          subtitle: Text('Speed: $speed m/s\n$time'),
                          onTap: () {
                            _launchMaps(log['latitude'], log['longitude']);
                          },
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

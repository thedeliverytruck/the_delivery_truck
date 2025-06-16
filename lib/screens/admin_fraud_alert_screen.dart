import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';

class AdminFraudAlertScreen extends StatefulWidget {
  const AdminFraudAlertScreen({super.key});

  @override
  State<AdminFraudAlertScreen> createState() => _AdminFraudAlertScreenState();
}

class _AdminFraudAlertScreenState extends State<AdminFraudAlertScreen> {
  List<Map<String, dynamic>> alerts = [];

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('fraud_alerts')
        .orderBy('count', descending: true)
        .get();

    setState(() {
      alerts = snapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList();
    });
  }

  Future<void> _markResolved(String alertId) async {
    await FirebaseFirestore.instance
        .collection('fraud_alerts')
        .doc(alertId)
        .update({'resolved': true});
    _fetchAlerts();
  }

  String _formatTimestamp(Timestamp ts) {
    return DateFormat('MM/dd/yyyy hh:mm:ss a').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Fraud Alerts'),
      backgroundColor: Colors.black,
      body: alerts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      '${alert['type']} (x${alert['count']})',
                      style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Driver ID: ${alert['driverId']}', style: const TextStyle(color: Colors.white70)),
                        Text('Job ID: ${alert['jobId']}', style: const TextStyle(color: Colors.white70)),
                        Text('Time: ${_formatTimestamp(alert['timestamp'])}', style: const TextStyle(color: Colors.white54)),
                        if (alert['resolved'] == true)
                          const Text('Status: Resolved ✅', style: TextStyle(color: Colors.greenAccent))
                        else
                          TextButton(
                            onPressed: () => _markResolved(alert['id']),
                            child: const Text('Mark Resolved', style: TextStyle(color: Colors.cyan)),
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

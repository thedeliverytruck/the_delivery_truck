import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsDashboardScreen extends StatefulWidget {
  const AdminAnalyticsDashboardScreen({super.key});

  @override
  State<AdminAnalyticsDashboardScreen> createState() =>
      _AdminAnalyticsDashboardScreenState();
}

class _AdminAnalyticsDashboardScreenState
    extends State<AdminAnalyticsDashboardScreen> {
  Map<String, int> jobsPerDriver = {};
  Map<String, int> jobsPerDay = {};
  double totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    final jobsSnapshot =
        await FirebaseFirestore.instance.collection('jobs').get();

    Map<String, int> driverCount = {};
    Map<String, int> dayCount = {};
    double revenue = 0;

    for (var doc in jobsSnapshot.docs) {
      final data = doc.data();
      final driverId = data['driverId'] ?? 'Unassigned';
      final timestamp = data['timestamp'];
      final amount = (data['price'] ?? 0).toDouble();

      if (driverId != 'Unassigned') {
        driverCount[driverId] = (driverCount[driverId] ?? 0) + 1;
      }

      if (timestamp != null) {
        final date = (timestamp as Timestamp).toDate();
        final day = DateFormat('EEEE').format(date);
        dayCount[day] = (dayCount[day] ?? 0) + 1;
      }

      revenue += amount;
    }

    setState(() {
      jobsPerDriver = driverCount;
      jobsPerDay = dayCount;
      totalRevenue = revenue;
    });
  }

  List<Widget> _buildDriverLeaderboard() {
    final sortedDrivers = jobsPerDriver.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedDrivers
        .take(5)
        .map(
          (entry) => ListTile(
            title: Text(
              entry.key,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: Text(
              '${entry.value} jobs',
              style: const TextStyle(color: Colors.greenAccent),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildBusiestDaysChart() {
    final sortedDays = jobsPerDay.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedDays
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(entry.key,
                      style: const TextStyle(color: Colors.white70)),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: entry.value / (jobsPerDay.values.reduce((a, b) => a > b ? a : b)),
                    backgroundColor: Colors.grey,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${entry.value}',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Admin Analytics'),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              '📊 Top Drivers',
              style: TextStyle(color: Colors.yellow, fontSize: 18),
            ),
            const SizedBox(height: 8),
            ..._buildDriverLeaderboard(),
            const Divider(color: Colors.white54),
            const Text(
              '📅 Busiest Days of the Week',
              style: TextStyle(color: Colors.yellow, fontSize: 18),
            ),
            const SizedBox(height: 8),
            ..._buildBusiestDaysChart(),
            const Divider(color: Colors.white54),
            Text(
              '💰 Total Revenue: \$${totalRevenue.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.cyan, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

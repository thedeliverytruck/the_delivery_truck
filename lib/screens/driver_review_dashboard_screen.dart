// lib/screens/driver_review_dashboard_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DriverReviewDashboardScreen extends StatefulWidget {
  const DriverReviewDashboardScreen({super.key});

  @override
  State<DriverReviewDashboardScreen> createState() =>
      _DriverReviewDashboardScreenState();
}

class _DriverReviewDashboardScreenState
    extends State<DriverReviewDashboardScreen> {
  double averageRating = 0.0;
  Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  List<Map<String, dynamic>> reviews = [];
  String? profileImageUrl;
  String sortOrder = 'Newest';

  @override
  void initState() {
    super.initState();
    _loadDriverReviews();
  }

  Future<void> _loadDriverReviews() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('driverId', isEqualTo: uid)
        .get();

    double total = 0;
    Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    List<Map<String, dynamic>> loadedReviews = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rating = (data['rating'] ?? 5).round();
      counts[rating] = (counts[rating] ?? 0) + 1;
      total += rating;
      loadedReviews.add(data);
    }

    final driverDoc =
        await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
    final profileUrl = driverDoc.data()?['photoUrl'];

    setState(() {
      reviews = loadedReviews;
      ratingCounts = counts;
      averageRating =
          snapshot.docs.isEmpty ? 0 : total / snapshot.docs.length;
      profileImageUrl = profileUrl;
    });
  }

  List<charts.Series<RatingCount, String>> _buildChartData() {
    final data = ratingCounts.entries
        .map((e) => RatingCount('${e.key}★', e.value))
        .toList()
      ..sort((a, b) => b.stars.compareTo(a.stars));

    return [
      charts.Series<RatingCount, String>(
        id: 'Ratings',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (RatingCount count, _) => count.label,
        measureFn: (RatingCount count, _) => count.count,
        data: data,
      ),
    ];
  }

  Future<void> _exportCSV() async {
    final List<List<dynamic>> csvData = [
      ['Rating', 'Comment', 'Timestamp'],
      ...reviews.map((r) => [
            r['rating'] ?? '',
            r['comment'] ?? '',
            r['timestamp'] != null
                ? DateFormat.yMd()
                    .add_jm()
                    .format((r['timestamp'] as Timestamp).toDate())
                : '',
          ]),
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/driver_reviews.csv';
    final file = File(path);
    await file.writeAsString(csv);
    Share.shareXFiles([XFile(path)], text: 'My driver reviews (CSV export)');
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    final tableData = [
      ['Rating', 'Comment', 'Timestamp'],
      ...reviews.map((r) => [
            r['rating']?.toString() ?? '',
            r['comment'] ?? '',
            r['timestamp'] != null
                ? DateFormat.yMd()
                    .add_jm()
                    .format((r['timestamp'] as Timestamp).toDate())
                : '',
          ]),
    ];

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Table.fromTextArray(data: tableData),
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/driver_reviews.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    Share.shareXFiles([XFile(path)], text: 'My driver reviews (PDF export)');
  }

  List<Map<String, dynamic>> get sortedReviews {
    final sorted = [...reviews];
    if (sortOrder == 'Newest') {
      sorted.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
    } else if (sortOrder == 'Oldest') {
      sorted.sort((a, b) =>
          (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));
    } else if (sortOrder == 'Highest') {
      sorted.sort(
          (b, a) => (a['rating'] as int).compareTo(b['rating'] as int));
    } else if (sortOrder == 'Lowest') {
      sorted.sort(
          (a, b) => (a['rating'] as int).compareTo(b['rating'] as int));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Your Driver Reviews"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf), onPressed: _exportPDF),
          IconButton(
              icon: const Icon(Icons.table_view), onPressed: _exportCSV),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profileImageUrl != null)
              Center(
                  child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(profileImageUrl!))),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 36,
                          fontWeight: FontWeight.bold)),
                  RatingBarIndicator(
                    rating: averageRating,
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 28,
                  ),
                  const SizedBox(height: 8),
                  Text("${reviews.length} total review(s)",
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: charts.BarChart(
                _buildChartData(),
                animate: true,
                vertical: false,
                domainAxis: const charts.OrdinalAxisSpec(
                    renderSpec: charts.NoneRenderSpec()),
                primaryMeasureAxis: charts.NumericAxisSpec(
                  renderSpec: charts.GridlineRendererSpec(
                    labelStyle: charts.TextStyleSpec(
                        color: charts.MaterialPalette.white),
                    lineStyle: charts.LineStyleSpec(
                      color: charts.MaterialPalette.gray.shadeDefault,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (averageRating >= 4.5)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.green.shade800,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.yellow),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "You're eligible for referral bonuses thanks to your top ratings!",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/rewards'),
                      child: const Text("Rewards"),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recent Reviews",
                    style: TextStyle(color: Colors.white, fontSize: 20)),
                DropdownButton<String>(
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  value: sortOrder,
                  items: ['Newest', 'Oldest', 'Highest', 'Lowest']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => sortOrder = value ?? 'Newest'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sortedReviews.map((r) {
              final timestamp = r['timestamp'] != null
                  ? DateFormat.yMd()
                      .add_jm()
                      .format((r['timestamp'] as Timestamp).toDate())
                  : 'No date';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RatingBarIndicator(
                        rating: (r['rating'] ?? 5).toDouble(),
                        itemBuilder: (context, _) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 20,
                      ),
                      const SizedBox(height: 6),
                      Text(r['comment'] ?? 'No comment provided.',
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(timestamp,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ]),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class RatingCount {
  final String label;
  final int count;

  RatingCount(this.label, this.count);

  int get stars => int.tryParse(label[0]) ?? 0;
}

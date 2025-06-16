import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:screenshot/screenshot.dart';
import '../widgets/custom_app_bar.dart';

class AdminDriverLocationLogScreen extends StatefulWidget {
  const AdminDriverLocationLogScreen({super.key});

  @override
  State<AdminDriverLocationLogScreen> createState() => _AdminDriverLocationLogScreenState();
}

class _AdminDriverLocationLogScreenState extends State<AdminDriverLocationLogScreen> with TickerProviderStateMixin {
  String? selectedDriverId;
  String? selectedJobId;
  List<String> driverIds = [];
  List<Map<String, dynamic>> logs = [];
  DateTime? startDate;
  DateTime? endDate;
  GoogleMapController? mapController;
  ScreenshotController screenshotController = ScreenshotController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchDriverIds();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _fetchDriverIds() async {
    final snapshot = await FirebaseFirestore.instance.collection('drivers').get();
    setState(() {
      driverIds = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _fetchLogs() async {
    if (selectedDriverId == null) return;

    Query query = FirebaseFirestore.instance
        .collection('logs')
        .doc('driver_location_updates')
        .collection(selectedDriverId!)
        .orderBy('timestamp', descending: true);

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate!));
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate!));
    }

    final snapshot = await query.get();
    List<Map<String, dynamic>> rawLogs = snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    if (selectedJobId != null && selectedJobId!.isNotEmpty) {
      rawLogs = rawLogs.where((log) => log['jobId'] == selectedJobId).toList();
    }

    setState(() {
      logs = rawLogs;
    });
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'N/A';
    final dt = ts.toDate();
    return DateFormat('MM/dd/yyyy hh:mm:ss a').format(dt);
  }

  Set<Marker> _buildMarkers() {
    return logs.asMap().entries.map((entry) {
      final log = entry.value;
      final index = entry.key;
      return Marker(
        markerId: MarkerId('log_$index'),
        position: LatLng(log['latitude'], log['longitude']),
        infoWindow: InfoWindow(
          title: 'Log $index',
          snippet: _formatTimestamp(log['timestamp']),
        ),
      );
    }).toSet();
  }

  Future<void> _exportCSV() async {
    final List<List<dynamic>> csvData = [
      ['Job ID', 'Latitude', 'Longitude', 'Speed', 'Accuracy', 'Timestamp'],
      ...logs.map((log) => [
            log['jobId'] ?? '',
            log['latitude'],
            log['longitude'],
            log['speed'],
            log['accuracy'],
            _formatTimestamp(log['timestamp']),
          ]),
    ];

    final String csv = const ListToCsvConverter().convert(csvData);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/driver_logs_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    Share.shareXFiles([XFile(path)], text: 'Driver location logs export');
  }

  Future<void> _exportPDFWithScreenshot() async {
    final image = await screenshotController.capture();
    if (image == null) return;

    final pdf = pw.Document();
    final screenshotImage = pw.MemoryImage(image);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Driver Location Log', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Image(screenshotImage),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Job ID', 'Lat', 'Lng', 'Speed', 'Accuracy', 'Timestamp'],
                data: logs.map((log) => [
                  log['jobId'] ?? '',
                  log['latitude'],
                  log['longitude'],
                  log['speed'],
                  log['accuracy'],
                  _formatTimestamp(log['timestamp']),
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/driver_logs_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    Share.shareXFiles([XFile(path)], text: 'Driver location logs PDF');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Driver Location Logs"),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Driver',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  value: selectedDriverId,
                  items: driverIds
                      .map((id) => DropdownMenuItem(
                            value: id,
                            child: Text(id, style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDriverId = value;
                    });
                    _fetchLogs();
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Filter by Job ID',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    setState(() => selectedJobId = value.trim());
                    _fetchLogs();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(const Duration(days: 1)),
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => startDate = picked);
                            _fetchLogs();
                          }
                        },
                        child: Text(
                          startDate != null ? 'Start: ${DateFormat.yMd().format(startDate!)}' : 'Pick Start Date',
                          style: const TextStyle(color: Colors.yellow),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => endDate = picked.add(const Duration(hours: 23, minutes: 59)));
                            _fetchLogs();
                          }
                        },
                        child: Text(
                          endDate != null ? 'End: ${DateFormat.yMd().format(endDate!)}' : 'Pick End Date',
                          style: const TextStyle(color: Colors.yellow),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.cyan),
                      onPressed: logs.isEmpty ? null : _exportCSV,
                      tooltip: 'Export as CSV',
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.orangeAccent),
                      onPressed: logs.isEmpty ? null : _exportPDFWithScreenshot,
                      tooltip: 'Export as PDF',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          TabBar(
            controller: _tabController,
            labelColor: Colors.yellow,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'Logs'),
              Tab(icon: Icon(Icons.map), text: 'Map'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                logs.isEmpty
                    ? const Center(child: Text("No logs available.", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return Card(
                            color: Colors.grey[850],
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(
                                "Lat: ${log['latitude']?.toStringAsFixed(5)}, Lng: ${log['longitude']?.toStringAsFixed(5)}",
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Job ID: ${log['jobId'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
                                  Text("Speed: ${log['speed'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
                                  Text("Accuracy: ${log['accuracy'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
                                  Text("Timestamp: ${_formatTimestamp(log['timestamp'])}",
                                      style: const TextStyle(color: Colors.white38)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                Screenshot(
                  controller: screenshotController,
                  child: logs.isEmpty
                      ? const Center(child: Text("No map data.", style: TextStyle(color: Colors.white54)))
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(logs.first['latitude'], logs.first['longitude']),
                            zoom: 13,
                          ),
                          markers: _buildMarkers(),
                          onMapCreated: (controller) => mapController = controller,
                          myLocationButtonEnabled: false,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

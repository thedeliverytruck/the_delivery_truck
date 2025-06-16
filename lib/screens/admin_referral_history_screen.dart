import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class AdminReferralHistoryScreen extends StatefulWidget {
  const AdminReferralHistoryScreen({super.key});

  @override
  State<AdminReferralHistoryScreen> createState() => _AdminReferralHistoryScreenState();
}

class _AdminReferralHistoryScreenState extends State<AdminReferralHistoryScreen> {
  List<DocumentSnapshot> referrals = [];
  List<DocumentSnapshot> filteredReferrals = [];
  String filterReferrer = '';
  String filterType = 'All';
  DateTime? filterDate;

  final List<String> typeOptions = ['All', 'PRO_SUBSCRIPTION', 'DELIVERY_REQUEST'];

  @override
  void initState() {
    super.initState();
    _loadReferralHistory();
  }

  Future<void> _loadReferralHistory() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('referralHistory')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      referrals = snapshot.docs;
      filteredReferrals = referrals;
    });
  }

  void _applyFilters() {
    setState(() {
      filteredReferrals = referrals.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final referrerMatch = filterReferrer.isEmpty || (data['referrerId']?.toLowerCase() ?? '').contains(filterReferrer.toLowerCase());
        final typeMatch = filterType == 'All' || data['type'] == filterType;
        final dateMatch = filterDate == null || DateTime.tryParse(data['timestamp'])?.day == filterDate?.day;

        return referrerMatch && typeMatch && dateMatch;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      filterReferrer = '';
      filterType = 'All';
      filterDate = null;
      filteredReferrals = referrals;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Referral History", showHome: true, showDriverHome: true, showUserHome: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Filter by Referrer ID',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      filterReferrer = value;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: filterType,
                  dropdownColor: Colors.black,
                  iconEnabledColor: Colors.white,
                  items: typeOptions.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    filterType = value!;
                    _applyFilters();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      filterDate = pickedDate;
                      _applyFilters();
                    }
                  },
                  child: const Text("Filter by Date"),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text("Clear Filters", style: TextStyle(color: Colors.yellow)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredReferrals.length,
                itemBuilder: (context, index) {
                  final data = filteredReferrals[index].data() as Map<String, dynamic>;
                  final timestamp = DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now();
                  return Card(
                    color: Colors.grey[850],
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text("Referrer: ${data['referrerId']}", style: const TextStyle(color: Colors.white)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Referred: ${data['referredUserId']}", style: const TextStyle(color: Colors.white70)),
                          Text("Type: ${data['type']}", style: const TextStyle(color: Colors.white70)),
                          Text("Notes: ${data['notes'] ?? ''}", style: const TextStyle(color: Colors.white70)),
                          Text("Created By: ${data['createdBy']}", style: const TextStyle(color: Colors.white70)),
                          Text("Time: ${timestamp.toLocal()}", style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
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

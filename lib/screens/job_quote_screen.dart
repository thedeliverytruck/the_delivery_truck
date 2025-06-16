import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class JobQuoteScreen extends StatelessWidget {
  final String jobId;

  const JobQuoteScreen({super.key, required this.jobId});

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchJob() async {
    return FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
  }

  double _calculateEstimatedPrice(Map<String, dynamic> job) {
    const baseRate = 20.0;
    const perMileRate = 2.0;
    const deliveryTypeRate = {
      'Curbside': 0.0,
      'Inside 1st Floor': 15.0,
      'Inside 2nd Floor': 30.0,
    };

    final deliveryType = job['deliveryType'] ?? 'Curbside';
    final miles = job['estimatedDistanceMiles'] ?? 5;
    return baseRate + (miles * perMileRate) + (deliveryTypeRate[deliveryType] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Job Quote'),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _fetchJob(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.yellow));
          }

          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text("Job not found.", style: TextStyle(color: Colors.white)));
          }

          final job = snapshot.data!.data()!;
          final estimatedPrice = _calculateEstimatedPrice(job);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (job['imageUrl'] != null)
                  Center(
                    child: Image.network(
                      job['imageUrl'],
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 24),
                _infoText("Pickup", "${job['pickupLocationName']} - ${job['pickupAddress']}"),
                _infoText("Dropoff", "${job['dropoffLocationName']} - ${job['dropoffAddress']}"),
                _infoText("Item", job['description']),
                _infoText("Weight", "${job['weight']} lbs"),
                _infoText("Delivery Type", job['deliveryType'] ?? 'Curbside'),
                const SizedBox(height: 20),
                Text(
                  "Estimated Price: \$${estimatedPrice.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Accept Quote and Select Driver',
                  onPressed: () {
                    Navigator.pushNamed(context, '/select_driver', arguments: {'jobId': jobId});
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Cancel and Edit Job',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/edit_job', arguments: {'jobId': jobId});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.white),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

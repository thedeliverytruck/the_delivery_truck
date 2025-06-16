import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class UserDeliveryConfirmationScreen extends StatefulWidget {
  final String jobId;
  final String driverId;
  final String deliveryPhotoUrl; // ✅ Added

  const UserDeliveryConfirmationScreen({
    super.key,
    required this.jobId,
    required this.driverId,
    required this.deliveryPhotoUrl, // ✅ Added
  });

  @override
  State<UserDeliveryConfirmationScreen> createState() => _UserDeliveryConfirmationScreenState();
}

class _UserDeliveryConfirmationScreenState extends State<UserDeliveryConfirmationScreen> {
  double _rating = 5.0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);

    final review = {
      'rating': _rating,
      'feedback': _feedbackController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'jobId': widget.jobId,
      'userId': FirebaseFirestore.instance.collection('users').doc().id, // Replace with actual user ID logic
    };

    final driverRef = FirebaseFirestore.instance.collection('drivers').doc(widget.driverId);

    await driverRef.collection('reviews').add(review);

    await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
      'status': 'delivered_confirmed_by_user',
      'userRating': _rating,
      'userFeedback': _feedbackController.text.trim(),
      'deliveryConfirmedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you! Your review has been submitted.')),
    );

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Confirm Delivery'),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.deliveryPhotoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(widget.deliveryPhotoUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 24),
            const Text(
              "Rate your driver:",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 12),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemSize: 40,
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) => setState(() => _rating = rating),
            ),
            const SizedBox(height: 24),
            const Text(
              "Leave optional feedback:",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850],
                hintText: "How was your experience?",
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              text: _isSubmitting ? 'Submitting...' : 'Submit Confirmation',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitReview,
            ),
          ],
        ),
      ),
    );
  }
}

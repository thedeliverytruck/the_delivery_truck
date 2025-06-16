import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class ReviewScreen extends StatefulWidget {
  final String jobId;
  final String driverId;

  const ReviewScreen({super.key, required this.jobId, required this.driverId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);

    try {
      // Save review
      await FirebaseFirestore.instance.collection('reviews').doc(widget.jobId).set({
        'jobId': widget.jobId,
        'driverId': widget.driverId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update driver's average rating
      final reviewQuery = await FirebaseFirestore.instance
          .collection('reviews')
          .where('driverId', isEqualTo: widget.driverId)
          .get();

      final allRatings = reviewQuery.docs.map((doc) => doc['rating'] as double).toList();
      final avgRating = allRatings.isEmpty
          ? _rating
          : allRatings.reduce((a, b) => a + b) / allRatings.length;

      await FirebaseFirestore.instance.collection('drivers').doc(widget.driverId).update({
        'averageRating': avgRating,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thanks for your feedback!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: "Leave a Review"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rate your driver",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Center(
              child: RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 40,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) => _rating = rating,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Write a comment (optional)",
                labelStyle: TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: PrimaryButton(
                text: 'Submit Review',
                icon: Icons.send,
                isLoading: _isSubmitting,
                onPressed: _submitReview,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

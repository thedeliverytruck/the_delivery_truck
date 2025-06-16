import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import '../screens/delivery_confirmation_screen.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class ConfirmDeliveryScreen extends StatefulWidget {
  final String jobId;
  final String driverId;
  final String? deliveryPhotoUrl;

  const ConfirmDeliveryScreen({
    super.key,
    required this.jobId,
    required this.driverId,
    this.deliveryPhotoUrl,
  });

  @override
  State<ConfirmDeliveryScreen> createState() => _ConfirmDeliveryScreenState();
}

class _ConfirmDeliveryScreenState extends State<ConfirmDeliveryScreen> {
  final _tipController = TextEditingController();
  final _commentController = TextEditingController();
  double _rating = 5;
  bool _isSubmitting = false;

  late final ConfettiController _confettiController;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _audioPlayer = AudioPlayer();
  }

  Future<void> _awardReferralPoints(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final referrerId = userDoc.data()?['referredBy'];
    if (referrerId != null) {
      final refRef = FirebaseFirestore.instance.collection('referrals').doc(referrerId);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final s = await tx.get(refRef);
        final points = (s.data()?['points'] ?? 0) + 3;
        final list = s.exists ? List<String>.from(s.data()?['deliveries'] ?? []) : <String>[];
        if (!list.contains(widget.jobId)) {
          list.add(widget.jobId);
        }
        tx.set(refRef, {
          'uid': referrerId,
          'points': points,
          'deliveries': list,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // 🎉 Celebration animation and sound
      _audioPlayer.play(AssetSource('sounds/horn.mp3'));
      _confettiController.play();
    }
  }

  Future<void> _submitConfirmation() async {
    setState(() => _isSubmitting = true);
    try {
      final tip = double.tryParse(_tipController.text.trim()) ?? 0;

      // 1. Update job as user confirmed delivery
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'userConfirmedDelivery': true,
        'tip': tip,
        'status': 'delivered',
        'userConfirmedAt': FieldValue.serverTimestamp(),
      });

      // 2. Save review
      await FirebaseFirestore.instance.collection('reviews').doc(widget.jobId).set({
        'jobId': widget.jobId,
        'driverId': widget.driverId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      // 3. Update driver's average rating
      final reviews = await FirebaseFirestore.instance
          .collection('reviews')
          .where('driverId', isEqualTo: widget.driverId)
          .get();
      final ratings = reviews.docs.map((e) => (e['rating'] as num).toDouble()).toList();
      final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

      await FirebaseFirestore.instance.collection('drivers').doc(widget.driverId).update({
        'averageRating': avgRating,
      });

      // 4. Award referral points if applicable
      final jobSnapshot = await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
      final userId = jobSnapshot.data()?['userId'] as String?;
      final itemDescription = jobSnapshot.data()?['itemDescription'] ?? 'your item';

      if (userId != null) {
        await _awardReferralPoints(userId);
      }

      // 5. Navigate to confirmation screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryConfirmationScreen(
              itemDescription: itemDescription,
              deliveryPhotoUrl: widget.deliveryPhotoUrl,
              userReview: _commentController.text.trim().isEmpty
                  ? 'Great delivery!'
                  : _commentController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _tipController.dispose();
    _commentController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          appBar: const CustomAppBar(title: 'Confirm Delivery'),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                if (widget.deliveryPhotoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(widget.deliveryPhotoUrl!, height: 200, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 24),
                const Text(
                  "Leave a Tip (optional)",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tipController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "e.g. 10.00",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Rate Your Driver",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  itemCount: 5,
                  itemSize: 36,
                  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (r) => _rating = r,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Comment (optional)",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Write your feedback...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: "Confirm Delivery & Submit Review",
                  icon: Icons.check_circle,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submitConfirmation,
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.yellow, Colors.red, Colors.blue],
          ),
        ),
      ],
    );
  }
}

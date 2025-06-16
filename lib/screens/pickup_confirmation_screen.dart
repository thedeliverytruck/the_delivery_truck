import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class PickupConfirmationScreen extends StatefulWidget {
  final String jobId;
  final String userId;

  const PickupConfirmationScreen({super.key, required this.jobId, required this.userId});

  @override
  State<PickupConfirmationScreen> createState() => _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  bool isLoading = true;
  Map<String, dynamic>? jobData;
  String? error;
  File? pickupPhoto;
  String? userName;
  String? userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadJobAndUserData();
  }

  Future<void> _loadJobAndUserData() async {
    try {
      final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();

      if (!jobDoc.exists || !userDoc.exists) throw Exception("Data not found");

      setState(() {
        jobData = jobDoc.data();
        userName = userDoc['firstName'] + ' ' + (userDoc['lastName'] ?? '').substring(0, 1) + '.';
        userPhotoUrl = userDoc['profileImageUrl'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Failed to load job: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75);
    if (picked != null) {
      setState(() {
        pickupPhoto = File(picked.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('job_pickups')
        .child('${widget.jobId}_pickup.jpg');

    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> _confirmPickup() async {
    if (pickupPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a pickup photo.")),
      );
      return;
    }

    final url = await _uploadImage(pickupPhoto!);

    await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
      'status': 'in_transit',
      'pickupConfirmedAt': FieldValue.serverTimestamp(),
      'pickupPhotoUrl': url,
    });

    _showUserDisclaimerDialog();
  }

  void _showUserDisclaimerDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("User Liability Notice"),
        content: const Text(
          "The Delivery Truck is a platform connecting drivers and users. "
          "We are not liable for any damage, loss, or theft of packages. "
          "We strongly recommend that you follow your driver to the destination or confirm the condition upon arrival.",
        ),
        actions: [
          TextButton(
            child: const Text("I Understand and Accept"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/live_tracking', arguments: {
                'jobId': widget.jobId,
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: const CustomAppBar(title: 'Pickup Confirmation'),
        body: Center(child: Text(error!, style: const TextStyle(color: Colors.red))),
      );
    }

    final pickup = jobData!['pickupAddress'] ?? 'N/A';
    final instructions = jobData!['pickupInstructions'] ?? 'None provided';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Confirm Pickup'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (userPhotoUrl != null)
              CircleAvatar(backgroundImage: NetworkImage(userPhotoUrl!), radius: 40),
            const SizedBox(height: 12),
            Text(userName ?? '', style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 24),
            _buildInfoRow("Pickup Location", pickup),
            _buildInfoRow("Special Instructions", instructions),
            const SizedBox(height: 16),
            const Text("Upload Pickup Photo", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: pickupPhoto == null
                    ? const Icon(Icons.camera_alt, color: Colors.white54, size: 48)
                    : Image.file(pickupPhoto!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: "✅ Mark as Picked Up",
              onPressed: _confirmPickup,
              isLoading: false,
            ),
          ],
        ),
      ),
    );
  }
}

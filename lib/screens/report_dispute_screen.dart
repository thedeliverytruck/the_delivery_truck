import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class ReportDisputeScreen extends StatefulWidget {
  final String jobId;

  const ReportDisputeScreen({super.key, required this.jobId});

  @override
  State<ReportDisputeScreen> createState() => _ReportDisputeScreenState();
}

class _ReportDisputeScreenState extends State<ReportDisputeScreen> {
  final _messageController = TextEditingController();
  String? _selectedReason;
  File? _imageFile;
  Uint8List? _webImageBytes;
  bool _isSubmitting = false;

  final List<String> _reasons = [
    "Item damaged",
    "Item didn't arrive",
    "Driver late",
    "Inaccurate item description",
    "Unsafe delivery experience",
    "Other",
  ];

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() => _webImageBytes = bytes);
        } else {
          setState(() => _imageFile = File(pickedFile.path));
        }
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  Future<String?> _uploadImage(String disputeId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("dispute_photos/$disputeId.jpg");

      UploadTask uploadTask;
      if (kIsWeb && _webImageBytes != null) {
        uploadTask = ref.putData(_webImageBytes!);
      } else if (_imageFile != null) {
        uploadTask = ref.putFile(_imageFile!);
      } else {
        return null;
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Upload failed: $e");
      return null;
    }
  }

  Future<void> _submitDispute() async {
    final message = _messageController.text.trim();
    if (_selectedReason == null || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a reason and enter a message.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userId = user.uid;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final isDriver = !userDoc.exists;

      final disputeRef = FirebaseFirestore.instance.collection('disputes').doc();
      String? photoUrl;

      if (_imageFile != null || _webImageBytes != null) {
        photoUrl = await _uploadImage(disputeRef.id);
      }

      await disputeRef.set({
        'jobId': widget.jobId,
        'submittedBy': userId,
        'role': isDriver ? 'driver' : 'user',
        'reason': _selectedReason,
        'message': message,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dispute submitted successfully.")),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Dispute submit error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting dispute: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewWidget = _imageFile != null
        ? Image.file(_imageFile!, height: 200)
        : _webImageBytes != null
            ? Image.memory(_webImageBytes!, height: 200)
            : const Text("No image selected.", style: TextStyle(color: Colors.white54));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Report a Problem'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Text(
                "Select a reason for the dispute:",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                dropdownColor: Colors.black87,
                value: _selectedReason,
                items: _reasons
                    .map((reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(reason, style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedReason = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: "Select reason",
                  hintStyle: const TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _messageController,
                maxLines: 6,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Describe the issue",
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              previewWidget,
              const SizedBox(height: 8),
              PrimaryButton(
                text: "Upload Photo (optional)",
                icon: Icons.camera_alt,
                onPressed: _pickImage,
              ),
              const SizedBox(height: 20),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: "Submit Dispute",
                      icon: Icons.report_problem,
                      onPressed: _submitDispute,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

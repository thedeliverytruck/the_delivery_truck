import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class MarkDeliveredScreen extends StatefulWidget {
  final String jobId;

  const MarkDeliveredScreen({super.key, required this.jobId});

  @override
  State<MarkDeliveredScreen> createState() => _MarkDeliveredScreenState();
}

class _MarkDeliveredScreenState extends State<MarkDeliveredScreen> {
  File? _imageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  Map<String, dynamic>? _jobData;

  @override
  void initState() {
    super.initState();
    _loadJobInfo();
  }

  Future<void> _loadJobInfo() async {
    final doc = await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
    if (doc.exists) {
      setState(() {
        _jobData = doc.data();
      });
    }
  }

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
      debugPrint('Image pick error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Future<void> _submitDelivery() async {
    if (_imageFile == null && _webImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo before submitting.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('delivery_photos/${widget.jobId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      UploadTask uploadTask;

      if (kIsWeb && _webImageBytes != null) {
        uploadTask = storageRef.putData(_webImageBytes!);
      } else if (_imageFile != null) {
        uploadTask = storageRef.putFile(_imageFile!);
      } else {
        throw Exception('No image to upload.');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'status': 'delivered',
        'deliveryPhotoUrl': downloadUrl,
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushNamed(context, '/confirm_delivery', arguments: {
        'jobId': widget.jobId,
        'deliveryPhotoUrl': downloadUrl,
      });
    } catch (e) {
      debugPrint('Delivery submission failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery submission failed')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePreview = _imageFile != null
        ? Image.file(_imageFile!, height: 200, fit: BoxFit.cover)
        : _webImageBytes != null
            ? Image.memory(_webImageBytes!, height: 200, fit: BoxFit.cover)
            : const Text('No image selected.', style: TextStyle(color: Colors.white));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Mark Job as Delivered', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_jobData != null) ...[
              Text(
                'Delivery Address:',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _jobData!['dropoffAddress'] ?? 'N/A',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Item: ${_jobData!['itemDescription'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
            ],
            imagePreview,
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Upload Photo',
              icon: Icons.camera_alt,
              onPressed: _pickImage,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Submit Delivery',
              icon: Icons.check_circle,
              isLoading: _isLoading,
              onPressed: _submitDelivery,
            ),
          ],
        ),
      ),
    );
  }
}

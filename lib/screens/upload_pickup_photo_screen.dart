import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class UploadPickupPhotoScreen extends StatefulWidget {
  final String jobId;

  const UploadPickupPhotoScreen({super.key, required this.jobId});

  @override
  State<UploadPickupPhotoScreen> createState() => _UploadPickupPhotoScreenState();
}

class _UploadPickupPhotoScreenState extends State<UploadPickupPhotoScreen> {
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _imageBytes = result.files.single.bytes!;
            _imageName = result.files.single.name;
          });
        }
      } else {
        final source = await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Choose Source"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text("Camera"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text("Gallery"),
              ),
            ],
          ),
        );

        if (source == null) return;

        final pickedImage = await ImagePicker().pickImage(
          source: source,
          imageQuality: 85,
        );

        if (pickedImage != null) {
          final bytes = await pickedImage.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            _imageName = pickedImage.name;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitPickupPhoto() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a pickup photo.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final filename =
          "pickups/$uid/${DateTime.now().millisecondsSinceEpoch}_${_imageName ?? 'pickup.jpg'}";

      final ref = FirebaseStorage.instance.ref(filename);
      final uploadTask = await ref.putData(_imageBytes!);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'pickupPhotoUrl': imageUrl,
        'status': 'picked_up',
        'pickedUpAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pickup photo uploaded.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Upload Pickup Photo'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_imageBytes!, height: 200, fit: BoxFit.cover),
                ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: _imageBytes == null ? 'Choose Photo' : 'Change Photo',
                icon: Icons.camera_alt,
                onPressed: _pickImage,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Submit Pickup Photo',
                icon: Icons.check_circle,
                isLoading: _isUploading,
                onPressed: _isUploading ? null : _submitPickupPhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

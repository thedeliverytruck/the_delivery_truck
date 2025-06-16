import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_app_bar.dart';

class DeliveryConfirmationScreen extends StatefulWidget {
  final String itemDescription;
  final String? deliveryPhotoUrl;
  final String userReview;

  const DeliveryConfirmationScreen({
    super.key,
    required this.itemDescription,
    this.deliveryPhotoUrl,
    required this.userReview,
  });

  @override
  State<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen> {
  late TextEditingController _messageController;
  late TextEditingController _appReviewController;
  String _referralCode = 'yourcode';
  bool _isSaving = false;
  int _referralPoints = 0;

  File? _pickedImage;
  Uint8List? _webImageBytes;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: '''
I just used The Delivery Truck to deliver: "${widget.itemDescription}" 🚚

Here's what I thought: "${widget.userReview}"

Check it out and get your stuff moved easily!
👉 https://www.thedeliverytruck.com?ref=$_referralCode
''',
    );
    _appReviewController = TextEditingController();
    _loadReferralPoints();
  }

  Future<void> _loadReferralPoints() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final ref = await FirebaseFirestore.instance.collection('referrals').doc(uid).get();
      setState(() {
        _referralPoints = ref.data()?['points'] ?? 0;
        _referralCode = ref.data()?['code'] ?? 'yourcode';
      });
    }
  }

  Future<void> _saveReferralUsage() async {
    try {
      setState(() => _isSaving = true);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('referrals').add({
          'referralCode': _referralCode,
          'userId': uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Failed to save referral usage: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _shareDeliverySummary() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final files = <XFile>[];
    if (_pickedImage != null) {
      files.add(XFile(_pickedImage!.path));
    } else if (_webImageBytes != null) {
      final tempFile = XFile.fromData(_webImageBytes!, name: 'share.jpg');
      files.add(tempFile);
    }

    await Share.shareXFiles(files, text: message);
    await _saveReferralUsage();
  }

  Future<void> _copyReferralLink() async {
    final referralLink = 'https://www.thedeliverytruck.com?ref=$_referralCode';
    await Clipboard.setData(ClipboardData(text: referralLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral link copied to clipboard!')),
    );
    await _saveReferralUsage();
  }

  Future<void> _pickCustomImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          setState(() => _webImageBytes = bytes);
        } else {
          setState(() => _pickedImage = File(file.path));
        }
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _launchSocialShare(String platform) async {
    final url = switch (platform) {
      'x' => Uri.parse("https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_messageController.text)}"),
      'instagram' => Uri.parse("https://www.instagram.com/"),
      'facebook' => Uri.parse("https://www.facebook.com/sharer/sharer.php?u=https://www.thedeliverytruck.com?ref=$_referralCode"),
      _ => null,
    };
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _appReviewController.dispose();
    super.dispose();
  }

  Widget get _imagePreview {
    if (_pickedImage != null) {
      return Image.file(_pickedImage!, height: 150, fit: BoxFit.cover);
    } else if (_webImageBytes != null) {
      return Image.memory(_webImageBytes!, height: 150, fit: BoxFit.cover);
    } else if (widget.deliveryPhotoUrl != null) {
      return Image.network(widget.deliveryPhotoUrl!, height: 150, fit: BoxFit.cover);
    } else {
      return const Text('No image selected', style: TextStyle(color: Colors.white70));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Delivery Confirmed'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 12),
              const Text(
                "Delivery Confirmed!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text("You’ve earned: $_referralPoints points", style: const TextStyle(color: Colors.yellow)),
              const SizedBox(height: 16),
              _imagePreview,
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickCustomImage,
                icon: const Icon(Icons.photo),
                label: const Text("Choose Custom Share Image"),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _messageController,
                maxLines: 6,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Share Message',
                  labelStyle: const TextStyle(color: Colors.yellow),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _appReviewController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Write an app review',
                  labelStyle: const TextStyle(color: Colors.lightBlueAccent),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () => _launchSocialShare('x'),
                    icon: const Icon(Icons.share, color: Colors.blue),
                    tooltip: "Share on X",
                  ),
                  IconButton(
                    onPressed: () => _launchSocialShare('instagram'),
                    icon: const Icon(Icons.camera_alt, color: Colors.purple),
                    tooltip: "Open Instagram",
                  ),
                  IconButton(
                    onPressed: () => _launchSocialShare('facebook'),
                    icon: const Icon(Icons.facebook, color: Colors.blueAccent),
                    tooltip: "Share on Facebook",
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text("Share Your Experience"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: _isSaving ? null : _shareDeliverySummary,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text("Copy Referral Link"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: _isSaving ? null : _copyReferralLink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

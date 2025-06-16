import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/primary_button.dart';

class ReferralShareScreen extends StatefulWidget {
  const ReferralShareScreen({super.key});

  @override
  State<ReferralShareScreen> createState() => _ReferralShareScreenState();
}

class _ReferralShareScreenState extends State<ReferralShareScreen> {
  final _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _shareImage;
  String _referralCode = 'loading...';
  String _referralLink = '';
  String _displayName = 'You';

  @override
  void initState() {
    super.initState();
    _loadReferralCodeAndMessage();
  }

  Future<void> _loadReferralCodeAndMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final fullName = userDoc.data()?['name'] ?? '';
    final nameParts = fullName.split(' ');
    if (nameParts.isNotEmpty) {
      final firstName = nameParts.first;
      final lastInitial = nameParts.length > 1 ? nameParts.last[0] : '';
      _displayName = '$firstName $lastInitial.';
    }

    _referralCode = user.uid.substring(0, 6).toUpperCase();
    _referralLink = 'https://www.thedeliverytruck.com?ref=$_referralCode';

    _messageController.text = '''
I just signed up for The Delivery Truck app! 🚚  
It connects people who need something delivered with drivers who have trucks or trailers — fast, affordable, and local!

Whether you're moving furniture, hauling a big item, or need a delivery ASAP — this is the app for you.

Sign up here 👉 $_referralLink
(Shared by $_displayName)
''';

    setState(() {});
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _shareImage = picked);
    }
  }

  Future<void> _share({String? platform}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('referrals').add({
        'uid': uid,
        'timestamp': Timestamp.now(),
        'sharedMessage': _messageController.text.trim(),
        'platform': platform ?? 'generic',
        'referralCode': _referralCode,
      });
    }

    if (_shareImage != null) {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box?.localToGlobal(Offset.zero);
      if (origin != null && box != null) {
        await Share.shareXFiles(
          [XFile(_shareImage!.path)],
          text: _messageController.text,
          sharePositionOrigin: origin & box.size,
        );
      } else {
        await Share.shareXFiles([XFile(_shareImage!.path)], text: _messageController.text);
      }
    } else {
      await Share.share(_messageController.text);
    }
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _referralLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral link copied to clipboard!')),
    );
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/landing');
  }

  Widget _buildAppBarIcon(IconData icon, String tooltip, String route) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, route, (r) => false),
    );
  }

  Widget _socialButton(String label, IconData icon, String platform) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: () => _share(platform: platform),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 8),
            const Text('Spread the Word'),
          ],
        ),
        backgroundColor: Colors.black,
        actions: [
          _buildAppBarIcon(Icons.home, 'Landing Page', '/landing'),
          _buildAppBarIcon(Icons.local_shipping, 'Driver Home', '/driver_home'),
          _buildAppBarIcon(Icons.person, 'User Home', '/user_home'),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Help grow the network by sharing The Delivery Truck with your friends and followers!",
                style: TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _messageController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: "Your Share Message",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(color: Colors.black),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              if (_shareImage != null)
                kIsWeb
                    ? Image.network(_shareImage!.path, height: 200, fit: BoxFit.cover)
                    : Image.file(File(_shareImage!.path), height: 200, fit: BoxFit.cover),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: const Text("Upload Image"),
                    onPressed: _pickImage,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text("Copy Link"),
                    onPressed: _copyLink,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _socialButton("Share on X", Icons.share, 'x'),
                  _socialButton("Instagram", Icons.photo_camera, 'instagram'),
                  _socialButton("Facebook", Icons.facebook, 'facebook'),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Share Now',
                onPressed: () => _share(platform: 'generic'),
                isLoading: false,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _skip,
                child: const Text("Skip", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

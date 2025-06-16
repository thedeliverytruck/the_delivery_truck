import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class DriverInsuranceInfoScreen extends StatefulWidget {
  final Map<String, dynamic> previousData;

  const DriverInsuranceInfoScreen({super.key, required this.previousData});

  @override
  State<DriverInsuranceInfoScreen> createState() => _DriverInsuranceInfoScreenState();
}

class _DriverInsuranceInfoScreenState extends State<DriverInsuranceInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _autoInsCompany = TextEditingController();
  final _autoInsPolicy = TextEditingController();
  final _autoInsPhone = TextEditingController();
  final _genLiabCompany = TextEditingController();
  final _genLiabPolicy = TextEditingController();
  final _genLiabPhone = TextEditingController();

  bool _hasGeneralLiability = false;
  bool _proMembership = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String _errorMessage = '';

  final ImagePicker _picker = ImagePicker();
  XFile? _insuranceFront;
  XFile? _insuranceBack;

  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(XFile? file, String path) async {
    if (file == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref('$path/${DateTime.now().millisecondsSinceEpoch}');
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await ref.putData(bytes);
      } else {
        await ref.putFile(File(file.path));
      }
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _playCelebration() async {
    _confettiController.play();
    await _audioPlayer.play(AssetSource('sounds/truck_horn.mp3'));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || !_agreeToTerms) {
      setState(() => _errorMessage = 'Please complete the form and agree to the terms.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user!.uid;

      final insFrontUrl = await _uploadImage(_insuranceFront, 'drivers/$uid/insurance_front');
      final insBackUrl = await _uploadImage(_insuranceBack, 'drivers/$uid/insurance_back');

      final referralCode = Uri.base.queryParameters['ref'];
      String? referrerId;

      if (referralCode != null && referralCode.isNotEmpty) {
        final snapshot = await FirebaseFirestore.instance
            .collection('referralCodes')
            .where('code', isEqualTo: referralCode)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          referrerId = snapshot.docs.first['uid'];
        }
      }

      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'autoInsurance': {
          'company': _autoInsCompany.text.trim(),
          'policy': _autoInsPolicy.text.trim(),
          'phone': _autoInsPhone.text.trim(),
        },
        'hasGeneralLiability': _hasGeneralLiability,
        'generalLiability': _hasGeneralLiability
            ? {
                'company': _genLiabCompany.text.trim(),
                'policy': _genLiabPolicy.text.trim(),
                'phone': _genLiabPhone.text.trim(),
              }
            : null,
        'isPro': _proMembership,
        'subscriptionStatus': _proMembership ? 'pending' : 'none',
        'photos.insuranceFront': insFrontUrl,
        'photos.insuranceBack': insBackUrl,
        if (referrerId != null) 'referredBy': referrerId,
      });

      if (referrerId != null) {
        final rewardPoints = _proMembership ? 5 : 1;
        final referral = FirebaseFirestore.instance.collection('referrals').doc(referrerId);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final doc = await tx.get(referral);
          final current = doc.exists ? doc['points'] ?? 0 : 0;
          final referredList = doc.exists ? List<String>.from(doc['referrals'] ?? []) : [];
          if (!referredList.contains(uid)) {
            referredList.add(uid);
            tx.set(referral, {
              'uid': referrerId,
              'points': current + rewardPoints,
              'referrals': referredList,
              'lastUpdated': Timestamp.now(),
            }, SetOptions(merge: true));
          }
        });
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        final wantsUserAccount = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sign up as a User too?'),
            content: const Text('Would you also like to register as a user so you can request deliveries too?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No, just Driver")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, sign me up!")),
            ],
          ),
        );

        if (wantsUserAccount == true) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'role': 'user',
            'createdAt': Timestamp.now(),
            'email': user.email,
          });
        }
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && !refreshedUser.emailVerified) {
        await refreshedUser.sendEmailVerification();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/verify_email');
        }
        return;
      }

      await _playCelebration();

      if (_proMembership) {
        Navigator.pushReplacementNamed(
          context,
          '/pro_payment',
          arguments: {'afterSuccess': '/referral_share'},
        );
      } else {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Go PRO?'),
            content: const Text('Are you sure you don’t want to sign up as a PRO for only \$20/month?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Make me a PRO')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, I’m sure')),
            ],
          ),
        );

        if (confirm == true) {
          Navigator.pushReplacementNamed(context, '/referral_share');
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/pro_payment',
            arguments: {'afterSuccess': '/referral_share'},
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to complete registration.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source, Function(XFile) onSelected) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) onSelected(picked);
  }

  Widget _buildPhotoUpload(String label, XFile? image, Function(XFile) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (image != null)
              Image.network(
                kIsWeb ? image.path : image.path,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: () => _pickImage(ImageSource.camera, onSelected), child: const Text('Camera')),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: () => _pickImage(ImageSource.gallery, onSelected), child: const Text('Upload')),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.yellow,
      labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      hintStyle: const TextStyle(color: Colors.black),
      border: const OutlineInputBorder(),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Driver Sign-Up: Step 3',
        showBackButton: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(child: Image.asset('assets/icon/icon2.png', width: 120, height: 120)),
                    const SizedBox(height: 12),
                    const Text('Step 3 of 3: Insurance Info', style: TextStyle(fontSize: 24, color: Colors.white)),
                    const SizedBox(height: 16),
                    TextFormField(controller: _autoInsCompany, decoration: inputDecoration.copyWith(labelText: 'Auto Insurance Company'), validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 8),
                    TextFormField(controller: _autoInsPolicy, decoration: inputDecoration.copyWith(labelText: 'Auto Insurance Policy Number'), validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 8),
                    TextFormField(controller: _autoInsPhone, decoration: inputDecoration.copyWith(labelText: 'Auto Insurance Phone'), validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(value: _hasGeneralLiability, onChanged: (v) => setState(() => _hasGeneralLiability = v!)),
                        const Text('I have General Liability Insurance', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    if (_hasGeneralLiability) ...[
                      TextFormField(controller: _genLiabCompany, decoration: inputDecoration.copyWith(labelText: 'GL Insurance Company'), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 8),
                      TextFormField(controller: _genLiabPolicy, decoration: inputDecoration.copyWith(labelText: 'GL Policy Number'), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 8),
                      TextFormField(controller: _genLiabPhone, decoration: inputDecoration.copyWith(labelText: 'GL Insurance Phone'), validator: (v) => v!.isEmpty ? 'Required' : null),
                    ],
                    const SizedBox(height: 16),
                    _buildPhotoUpload('Insurance Card Front', _insuranceFront, (file) => setState(() => _insuranceFront = file)),
                    _buildPhotoUpload('Insurance Card Back', _insuranceBack, (file) => setState(() => _insuranceBack = file)),
                    CheckboxListTile(
                      value: _proMembership,
                      onChanged: (v) => setState(() => _proMembership = v!),
                      title: const Text('Enroll me in a PRO Membership for only \$20/month!', style: TextStyle(color: Colors.yellow)),
                    ),
                    Row(
                      children: [
                        Checkbox(value: _agreeToTerms, onChanged: (v) => setState(() => _agreeToTerms = v!)),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/terms_driver'),
                          child: const Text('I agree to the Terms & Conditions', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_errorMessage.isNotEmpty) Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    PrimaryButton(text: 'Finish Signup', onPressed: _isLoading ? null : _submitForm, isLoading: _isLoading),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}

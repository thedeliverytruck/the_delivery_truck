import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class SignUpUserScreen extends StatefulWidget {
  const SignUpUserScreen({super.key});

  @override
  State<SignUpUserScreen> createState() => _SignUpUserScreenState();
}

class _SignUpUserScreenState extends State<SignUpUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _agreedToTerms = false;
  String _errorMessage = '';
  String? _referralCode;
  List<String> _addressSuggestions = [];

  final String _googleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    final uri = Uri.base;
    final code = uri.queryParameters['ref'];
    if (code != null && code.isNotEmpty) {
      _referralCode = code;
    }

    _addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onAddressChanged() async {
    final input = _addressController.text;
    if (input.isEmpty) {
      setState(() => _addressSuggestions = []);
      return;
    }

    final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&components=country:us';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final suggestions = (json['predictions'] as List)
          .map((p) => p['description'] as String)
          .toList();

      setState(() {
        _addressSuggestions = suggestions;
      });
    }
  }

  Future<void> _trackReferral(String newUserId) async {
    if (_referralCode == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('referralCodes')
        .where('code', isEqualTo: _referralCode)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final referrerUid = snapshot.docs.first['uid'];
      final referralRef = FirebaseFirestore.instance.collection('referrals').doc(referrerUid);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final doc = await tx.get(referralRef);
        final currentPoints = doc.exists ? (doc['points'] ?? 0) as int : 0;
        final referrals = doc.exists ? List<String>.from(doc['referrals'] ?? []) : [];

        if (!referrals.contains(newUserId)) {
          referrals.add(newUserId);
          tx.set(referralRef, {
            'uid': referrerUid,
            'points': currentPoints + 1,
            'referrals': referrals,
            'lastUpdated': Timestamp.now(),
          }, SetOptions(merge: true));
        }
      });

      await FirebaseFirestore.instance.collection('referral_conversions').add({
        'referrerUid': referrerUid,
        'referredUid': newUserId,
        'role': 'user',
        'timestamp': Timestamp.now(),
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || !_agreedToTerms) {
      setState(() => _errorMessage = 'Please fill out all fields and accept the Terms.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();

    try {
      final existingMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (existingMethods.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Account Exists"),
            content: const Text("That email is already registered. Would you like to also register as a user?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes")),
            ],
          ),
        );

        if (confirmed != true) {
          setState(() {
            _loading = false;
            _errorMessage = "User cancelled.";
          });
          return;
        }

        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );

        final uid = userCredential.user?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'role': 'user',
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': email,
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'createdAt': Timestamp.now(),
          }, SetOptions(merge: true));

          _confettiController.play();
          _audioPlayer.play(AssetSource('sounds/truck_horn.mp3'));

          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/referral_share', arguments: {'role': 'user'});
          }
        }
        return;
      }

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      final user = userCredential.user;
      final uid = user?.uid;
      if (uid != null && user != null) {
        final userDoc = {
          'uid': uid,
          'role': 'user',
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': email,
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'createdAt': Timestamp.now(),
        };

        if (_referralCode != null) {
          userDoc['referredBy'] = _referralCode!;
        }

        await FirebaseFirestore.instance.collection('users').doc(uid).set(userDoc);
        await _trackReferral(uid);
        await user.sendEmailVerification();

        _confettiController.play();
        _audioPlayer.play(AssetSource('sounds/truck_horn.mp3'));

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/verify_email');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Registration failed.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showTerms() {
    Navigator.pushNamed(context, '/terms_user');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Sign Up as User', showBackButton: true),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Image.asset('assets/icon/icon2.png', width: 120, height: 120),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Enter first name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Enter last name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter email';
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                          return emailRegex.hasMatch(v) ? null : 'Enter a valid email';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Cell Phone Number', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.length < 10 ? 'Enter valid phone' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Home Address', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Enter your address' : null,
                      ),
                      if (_addressSuggestions.isNotEmpty)
                        Container(
                          color: Colors.white,
                          child: Column(
                            children: _addressSuggestions.map((s) {
                              return ListTile(
                                title: Text(s),
                                onTap: () {
                                  _addressController.text = s;
                                  setState(() => _addressSuggestions = []);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                          ),
                          GestureDetector(
                            onTap: _showTerms,
                            child: const Text(
                              'I agree to receive text/push notifications and Terms & Conditions',
                              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                        ),
                      PrimaryButton(text: 'Create Account', onPressed: _submitForm, isLoading: _loading),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.red, Colors.blue, Colors.white, Colors.yellow],
            ),
          ),
        ],
      ),
    );
  }
}

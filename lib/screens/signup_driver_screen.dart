import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/primary_button.dart';

class SignUpDriverScreen extends StatefulWidget {
  const SignUpDriverScreen({super.key});

  @override
  State<SignUpDriverScreen> createState() => _SignUpDriverScreenState();
}

class _SignUpDriverScreenState extends State<SignUpDriverScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _suffix = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _licenseNumber = TextEditingController();
  final _autoInsCompany = TextEditingController();
  final _autoInsPolicy = TextEditingController();
  final _autoInsPhone = TextEditingController();
  final _genLiabCompany = TextEditingController();
  final _genLiabPolicy = TextEditingController();
  final _genLiabPhone = TextEditingController();
  final _vehicleMake = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _vehicleYear = TextEditingController();
  final _vehicleColor = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  String? _trailerSize;
  List<String> _trailerTypes = [];
  bool _hasGeneralLiability = false;
  bool _agreeToTerms = false;
  bool _proMembership = false;
  bool _isLoading = false;
  String _errorMessage = '';

  final ImagePicker _picker = ImagePicker();
  XFile? _headshot;
  XFile? _vehiclePhoto;
  XFile? _licensePhoto;
  XFile? _insuranceFront;
  XFile? _insuranceBack;

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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || !_agreeToTerms) return;
    if (_password.text != _confirmPassword.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authResult = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      final uid = authResult.user!.uid;

      final headshotUrl = await _uploadImage(_headshot, 'drivers/$uid/headshot');
      final vehicleUrl = await _uploadImage(_vehiclePhoto, 'drivers/$uid/vehicle');
      final licenseUrl = await _uploadImage(_licensePhoto, 'drivers/$uid/license');
      final insFrontUrl = await _uploadImage(_insuranceFront, 'drivers/$uid/insurance_front');
      final insBackUrl = await _uploadImage(_insuranceBack, 'drivers/$uid/insurance_back');

      await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
        'uid': uid,
        'role': 'driver',
        'firstName': _firstName.text.trim(),
        'middleName': _middleName.text.trim(),
        'lastName': _lastName.text.trim(),
        'suffix': _suffix.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'licenseNumber': _licenseNumber.text.trim(),
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
        'vehicle': {
          'make': _vehicleMake.text.trim(),
          'model': _vehicleModel.text.trim(),
          'year': _vehicleYear.text.trim(),
          'color': _vehicleColor.text.trim(),
        },
        'trailer': {
          'size': _trailerSize,
          'types': _trailerTypes,
        },
        'isPro': _proMembership,
        'subscriptionStatus': _proMembership ? 'pending' : 'none',
        'createdAt': Timestamp.now(),
        'photos': {
          'headshot': headshotUrl,
          'vehicle': vehicleUrl,
          'license': licenseUrl,
          'insuranceFront': insFrontUrl,
          'insuranceBack': insBackUrl,
        }
      });

      if (_proMembership) {
        Navigator.pushReplacementNamed(context, '/pro_payment');
      } else {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Go PRO?'),
            content: const Text(
                'Are you sure you don’t want to sign up as a PRO for only \$20 a month and appear at the top of the driver list?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Make me a PRO'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, I’m sure'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          Navigator.pushReplacementNamed(context, '/driver_home');
        } else {
          Navigator.pushReplacementNamed(context, '/pro_payment');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Registration failed.');
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
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera, onSelected),
              child: const Text('Camera'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery, onSelected),
              child: const Text('Upload'),
            ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('assets/icon/icon.png', width: 120, height: 120),
                const SizedBox(height: 12),
                const Text('Sign Up as Driver', style: TextStyle(fontSize: 24, color: Colors.white)),
                const SizedBox(height: 16),
                TextFormField(controller: _firstName, decoration: inputDecoration.copyWith(labelText: 'First Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _middleName, decoration: inputDecoration.copyWith(labelText: 'Middle Name')),
                const SizedBox(height: 8),
                TextFormField(controller: _lastName, decoration: inputDecoration.copyWith(labelText: 'Last Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _suffix, decoration: inputDecoration.copyWith(labelText: 'Suffix')),
                const SizedBox(height: 8),
                TextFormField(controller: _email, decoration: inputDecoration.copyWith(labelText: 'Email'), keyboardType: TextInputType.emailAddress, validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _phone, decoration: inputDecoration.copyWith(labelText: 'Cell Phone Number'), keyboardType: TextInputType.phone, validator: (v) => v!.length < 10 ? 'Invalid phone' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _address, decoration: inputDecoration.copyWith(labelText: 'Address'), validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _licenseNumber, decoration: inputDecoration.copyWith(labelText: 'Driver License Number'), validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _autoInsCompany, decoration: inputDecoration.copyWith(labelText: 'Auto Insurance Company')),
                const SizedBox(height: 8),
                TextFormField(controller: _autoInsPolicy, decoration: inputDecoration.copyWith(labelText: 'Auto Insurance Policy Number')),
                const SizedBox(height: 8),
                TextFormField(controller: _autoInsPhone, decoration: inputDecoration.copyWith(labelText: 'Auto Insurance Phone')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(value: _hasGeneralLiability, onChanged: (v) => setState(() => _hasGeneralLiability = v!)),
                    const Text('I have General Liability Insurance', style: TextStyle(color: Colors.white)),
                  ],
                ),
                if (_hasGeneralLiability) ...[
                  TextFormField(controller: _genLiabCompany, decoration: inputDecoration.copyWith(labelText: 'GL Insurance Company')),
                  const SizedBox(height: 8),
                  TextFormField(controller: _genLiabPolicy, decoration: inputDecoration.copyWith(labelText: 'GL Policy Number')),
                  const SizedBox(height: 8),
                  TextFormField(controller: _genLiabPhone, decoration: inputDecoration.copyWith(labelText: 'GL Insurance Phone')),
                ],
                const SizedBox(height: 8),
                TextFormField(controller: _vehicleMake, decoration: inputDecoration.copyWith(labelText: 'Vehicle Make')),
                const SizedBox(height: 8),
                TextFormField(controller: _vehicleModel, decoration: inputDecoration.copyWith(labelText: 'Vehicle Model')),
                const SizedBox(height: 8),
                TextFormField(controller: _vehicleYear, decoration: inputDecoration.copyWith(labelText: 'Vehicle Year')),
                const SizedBox(height: 8),
                TextFormField(controller: _vehicleColor, decoration: inputDecoration.copyWith(labelText: 'Vehicle Color')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _trailerSize,
                  items: ['4x8', '5x10', '6x12', 'Larger'].map((size) => DropdownMenuItem(value: size, child: Text(size))).toList(),
                  onChanged: (value) => setState(() => _trailerSize = value),
                  decoration: inputDecoration.copyWith(labelText: 'Trailer Size'),
                ),
                CheckboxListTile(
                  value: _trailerTypes.contains('Enclosed'),
                  onChanged: (v) => setState(() {
                    v! ? _trailerTypes.add('Enclosed') : _trailerTypes.remove('Enclosed');
                  }),
                  title: const Text('Enclosed Trailer', style: TextStyle(color: Colors.white)),
                ),
                CheckboxListTile(
                  value: _trailerTypes.contains('Open'),
                  onChanged: (v) => setState(() {
                    v! ? _trailerTypes.add('Open') : _trailerTypes.remove('Open');
                  }),
                  title: const Text('Open Trailer', style: TextStyle(color: Colors.white)),
                ),
                TextFormField(controller: _password, obscureText: true, decoration: inputDecoration.copyWith(labelText: 'Password'), validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _confirmPassword, obscureText: true, decoration: inputDecoration.copyWith(labelText: 'Confirm Password')),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _proMembership,
                  onChanged: (v) => setState(() => _proMembership = v!),
                  title: const Text('Enroll me in a PRO Membership for only \$20/month!', style: TextStyle(color: Colors.yellow)),
                ),
                const SizedBox(height: 16),
                _buildPhotoUpload('Driver Headshot', _headshot, (file) => setState(() => _headshot = file)),
                _buildPhotoUpload('Vehicle Photo', _vehiclePhoto, (file) => setState(() => _vehiclePhoto = file)),
                _buildPhotoUpload('License Photo', _licensePhoto, (file) => setState(() => _licensePhoto = file)),
                _buildPhotoUpload('Insurance Card Front', _insuranceFront, (file) => setState(() => _insuranceFront = file)),
                _buildPhotoUpload('Insurance Card Back', _insuranceBack, (file) => setState(() => _insuranceBack = file)),
                Row(
                  children: [
                    Checkbox(value: _agreeToTerms, onChanged: (v) => setState(() => _agreeToTerms = v!)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/webview', arguments: {'url': 'https://www.thedeliverytruck.com/terms'}),
                      child: const Text('I agree to the Terms & Conditions', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_errorMessage.isNotEmpty)
                  Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                PrimaryButton(text: 'Create Account', onPressed: _isLoading ? null : _submitForm, isLoading: _isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class EditUserProfileScreen extends StatefulWidget {
  const EditUserProfileScreen({super.key});

  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String address = '';

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        firstName = data['firstName'] ?? '';
        lastName = data['lastName'] ?? '';
        email = data['email'] ?? '';
        phone = data['phone'] ?? '';
        address = data['address'] ?? '';
      });
    }
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
    });

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.yellow,
      labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      hintStyle: const TextStyle(color: Colors.black),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Edit My Profile'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Image.asset('assets/icon/icon2.png', width: 100, height: 100),
                      const SizedBox(height: 20),
                      TextFormField(
                        initialValue: firstName,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('First Name'),
                        onSaved: (value) => firstName = value!.trim(),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: lastName,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Last Name'),
                        onSaved: (value) => lastName = value!.trim(),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: email,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Email'),
                        onSaved: (value) => email = value!.trim(),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: phone,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Phone Number'),
                        onSaved: (value) => phone = value!.trim(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: address,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Address'),
                        onSaved: (value) => address = value!.trim(),
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        text: 'Save Changes',
                        onPressed: saveChanges,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

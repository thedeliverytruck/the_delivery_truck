import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class EditDriverProfileScreen extends StatefulWidget {
  const EditDriverProfileScreen({super.key});

  @override
  State<EditDriverProfileScreen> createState() => _EditDriverProfileScreenState();
}

class _EditDriverProfileScreenState extends State<EditDriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String address = '';
  String licenseNumber = '';
  String vehicleInfo = '';
  String trailerInfo = '';
  String insuranceInfo = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadDriverData();
  }

  Future<void> loadDriverData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        firstName = data['firstName'] ?? '';
        lastName = data['lastName'] ?? '';
        email = data['email'] ?? '';
        phone = data['phone'] ?? '';
        address = data['address'] ?? '';
        licenseNumber = data['licenseNumber'] ?? '';
        vehicleInfo = data['vehicleInfo'] ?? '';
        trailerInfo = data['trailerInfo'] ?? '';
        insuranceInfo = data['insuranceInfo'] ?? '';
      });
    }
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'licenseNumber': licenseNumber,
      'vehicleInfo': vehicleInfo,
      'trailerInfo': trailerInfo,
      'insuranceInfo': insuranceInfo,
    });

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Driver profile updated successfully')),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.yellow,
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      hintStyle: const TextStyle(color: Colors.black),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Edit Driver Profile'),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: licenseNumber,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Driver License Number'),
                        onSaved: (value) => licenseNumber = value!.trim(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: vehicleInfo,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Vehicle Info'),
                        onSaved: (value) => vehicleInfo = value!.trim(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: trailerInfo,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Trailer Info'),
                        onSaved: (value) => trailerInfo = value!.trim(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: insuranceInfo,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Insurance Info'),
                        onSaved: (value) => insuranceInfo = value!.trim(),
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        text: 'Save Changes',
                        onPressed: saveChanges,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

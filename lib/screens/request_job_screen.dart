// lib/screens/request_job_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class RequestJobScreen extends StatefulWidget {
  const RequestJobScreen({super.key});

  @override
  State<RequestJobScreen> createState() => _RequestJobScreenState();
}

class _RequestJobScreenState extends State<RequestJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _pickupDescController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();
  final _weightController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _pickupLocationNameController = TextEditingController();
  final _dropoffLocationNameController = TextEditingController();

  File? _selectedImage;
  String? _webImagePath;
  bool _isLoading = false;
  bool _useCurrentLocation = false;
  bool _useDifferentDropoff = false;
  bool _trailerRequested = false;
  String? _trailerType;
  String _deliveryType = 'Curbside';

  @override
  void dispose() {
    _pickupController.dispose();
    _pickupDescController.dispose();
    _dropoffController.dispose();
    _descriptionController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _weightController.dispose();
    _specialInstructionsController.dispose();
    _pickupLocationNameController.dispose();
    _dropoffLocationNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        setState(() => _webImagePath = picked.path);
      } else {
        setState(() => _selectedImage = File(picked.path));
      }
    }
  }

  Future<void> _useMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.first;
      String address = '${place.street}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
      setState(() {
        _pickupController.text = address;
        _pickupLocationNameController.text = 'My Current Location';
      });
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null || _webImagePath != null) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = FirebaseStorage.instance.ref().child('job_images/$fileName');

        if (kIsWeb && _webImagePath != null) {
          final bytes = await XFile(_webImagePath!).readAsBytes();
          await ref.putData(bytes);
        } else {
          await ref.putFile(_selectedImage!);
        }

        imageUrl = await ref.getDownloadURL();
      }

      double? pickupLat;
      double? pickupLng;
      double? dropoffLat;
      double? dropoffLng;

      if (_pickupController.text.isNotEmpty) {
        List<Location> locations = await locationFromAddress(_pickupController.text);
        if (locations.isNotEmpty) {
          pickupLat = locations.first.latitude;
          pickupLng = locations.first.longitude;
        }
      }

      if (_dropoffController.text.isNotEmpty) {
        List<Location> locations = await locationFromAddress(_dropoffController.text);
        if (locations.isNotEmpty) {
          dropoffLat = locations.first.latitude;
          dropoffLng = locations.first.longitude;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final userProfile = doc.data();

      final jobData = {
        'pickupAddress': _pickupController.text.trim(),
        'pickupLocationName': _pickupLocationNameController.text.trim(),
        'pickupDescription': _pickupDescController.text.trim(),
        'dropoffAddress': _dropoffController.text.trim(),
        'dropoffLocationName': _dropoffLocationNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'length': _lengthController.text.trim(),
        'width': _widthController.text.trim(),
        'depth': _depthController.text.trim(),
        'weight': _weightController.text.trim(),
        'deliveryType': _deliveryType,
        'specialInstructions': _specialInstructionsController.text.trim(),
        'trailerRequested': _trailerRequested,
        'trailerType': _trailerRequested ? _trailerType : null,
        'imageUrl': imageUrl,
        'status': 'pending',
        'userId': user.uid,
        'userName': userProfile?['name'],
        'timestamp': FieldValue.serverTimestamp(),
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropoffLocation': dropoffLat != null && dropoffLng != null
            ? {'latitude': dropoffLat, 'longitude': dropoffLng}
            : null,
      };

      final jobRef = await FirebaseFirestore.instance.collection('jobs').add(jobData);

      if (!mounted) return;
      Navigator.pushNamed(context, '/job_quote', arguments: {'jobId': jobRef.id});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
        ),
        validator: required ? (value) => (value == null || value.isEmpty) ? 'Required' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Request a Job'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(child: Image.asset('assets/icon/icon2.png', width: 120, height: 120)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Use My Location', style: TextStyle(color: Colors.white)),
                  value: _useCurrentLocation,
                  onChanged: (v) {
                    setState(() => _useCurrentLocation = v);
                    if (v) _useMyLocation();
                  },
                ),
                _buildTextField(_pickupLocationNameController, 'Pickup Location Name'),
                _buildTextField(_pickupController, 'Pickup Address', required: true),
                _buildTextField(_pickupDescController, 'Pickup Location Description (i.e. Loading Dock)'),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Use Different Dropoff Location', style: TextStyle(color: Colors.white)),
                  value: _useDifferentDropoff,
                  onChanged: (v) {
                    setState(() => _useDifferentDropoff = v);
                    if (!v) {
                      final user = FirebaseAuth.instance.currentUser;
                      FirebaseFirestore.instance.collection('users').doc(user!.uid).get().then((doc) {
                        final data = doc.data();
                        if (data != null) {
                          setState(() {
                            _dropoffLocationNameController.text = 'My Home';
                            _dropoffController.text = data['address'] ?? '';
                          });
                        }
                      });
                    } else {
                      _dropoffLocationNameController.clear();
                      _dropoffController.clear();
                    }
                  },
                ),
                _buildTextField(_dropoffLocationNameController, 'Dropoff Location Name'),
                _buildTextField(_dropoffController, 'Dropoff Address', required: true),
                _buildTextField(_descriptionController, 'Item Description', required: true),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_lengthController, 'Length (in)', type: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(_widthController, 'Width (in)', type: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(_depthController, 'Depth (in)', type: TextInputType.number)),
                  ],
                ),
                _buildTextField(_weightController, 'Weight (lbs)', type: TextInputType.number),
                DropdownButtonFormField<String>(
                  value: _deliveryType,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Delivery Type',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                  ),
                  items: ['Curbside', 'Inside 1st Floor', 'Inside 2nd Floor']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (v) => setState(() => _deliveryType = v!),
                ),
                CheckboxListTile(
                  value: _trailerRequested,
                  onChanged: (v) => setState(() => _trailerRequested = v!),
                  title: const Text('Trailer Requested?', style: TextStyle(color: Colors.white)),
                ),
                if (_trailerRequested)
                  DropdownButtonFormField<String>(
                    value: _trailerType,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Trailer Type',
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(),
                    ),
                    items: ['Open', 'Enclosed', 'Dump Style']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (v) => setState(() => _trailerType = v),
                    validator: (v) => _trailerRequested && v == null ? 'Select trailer type' : null,
                  ),
                const SizedBox(height: 12),
                _buildTextField(_specialInstructionsController, 'Special Instructions'),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Upload Image'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Submit Job Request',
                  onPressed: _isLoading ? null : _submitJob,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

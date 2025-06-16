import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_delivery_truck/widgets/primary_button.dart';
import 'package:google_maps_webservice/places.dart';

class DriverPersonalInfoScreen extends StatefulWidget {
  const DriverPersonalInfoScreen({super.key});

  @override
  State<DriverPersonalInfoScreen> createState() => _DriverPersonalInfoScreenState();
}

class _DriverPersonalInfoScreenState extends State<DriverPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _suffix = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _licenseNumber = TextEditingController();
  String? _selectedState;
  bool _agreedToNotifications = false;

  final ImagePicker _picker = ImagePicker();
  XFile? _headshot;
  XFile? _licensePhoto;
  bool _isLoading = false;
  String _errorMessage = '';
  final _places = GoogleMapsPlaces(apiKey: 'AIzaSyCh-O9NUty2VEG6R0nQIbl5MQFV6GgHXVg');
  List<Prediction> _addressPredictions = [];

  final List<String> _states = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
  ];

  Future<void> _pickImage(ImageSource source, Function(XFile) onSelected) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) onSelected(picked);
  }

  void _searchAddress(String input) async {
    if (input.isEmpty) {
      setState(() => _addressPredictions = []);
      return;
    }

    final response = await _places.autocomplete(input);
    if (response.isOkay) {
      setState(() => _addressPredictions = response.predictions);
    }
  }

  void _selectAddress(String address) {
    setState(() {
      _address.text = address;
      _addressPredictions = [];
    });
  }

  void _continueToVehicleInfo() {
    if (_formKey.currentState!.validate()) {
      if (_headshot == null || _licensePhoto == null) {
        setState(() => _errorMessage = 'Please upload all required photos.');
        return;
      }
      if (!_agreedToNotifications) {
        setState(() => _errorMessage = 'Please agree to receive notifications.');
        return;
      }

      final personalData = {
        'firstName': _firstName.text.trim(),
        'middleName': _middleName.text.trim(),
        'lastName': _lastName.text.trim(),
        'suffix': _suffix.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'licenseNumber': _licenseNumber.text.trim(),
        'licenseState': _selectedState,
        'headshot': _headshot,
        'licensePhoto': _licensePhoto,
      };

      Navigator.pushNamed(context, '/driver_vehicle_info', arguments: personalData);
    }
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
              Image.network(kIsWeb ? image.path : image.path, width: 80, height: 80, fit: BoxFit.cover),
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Driver Sign-Up: Step 1'),
        actions: [
          IconButton(icon: const Icon(Icons.home), tooltip: 'Landing Page', onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/landing', (r) => false)),
          IconButton(icon: const Icon(Icons.local_shipping), tooltip: 'Driver Home', onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/driver_home', (r) => false)),
          IconButton(icon: const Icon(Icons.person), tooltip: 'User Home', onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/user_home', (r) => false)),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Image.asset('assets/icon/icon2.png', width: 120, height: 120)),
                const SizedBox(height: 12),
                const Text('Step 1 of 3: Personal Info', style: TextStyle(fontSize: 24, color: Colors.white)),
                const SizedBox(height: 16),
                TextFormField(controller: _firstName, decoration: inputDecoration.copyWith(labelText: 'First Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _middleName, decoration: inputDecoration.copyWith(labelText: 'Middle Name')),
                const SizedBox(height: 8),
                TextFormField(controller: _lastName, decoration: inputDecoration.copyWith(labelText: 'Last Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _suffix, decoration: inputDecoration.copyWith(labelText: 'Suffix')),
                const SizedBox(height: 8),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: inputDecoration.copyWith(labelText: 'Email'), validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: inputDecoration.copyWith(labelText: 'Cell Phone Number'), validator: (v) => v!.length < 10 ? 'Invalid phone' : null),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _address,
                  decoration: inputDecoration.copyWith(labelText: 'Home Address'),
                  onChanged: _searchAddress,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                ..._addressPredictions.map((p) => ListTile(
                      tileColor: Colors.white,
                      title: Text(p.description ?? '', style: const TextStyle(color: Colors.black)),
                      onTap: () => _selectAddress(p.description ?? ''),
                    )),
                const SizedBox(height: 8),
                TextFormField(controller: _licenseNumber, decoration: inputDecoration.copyWith(labelText: 'Driver License Number'), validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  decoration: inputDecoration.copyWith(labelText: 'Driver License State'),
                  dropdownColor: Colors.white, // Fix for white-on-white dropdown
                  style: const TextStyle(color: Colors.black), // Ensures readable text
                  items: _states.map((state) => DropdownMenuItem(
                    value: state,
                    child: Text(state),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedState = value),
                  validator: (v) => v == null ? 'Select a state' : null,
                ),
                const SizedBox(height: 16),
                _buildPhotoUpload('Driver Headshot', _headshot, (file) => setState(() => _headshot = file)),
                _buildPhotoUpload('Driver License Photo', _licensePhoto, (file) => setState(() => _licensePhoto = file)),
                Row(
                  children: [
                    Checkbox(value: _agreedToNotifications, onChanged: (v) => setState(() => _agreedToNotifications = v ?? false)),
                    const Flexible(
                      child: Text(
                        'I agree to receive text and push notifications regarding my deliveries and driver activity.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage.isNotEmpty)
                  Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                PrimaryButton(
                  text: 'Continue to Vehicle Info',
                  onPressed: _isLoading ? null : _continueToVehicleInfo,
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

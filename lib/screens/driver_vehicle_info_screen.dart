import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class DriverVehicleInfoScreen extends StatefulWidget {
  final Map<String, dynamic> previousData;

  const DriverVehicleInfoScreen({super.key, required this.previousData});

  @override
  State<DriverVehicleInfoScreen> createState() => _DriverVehicleInfoScreenState();
}

class _DriverVehicleInfoScreenState extends State<DriverVehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedYear;
  String? _selectedMake;
  String? _selectedModel;
  final _vehicleColor = TextEditingController();

  bool _hasTrailer = false;
  String? _trailerSize;
  List<String> _trailerTypes = [];

  final ImagePicker _picker = ImagePicker();
  XFile? _vehiclePhoto;
  XFile? _licensePlatePhoto;

  bool _isLoading = false;
  String _errorMessage = '';

  List<String> _availableYears = [];
  List<String> _availableMakes = [];
  List<String> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _generateYearList();
  }

  void _generateYearList() {
    final currentYear = DateTime.now().year;
    _availableYears = List.generate(30, (index) => (currentYear - index).toString());
  }

  Future<void> _fetchMakes(String year) async {
    final url = Uri.parse('https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/car?format=json');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _availableMakes = (data['Results'] as List).map((e) => e['MakeName'].toString()).toSet().toList()..sort();
        _selectedMake = null;
        _selectedModel = null;
        _availableModels = [];
      });
    }
  }

  Future<void> _fetchModels(String year, String make) async {
    final url = Uri.parse('https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMakeYear/make/$make/modelyear/$year?format=json');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _availableModels = (data['Results'] as List).map((e) => e['Model_Name'].toString()).toSet().toList()..sort();
        _selectedModel = null;
      });
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
              kIsWeb
                  ? Image.network(image.path, width: 80, height: 80, fit: BoxFit.cover)
                  : Image.file(File(image.path), width: 80, height: 80, fit: BoxFit.cover),
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

  void _submitVehicleInfo() {
    if (!_formKey.currentState!.validate()) return;
    if (_vehiclePhoto == null || _licensePlatePhoto == null) {
      setState(() => _errorMessage = 'Please upload both vehicle and license plate photos.');
      return;
    }

    final vehicleData = {
      'vehicle': {
        'year': _selectedYear,
        'make': _selectedMake,
        'model': _selectedModel,
        'color': _vehicleColor.text.trim(),
      },
      'trailer': _hasTrailer
          ? {
              'size': _trailerSize,
              'types': _trailerTypes,
            }
          : null,
      'photos': {
        'vehicle': _vehiclePhoto,
        'licensePlate': _licensePlatePhoto,
      }
    };

    final allData = {
      ...widget.previousData,
      ...vehicleData,
    };

    Navigator.pushNamed(context, '/driver_insurance_info', arguments: allData);
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
        title: 'Driver Sign-Up: Step 2',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(child: Image.asset('assets/icon/icon2.png', width: 120, height: 120)),
                const SizedBox(height: 12),
                const Text('Step 2 of 3: Vehicle Info', style: TextStyle(fontSize: 24, color: Colors.white)),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedYear,
                  decoration: inputDecoration.copyWith(labelText: 'Vehicle Year'),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black),
                  items: _availableYears
                      .map((year) => DropdownMenuItem(value: year, child: Text(year, style: const TextStyle(color: Colors.black))))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedYear = value);
                    if (value != null) _fetchMakes(value);
                  },
                  validator: (v) => v == null ? 'Select year' : null,
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _selectedMake,
                  decoration: inputDecoration.copyWith(labelText: 'Vehicle Make'),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black),
                  items: _availableMakes
                      .map((make) => DropdownMenuItem(value: make, child: Text(make, style: const TextStyle(color: Colors.black))))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedMake = value);
                    if (value != null && _selectedYear != null) _fetchModels(_selectedYear!, value);
                  },
                  validator: (v) => v == null ? 'Select make' : null,
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _selectedModel,
                  decoration: inputDecoration.copyWith(labelText: 'Vehicle Model'),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black),
                  items: _availableModels
                      .map((model) => DropdownMenuItem(value: model, child: Text(model, style: const TextStyle(color: Colors.black))))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedModel = value),
                  validator: (v) => v == null ? 'Select model' : null,
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _vehicleColor,
                  decoration: inputDecoration.copyWith(labelText: 'Vehicle Color'),
                  style: const TextStyle(color: Colors.black), // ✅ Explicit black text
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _hasTrailer,
                  onChanged: (value) => setState(() => _hasTrailer = value ?? false),
                  title: const Text('Do you also have a trailer?', style: TextStyle(color: Colors.white)),
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                if (_hasTrailer) ...[
                  DropdownButtonFormField<String>(
                    value: _trailerSize,
                    decoration: inputDecoration.copyWith(labelText: 'Trailer Size'),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: ['4x8', '5x10', '6x12', 'Larger']
                        .map((size) => DropdownMenuItem(value: size, child: Text(size, style: const TextStyle(color: Colors.black))))
                        .toList(),
                    onChanged: (value) => setState(() => _trailerSize = value),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('What type of trailer?', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  CheckboxListTile(
                    value: _trailerTypes.contains('Enclosed'),
                    onChanged: (v) => setState(() {
                      v! ? _trailerTypes.add('Enclosed') : _trailerTypes.remove('Enclosed');
                    }),
                    title: const Text('Enclosed', style: TextStyle(color: Colors.white)),
                  ),
                  CheckboxListTile(
                    value: _trailerTypes.contains('Open'),
                    onChanged: (v) => setState(() {
                      v! ? _trailerTypes.add('Open') : _trailerTypes.remove('Open');
                    }),
                    title: const Text('Open', style: TextStyle(color: Colors.white)),
                  ),
                  CheckboxListTile(
                    value: _trailerTypes.contains('Dump Style'),
                    onChanged: (v) => setState(() {
                      v! ? _trailerTypes.add('Dump Style') : _trailerTypes.remove('Dump Style');
                    }),
                    title: const Text('Dump Style', style: TextStyle(color: Colors.white)),
                  ),
                ],
                const SizedBox(height: 16),
                _buildPhotoUpload('Vehicle Photo', _vehiclePhoto, (file) => setState(() => _vehiclePhoto = file)),
                _buildPhotoUpload('License Plate Photo', _licensePlatePhoto, (file) => setState(() => _licensePlatePhoto = file)),
                if (_errorMessage.isNotEmpty)
                  Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Continue to Insurance Info',
                  onPressed: _isLoading ? null : _submitVehicleInfo,
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

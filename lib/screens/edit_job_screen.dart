import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

class EditJobScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const EditJobScreen({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _pickupName;
  late TextEditingController _pickupAddress;
  late TextEditingController _itemDescription;
  late TextEditingController _itemSize;
  late TextEditingController _itemWeight;
  late TextEditingController _deliveryType;
  late TextEditingController _specialInstructions;

  @override
  void initState() {
    super.initState();
    final job = widget.jobData;
    _pickupName = TextEditingController(text: job['pickupName'] ?? '');
    _pickupAddress = TextEditingController(text: job['pickupAddress'] ?? '');
    _itemDescription = TextEditingController(text: job['itemDescription'] ?? '');
    _itemSize = TextEditingController(text: job['itemSize'] ?? '');
    _itemWeight = TextEditingController(text: job['itemWeight'] ?? '');
    _deliveryType = TextEditingController(text: job['deliveryType'] ?? '');
    _specialInstructions = TextEditingController(text: job['specialInstructions'] ?? '');
  }

  @override
  void dispose() {
    _pickupName.dispose();
    _pickupAddress.dispose();
    _itemDescription.dispose();
    _itemSize.dispose();
    _itemWeight.dispose();
    _deliveryType.dispose();
    _specialInstructions.dispose();
    super.dispose();
  }

  Future<void> _updateJob() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'pickupName': _pickupName.text.trim(),
        'pickupAddress': _pickupAddress.text.trim(),
        'itemDescription': _itemDescription.text.trim(),
        'itemSize': _itemSize.text.trim(),
        'itemWeight': _itemWeight.text.trim(),
        'deliveryType': _deliveryType.text.trim(),
        'specialInstructions': _specialInstructions.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job updated successfully.")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update job: $e")),
      );
    }
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
      appBar: const CustomAppBar(title: "Edit Job Request"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('assets/icon/icon2.png', width: 100, height: 100),
                const SizedBox(height: 20),
                _buildField(_pickupName, 'Pickup Name', true),
                _buildField(_pickupAddress, 'Pickup Address', true),
                _buildField(_itemDescription, 'Item Description'),
                _buildField(_itemSize, 'Item Size'),
                _buildField(_itemWeight, 'Item Weight'),
                _buildField(_deliveryType, 'Delivery Type'),
                _buildField(_specialInstructions, 'Special Instructions'),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: "Save Changes",
                  onPressed: _updateJob,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, [bool isRequired = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.black),
        decoration: _inputDecoration(label),
        validator: isRequired
            ? (value) => value == null || value.isEmpty ? 'Required' : null
            : null,
      ),
    );
  }
}

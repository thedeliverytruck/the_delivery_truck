import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../widgets/custom_app_bar.dart';

class UpdatePaymentScreen extends StatefulWidget {
  const UpdatePaymentScreen({super.key});

  @override
  State<UpdatePaymentScreen> createState() => _UpdatePaymentScreenState();
}

class _UpdatePaymentScreenState extends State<UpdatePaymentScreen> {
  bool _isLoading = false;

  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createBillingPortal');
      final result = await callable();
      final url = result.data['url'];

      if (url != null && mounted) {
        Navigator.pushNamed(context, '/webview', arguments: {'url': url});
      }
    } catch (e) {
      debugPrint('Error launching billing portal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open billing portal')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Manage Payment'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'To update or manage your PRO subscription billing details, tap the button below.',
                style: TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Open Billing Portal',
                icon: Icons.credit_card,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleUpdate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

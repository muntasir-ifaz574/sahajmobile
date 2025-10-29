import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import '../../../core/theme/app_theme.dart';

class OnlineContractScreen extends ConsumerStatefulWidget {
  const OnlineContractScreen({super.key});

  @override
  ConsumerState<OnlineContractScreen> createState() =>
      _OnlineContractScreenState();
}

class _OnlineContractScreenState extends ConsumerState<OnlineContractScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: AppTheme.textPrimary,
    exportBackgroundColor: Colors.white,
  );

  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _signatureController.addListener(() {
      setState(() {
        _hasSignature = _signatureController.points.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  void _clearSignature() {
    _signatureController.clear();
  }

  void _undoSignature() {
    // Signature package doesn't have built-in undo, so we'll clear for now
    // You could implement a more sophisticated undo system if needed
    _signatureController.clear();
  }

  Future<void> _saveSignature() async {
    if (!_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign your name before proceeding'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Export signature as image
      await _signatureController.toPngBytes();

      // Here you would typically save the signature data
      // For now, we'll just show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to next screen
        context.go('/contract/pre-enroll');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving signature: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Online Contract',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/application/machine'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign Your Name. Please sign your name in the area below. Signature supports landscape. Your signature indicates that you understand and agree to the terms of the agreement.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // Signature Pad
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.white,
                  ),
                  if (!_hasSignature)
                    const Center(
                      child: Text(
                        'Tap here to sign',
                        style: TextStyle(color: AppTheme.textHint),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Signature Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _hasSignature ? _undoSignature : null,
                  child: const Text('Undo'),
                ),
                TextButton(
                  onPressed: _hasSignature ? _clearSignature : null,
                  child: const Text('Clear'),
                ),
              ],
            ),

            // Signature Status
            if (_hasSignature) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Signature captured successfully',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSignature,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

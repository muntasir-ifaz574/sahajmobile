import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/application_provider.dart';
import '../../../shared/models/application_model.dart';

class MachineInfoScreen extends ConsumerStatefulWidget {
  const MachineInfoScreen({super.key});

  @override
  ConsumerState<MachineInfoScreen> createState() => _MachineInfoScreenState();
}

class _MachineInfoScreenState extends ConsumerState<MachineInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _imei1Controller = TextEditingController();
  final TextEditingController _imei2Controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // Delay the data loading to avoid modifying providers during initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  @override
  void dispose() {
    _imei1Controller.dispose();
    _imei2Controller.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final machineInfo = ref.read(machineInfoProvider);
    if (machineInfo != null) {
      _imei1Controller.text = machineInfo.imei1;
      _imei2Controller.text = machineInfo.imei2;
    }
  }

  Future<void> _scanIMEI() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isScanning = true;
        });

        final inputImage = InputImage.fromFilePath(image.path);
        final textRecognizer = TextRecognizer();
        final RecognizedText recognizedText = await textRecognizer.processImage(
          inputImage,
        );

        String extractedText = recognizedText.text;

        // Extract IMEI numbers from the scanned text
        List<String> imeiNumbers = _extractIMEINumbers(extractedText);

        if (imeiNumbers.isNotEmpty) {
          if (imeiNumbers.length >= 1) {
            _imei1Controller.text = imeiNumbers[0];
          }
          if (imeiNumbers.length >= 2) {
            _imei2Controller.text = imeiNumbers[1];
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${imeiNumbers.length} IMEI number(s)'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No IMEI numbers found in the image. Please try again or enter manually.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }

        await textRecognizer.close();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  List<String> _extractIMEINumbers(String text) {
    // IMEI numbers are typically 15 digits long
    RegExp imeiRegex = RegExp(r'\b\d{15}\b');
    List<String> matches = imeiRegex
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();

    // Remove duplicates while preserving order
    List<String> uniqueImeis = [];
    for (String imei in matches) {
      if (!uniqueImeis.contains(imei)) {
        uniqueImeis.add(imei);
      }
    }

    return uniqueImeis;
  }

  bool _validateIMEI(String imei) {
    if (imei.length != 15) return false;

    // Luhn algorithm for IMEI validation
    int sum = 0;
    bool alternate = false;

    for (int i = imei.length - 1; i >= 0; i--) {
      int digit = int.parse(imei[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Machine Information',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/application/guarantor'),
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
            // Scan IMEI Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.camera_alt,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan IMEI Numbers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Take a photo of the device containing IMEI#, serial# and model information',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _scanIMEI,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.camera_alt),
                      label: Text(_isScanning ? 'Scanning...' : 'Scan IMEI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Divider with "OR" text
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 24),

            // Manual Entry Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textSecondary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.edit,
                        color: AppTheme.textPrimary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Manual Entry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter IMEI numbers manually',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _imei1Controller,
                    keyboardType: TextInputType.number,
                    maxLength: 15,
                    decoration: InputDecoration(
                      labelText: 'IMEI 1',
                      hintText: 'Enter 15-digit IMEI number',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.textSecondary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'IMEI 1 is required';
                      }
                      if (value.length != 15) {
                        return 'IMEI must be 15 digits';
                      }
                      if (!_validateIMEI(value)) {
                        return 'Invalid IMEI number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _imei2Controller,
                    keyboardType: TextInputType.number,
                    maxLength: 15,
                    decoration: InputDecoration(
                      labelText: 'IMEI 2 (Optional)',
                      hintText: 'Enter 15-digit IMEI number',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.textSecondary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length != 15) {
                          return 'IMEI must be 15 digits';
                        }
                        if (!_validateIMEI(value)) {
                          return 'Invalid IMEI number';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Save IMEI data to provider
                    final machineInfo = MachineInfo(
                      imei1: _imei1Controller.text.trim(),
                      imei2: _imei2Controller.text.trim(),
                    );

                    ref
                        .read(applicationDataProvider.notifier)
                        .setMachineInfo(machineInfo);

                    // Navigate to next screen
                    context.go('/contract/online');
                  }
                },
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

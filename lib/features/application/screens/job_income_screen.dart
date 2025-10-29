import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/providers/application_provider.dart';

class JobIncomeScreen extends ConsumerStatefulWidget {
  const JobIncomeScreen({super.key});

  @override
  ConsumerState<JobIncomeScreen> createState() => _JobIncomeScreenState();
}

class _JobIncomeScreenState extends ConsumerState<JobIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _occupationController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _certifierNameController = TextEditingController();
  final _certifierMobileController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();

  File? _frontWorkIdImage;
  File? _backWorkIdImage;
  File? _workCertifierFile;

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
    _occupationController.dispose();
    _companyNameController.dispose();
    _certifierNameController.dispose();
    _certifierMobileController.dispose();
    _monthlyIncomeController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final jobInfo = ref.read(jobInfoProvider);
    if (jobInfo != null) {
      _occupationController.text = jobInfo.occupation;
      _companyNameController.text = jobInfo.companyName;
      _certifierNameController.text = jobInfo.certifierName;
      _certifierMobileController.text = jobInfo.certifierPhone;
      _monthlyIncomeController.text = jobInfo.monthlyIncome.toString();

      if (jobInfo.workIdFrontImage != null) {
        _frontWorkIdImage = File(jobInfo.workIdFrontImage!);
      }
      if (jobInfo.workIdBackImage != null) {
        _backWorkIdImage = File(jobInfo.workIdBackImage!);
      }
      if (jobInfo.workCertifier.isNotEmpty) {
        _workCertifierFile = File(jobInfo.workCertifier);
      }
    }
  }

  void _saveJobInfo() {
    final jobInfo = JobInfo(
      occupation: _occupationController.text.trim(),
      companyName: _companyNameController.text.trim(),
      workCertifier: _workCertifierFile?.path ?? '',
      certifierName: _certifierNameController.text.trim(),
      certifierPhone: _certifierMobileController.text.trim(),
      monthlyIncome: double.tryParse(_monthlyIncomeController.text) ?? 0.0,
      workIdFrontImage: _frontWorkIdImage?.path,
      workIdBackImage: _backWorkIdImage?.path,
    );

    ref.read(applicationDataProvider.notifier).setJobInfo(jobInfo);
  }

  Future<void> _pickWorkCertifierFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _workCertifierFile = File(image.path);
      });
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
          'Job and Income Information',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/application/address'),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Occupation Text Field
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  hintText: 'Please enter your occupation',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your occupation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Company Name
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  hintText: 'Please enter your company name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your company name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Work Certifier File Upload
              const Text(
                'Work Certifier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickWorkCertifierFile,
                      icon: Icon(
                        _workCertifierFile != null
                            ? Icons.check
                            : Icons.upload_file,
                      ),
                      label: Text(
                        _workCertifierFile != null
                            ? 'File Selected ✓'
                            : 'Upload File',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _workCertifierFile != null
                            ? Colors.green
                            : AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                    ),
                    if (_workCertifierFile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Selected: ${_workCertifierFile!.path.split('/').last}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    const Text(
                      'Supported formats: JPG, JPEG, PNG',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Certifier's Full Name
              TextFormField(
                controller: _certifierNameController,
                decoration: const InputDecoration(
                  labelText: 'Certifier\'s Full Name',
                  hintText: 'Enter certifier\'s full name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter certifier\'s full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Certifier's Mobile Number
              TextFormField(
                controller: _certifierMobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Certifier\'s Mobile Number',
                  hintText: '+880 phone number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter certifier\'s mobile number';
                  }
                  if (!RegExp(r'^\+880[0-9]{10}$').hasMatch(value)) {
                    return 'Please enter a valid Bangladesh mobile number (+880xxxxxxxxxx)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Monthly Income Amount
              TextFormField(
                controller: _monthlyIncomeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Income Amount',
                  hintText: 'Please enter your monthly income',
                  border: OutlineInputBorder(),
                  prefixText: '৳ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your monthly income';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _saveJobInfo();
                      context.go('/application/guarantor');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/providers/application_provider.dart';
import '../../../shared/services/bkash_statement_ocr_service.dart';
import '../../../shared/providers/nid_provider.dart';

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
  final _bkashBalanceController = TextEditingController();

  File? _frontWorkIdImage;
  File? _backWorkIdImage;
  File? _workCertifierFile;
  File? _bankStatementFile;
  File? _bkashStatementFile;
  String? _bkashAccountName;
  String? _bkashAccountNumber;
  String? _bkashStatementTenure;
  final List<String> _bkashTenureOptions = const ['3', '6', '9', '12'];

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
    _bkashBalanceController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final jobInfo = ref.read(jobInfoProvider);
    final appState = ref.read(applicationDataProvider);

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

    // Load statement files from application state
    if (appState.bankStatementPath != null) {
      _bankStatementFile = File(appState.bankStatementPath!);
    }
    if (appState.bkashStatementPath != null) {
      _bkashStatementFile = File(appState.bkashStatementPath!);
    }
    if (appState.bkashAccountName != null &&
        appState.bkashAccountName!.isNotEmpty) {
      _bkashAccountName = appState.bkashAccountName;
    }
    if (appState.bkashAccountNumber != null &&
        appState.bkashAccountNumber!.isNotEmpty) {
      _bkashAccountNumber = appState.bkashAccountNumber;
    }
    if (appState.bkashStatementTenure != null &&
        appState.bkashStatementTenure!.isNotEmpty) {
      _bkashStatementTenure = appState.bkashStatementTenure;
    }
    if (appState.bkashStatementBalance != null &&
        appState.bkashStatementBalance!.isNotEmpty) {
      _bkashBalanceController.text = appState.bkashStatementBalance!;
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

    // Save statement paths to application provider
    final applicationNotifier = ref.read(applicationDataProvider.notifier);
    applicationNotifier.setBankStatementPath(_bankStatementFile?.path);
    applicationNotifier.setBkashStatementPath(_bkashStatementFile?.path);
    if (_bkashStatementFile != null) {
      applicationNotifier.setBkashAccountInfo(
        name: _bkashAccountName ?? '',
        number: _bkashAccountNumber ?? '',
      );
      applicationNotifier.setBkashStatementDetails(
        tenure: _bkashStatementTenure ?? '',
        balance: _bkashBalanceController.text.trim(),
      );
    } else {
      applicationNotifier.setBkashAccountInfo(name: '', number: '');
      applicationNotifier.setBkashStatementDetails(tenure: '', balance: '');
    }
  }

  Future<void> _pickFrontJobIdImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _frontWorkIdImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking front image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _captureFrontJobIdImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _frontWorkIdImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing front image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickBackJobIdImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _backWorkIdImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking back image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _captureBackJobIdImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _backWorkIdImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing back image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Methods for Bank Statement
  Future<void> _pickBankStatementImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _bankStatementFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _captureBankStatementImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          _bankStatementFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickBankStatementPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
        withReadStream: true,
        allowMultiple: false,
        dialogTitle: 'Select Bank Statement PDF',
      );

      if (result != null && result.files.isNotEmpty) {
        final selected = result.files.single;
        final ext = (selected.extension ?? '').toLowerCase();
        if (ext != 'pdf') {
          _showSnackBar('Only PDF files are allowed.');
          return;
        }

        String? effectivePath = selected.path;
        if (effectivePath == null) {
          final dir = await getTemporaryDirectory();
          final fileName = selected.name.isNotEmpty
              ? p.setExtension(selected.name, '.pdf')
              : 'bank_statement_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final tempPath = p.join(dir.path, fileName);
          final outFile = File(tempPath);
          if (selected.bytes != null) {
            await outFile.writeAsBytes(selected.bytes!, flush: true);
            effectivePath = tempPath;
          } else if (selected.readStream != null) {
            final sink = outFile.openWrite();
            await selected.readStream!.pipe(sink);
            await sink.close();
            effectivePath = tempPath;
          }
        }

        if (effectivePath == null) {
          _showSnackBar('Could not access selected PDF', isError: true);
          return;
        }

        setState(() {
          _bankStatementFile = File(effectivePath!);
        });
        _showSnackBar('Bank statement PDF selected!');
      } else {
        _showSnackBar('No file selected');
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  // Methods for Bkash Statement
  Future<void> _pickBkashStatementImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _bkashStatementFile = File(image.path);
        });
        await _runBkashOcr(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _captureBkashStatementImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          _bkashStatementFile = File(image.path);
        });
        await _runBkashOcr(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickBkashStatementPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
        withReadStream: true,
        allowMultiple: false,
        dialogTitle: 'Select PDF File',
      );

      if (result != null && result.files.isNotEmpty) {
        final selected = result.files.single;
        final ext = (selected.extension ?? '').toLowerCase();
        if (ext != 'pdf') {
          _showSnackBar('Only PDF files are allowed.');
          return;
        }

        String? effectivePath = selected.path;
        if (effectivePath == null) {
          final dir = await getTemporaryDirectory();
          final fileName = selected.name.isNotEmpty
              ? p.setExtension(selected.name, '.pdf')
              : 'bkash_statement_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final tempPath = p.join(dir.path, fileName);
          final outFile = File(tempPath);
          if (selected.bytes != null) {
            await outFile.writeAsBytes(selected.bytes!, flush: true);
            effectivePath = tempPath;
          } else if (selected.readStream != null) {
            final sink = outFile.openWrite();
            await selected.readStream!.pipe(sink);
            await sink.close();
            effectivePath = tempPath;
          }
        }

        if (effectivePath == null) {
          _showSnackBar('Could not access selected PDF', isError: true);
          return;
        }

        setState(() {
          _bkashStatementFile = File(effectivePath!);
        });
        await _runBkashOcr(effectivePath);
        _showSnackBar('PDF selected successfully!');
      } else {
        _showSnackBar('No file selected');
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _runBkashOcr(String path) async {
    try {
      final info = await BkashStatementOcrService.extract(path);
      setState(() {
        _bkashAccountName = info.accountName.isNotEmpty
            ? info.accountName
            : null;
        _bkashAccountNumber = info.accountNumber.isNotEmpty
            ? info.accountNumber
            : null;
      });
      if (mounted &&
          (info.accountName.isNotEmpty || info.accountNumber.isNotEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'bKash parsed: ${info.accountName.isNotEmpty ? info.accountName : 'Name N/A'}'
              ' • ${info.accountNumber.isNotEmpty ? info.accountNumber : 'Number N/A'}',
            ),
          ),
        );
      }
    } catch (e) {
      // Silently ignore OCR errors but inform user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not read bKash statement: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Helper method to build statement upload section
  Widget _buildStatementSection({
    required String title,
    required File? file,
    required VoidCallback onPickImage,
    required VoidCallback onCaptureImage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
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
            border: Border.all(
              color: file != null ? Colors.green : Colors.grey.shade300,
              width: file != null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: file != null ? Colors.green.shade50 : Colors.white,
          ),
          child: Column(
            children: [
              if (file != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: ${file.path.split('/').last}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.red,
                      onPressed: () {
                        setState(() {
                          if (title.contains('Bank')) {
                            _bankStatementFile = null;
                          } else {
                            _bkashStatementFile = null;
                            _bkashAccountName = null;
                            _bkashAccountNumber = null;
                            _bkashStatementTenure = null;
                            _bkashBalanceController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  const SizedBox(width: 8),
                  if (title.contains('Bkash') || title.contains('Bank')) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: title.contains('Bkash')
                            ? _pickBkashStatementPdf
                            : _pickBankStatementPdf,
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('Upload PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCaptureImage,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Capture'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title.contains('Bkash')
                    ? 'Supported formats: JPG, JPEG, PNG, PDF'
                    : title.contains('Bank')
                    ? 'Supported formats: JPG, JPEG, PNG, PDF'
                    : 'Supported formats: JPG, JPEG, PNG',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
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

              // Job ID Front
              const Text(
                'Job ID Front',
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
                  border: Border.all(
                    color: _frontWorkIdImage != null
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: _frontWorkIdImage != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _frontWorkIdImage != null
                      ? Colors.green.shade50
                      : Colors.white,
                ),
                child: Column(
                  children: [
                    if (_frontWorkIdImage != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected: ${_frontWorkIdImage!.path.split('/').last}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: Colors.red,
                            onPressed: () {
                              setState(() {
                                _frontWorkIdImage = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickFrontJobIdImage,
                            icon: const Icon(Icons.image, size: 18),
                            label: const Text('Upload Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _captureFrontJobIdImage,
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text('Capture'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Supported formats: JPG, JPEG, PNG',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Job ID Back
              const Text(
                'Job ID Back',
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
                  border: Border.all(
                    color: _backWorkIdImage != null
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: _backWorkIdImage != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _backWorkIdImage != null
                      ? Colors.green.shade50
                      : Colors.white,
                ),
                child: Column(
                  children: [
                    if (_backWorkIdImage != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected: ${_backWorkIdImage!.path.split('/').last}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: Colors.red,
                            onPressed: () {
                              setState(() {
                                _backWorkIdImage = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickBackJobIdImage,
                            icon: const Icon(Icons.image, size: 18),
                            label: const Text('Upload Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _captureBackJobIdImage,
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text('Capture'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Supported formats: JPG, JPEG, PNG',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
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
                  hintText: '01XXXXXXXXX',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter certifier\'s mobile number';
                  }
                  if (!RegExp(r'^01[0-9]{9}$').hasMatch(value)) {
                    return 'Please enter a valid 11-digit mobile number starting with 01';
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
              const SizedBox(height: 24),

              // Bank Statement Section
              _buildStatementSection(
                title: 'Bank Statement',
                file: _bankStatementFile,
                onPickImage: _pickBankStatementImage,
                onCaptureImage: _captureBankStatementImage,
              ),
              const SizedBox(height: 16),

              // Bkash Statement Section
              _buildStatementSection(
                title: 'Bkash Statement',
                file: _bkashStatementFile,
                onPickImage: _pickBkashStatementImage,
                onCaptureImage: _captureBkashStatementImage,
              ),
              const SizedBox(height: 8),
              if (_bkashStatementFile != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'bKash Details (auto-filled from statement)',
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
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bkash Account Name',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey.shade50,
                        ),
                        child: Text(
                          _bkashAccountName?.isNotEmpty == true
                              ? _bkashAccountName!
                              : 'Not detected',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Bkash Account Number',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey.shade50,
                        ),
                        child: Text(
                          _bkashAccountNumber?.isNotEmpty == true
                              ? _bkashAccountNumber!
                              : 'Not detected',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _bkashStatementTenure,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'bKash Statement Tenure (months)',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select tenure'),
                        items: _bkashTenureOptions
                            .map(
                              (tenure) => DropdownMenuItem<String>(
                                value: tenure,
                                child: Text('$tenure months'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _bkashStatementTenure = value;
                          });
                        },
                        validator: (value) {
                          if (_bkashStatementFile == null) return null;
                          if (value == null || value.isEmpty) {
                            return 'Please select bKash statement tenure';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bkashBalanceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'bKash Statement Balance',
                          hintText: 'Enter current balance',
                          border: OutlineInputBorder(),
                          prefixText: '৳ ',
                        ),
                        validator: (value) {
                          if (_bkashStatementFile == null) return null;
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Please enter bKash statement balance';
                          }
                          if (double.tryParse(trimmed) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                // const SizedBox(height: 8),
              ],

              // Validation message for statements
              // if (_bankStatementFile == null && _bkashStatementFile == null)
              //   Container(
              //     padding: const EdgeInsets.all(12),
              //     decoration: BoxDecoration(
              //       color: Colors.orange.shade50,
              //       borderRadius: BorderRadius.circular(8),
              //       border: Border.all(color: Colors.orange.shade200),
              //     ),
              //     child: Row(
              //       children: [
              //         Icon(
              //           Icons.info_outline,
              //           color: Colors.orange.shade700,
              //           size: 20,
              //         ),
              //         const SizedBox(width: 8),
              //         Expanded(
              //           child: Text(
              //             'At least one statement (Bank or Bkash) is required',
              //             style: TextStyle(
              //               fontSize: 12,
              //               color: Colors.orange.shade700,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              const SizedBox(height: 24),

              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Validate form
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    // Validate that at least one statement is selected
                    // if (_bankStatementFile == null &&
                    //     _bkashStatementFile == null) {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text(
                    //         'Please upload at least one statement (Bank or Bkash)',
                    //       ),
                    //       backgroundColor: Colors.red,
                    //     ),
                    //   );
                    //   return;
                    // }

                    // if (_bkashStatementFile != null) {
                    //   final contactNumberRaw =
                    //       ref.read(nidProvider).contactNumber ?? '';
                    //   final contactNumber = contactNumberRaw.replaceAll(
                    //     RegExp(r'\D'),
                    //     '',
                    //   );
                    //   final bkashNumber = (_bkashAccountNumber ?? '')
                    //       .replaceAll(RegExp(r'\D'), '');
                    //
                    //   if (contactNumber.isEmpty ||
                    //       bkashNumber.isEmpty ||
                    //       contactNumber != bkashNumber) {
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(
                    //         duration: Duration(seconds: 5),
                    //         content: Text(
                    //           'Contact number and bKash account number must be the same.',
                    //         ),
                    //         backgroundColor: Colors.red,
                    //       ),
                    //     );
                    //     return;
                    //   }
                    // }

                    _saveJobInfo();
                    context.go('/application/guarantor');
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/nid_ocr_service.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/providers/application_provider.dart';

class GuarantorInfoScreen extends ConsumerStatefulWidget {
  const GuarantorInfoScreen({super.key});

  @override
  ConsumerState<GuarantorInfoScreen> createState() =>
      _GuarantorInfoScreenState();
}

class _GuarantorInfoScreenState extends ConsumerState<GuarantorInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nidController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _presentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();

  String? _maritalStatus;
  String? _relationship;
  DateTime? _selectedDate;
  String? _frontImagePath;
  String? _backImagePath;
  bool _isProcessing = false;
  String? _errorMessage;

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
    _nidController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _presentAddressController.dispose();
    _permanentAddressController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final guarantorInfo = ref.read(guarantorInfoProvider);
    if (guarantorInfo != null) {
      setState(() {
        _nidController.text = guarantorInfo.nidNumber;
        _nameController.text = guarantorInfo.fullName;
        _phoneController.text = guarantorInfo.phoneNumber;
        _dateController.text = DateFormat(
          'd MMM yyyy',
        ).format(guarantorInfo.dateOfBirth);
        _selectedDate = guarantorInfo.dateOfBirth;
        _relationship = guarantorInfo.relationship;
        _maritalStatus = guarantorInfo.maritalStatus;
        _frontImagePath = guarantorInfo.nidFrontImage;
        _backImagePath = guarantorInfo.nidBackImage;
        _presentAddressController.text = guarantorInfo.presentAddress;
        _permanentAddressController.text = guarantorInfo.permanentAddress;
      });
    }
  }

  String? _saveGuarantorInfo() {
    // Validate all required fields are present
    if (_maritalStatus == null || _maritalStatus!.isEmpty) {
      return 'Please select Marital Status';
    }

    if (_relationship == null || _relationship!.isEmpty) {
      return 'Please select Guarantor Relationship';
    }

    // If _selectedDate is null but dateController has text, try to parse it
    DateTime? dateToUse = _selectedDate;
    if (dateToUse == null && _dateController.text.isNotEmpty) {
      try {
        // Try parsing the formatted date (e.g., "18 Feb 1998")
        dateToUse = DateFormat('d MMM yyyy').parse(_dateController.text.trim());
      } catch (e) {
        // If that fails, try other formats
        try {
          dateToUse = DateTime.parse(_dateController.text.trim());
        } catch (e2) {
          // Try DD/MM/YYYY format
          final datePattern = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})');
          final match = datePattern.firstMatch(_dateController.text.trim());
          if (match != null) {
            try {
              final day = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              final year = int.parse(match.group(3)!);
              dateToUse = DateTime(year, month, day);
            } catch (e3) {
              // Still null
            }
          }
        }
      }

      // If we successfully parsed, update _selectedDate for next time
      if (dateToUse != null) {
        setState(() {
          _selectedDate = dateToUse;
        });
      }
    }

    if (dateToUse == null) {
      return 'Please select Date of Birth';
    }

    final nidNumber = _nidController.text.trim();
    final fullName = _nameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final presentAddress = _presentAddressController.text.trim();
    final permanentAddress = _permanentAddressController.text.trim();

    // Validate text fields are not empty
    if (nidNumber.isEmpty) {
      return 'Please enter Guarantor\'s NID Number';
    }

    if (fullName.isEmpty) {
      return 'Please enter Guarantor\'s Full Name';
    }

    if (phoneNumber.isEmpty) {
      return 'Please enter Guarantor\'s Mobile Number';
    }

    // Validate NID number length
    if (nidNumber.length < 10 || nidNumber.length > 17) {
      return 'NID number must be 10-17 digits';
    }

    // Validate name length
    if (fullName.length < 2) {
      return 'Name must be at least 2 characters';
    }

    // Validate phone number length
    if (phoneNumber.length < 11) {
      return 'Phone number must be at least 11 digits';
    }

    if (presentAddress.isEmpty) {
      return 'Please enter Guarantor\'s Present Address';
    }

    if (permanentAddress.isEmpty) {
      return 'Please enter Guarantor\'s Permanent Address';
    }

    try {
      // Ensure marital status is not empty and trimmed
      final maritalStatusValue = _maritalStatus?.trim() ?? '';
      if (maritalStatusValue.isEmpty) {
        return 'Please select Marital Status';
      }

      // Ensure relationship is not empty and trimmed
      final relationshipValue = _relationship?.trim() ?? '';
      if (relationshipValue.isEmpty) {
        return 'Please select Guarantor Relationship';
      }

      // dateToUse is guaranteed to be non-null here due to validation above
      final guarantorInfo = GuarantorInfo(
        relationship: relationshipValue,
        nidNumber: nidNumber,
        fullName: fullName,
        dateOfBirth: dateToUse,
        phoneNumber: phoneNumber,
        maritalStatus: maritalStatusValue,
        presentAddress: presentAddress,
        permanentAddress: permanentAddress,
        nidFrontImage: _frontImagePath,
        nidBackImage: _backImagePath,
      );

      ref
          .read(applicationDataProvider.notifier)
          .setGuarantorInfo(guarantorInfo);

      // Clear any error message on successful save
      setState(() {
        _errorMessage = null;
      });

      return null; // null means success
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save guarantor information: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return 'Failed to save: $e';
    }
  }

  String _formatDateFromOCR(String dateString) {
    if (dateString.isEmpty) return '';

    try {
      // Try to parse the date and format it as "18 Feb 1998"
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('d MMM yyyy').format(parsedDate);
    } catch (e) {
      // If parsing fails, try to extract date from common formats
      final datePattern = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})');
      final match = datePattern.firstMatch(dateString);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        final parsedDate = DateTime(year, month, day);
        return DateFormat('d MMM yyyy').format(parsedDate);
      } else {
        // If all parsing fails, use the original value
        return dateString;
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(
            const Duration(days: 365 * 25),
          ), // Default to 25 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('d MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage(bool isFront) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          if (isFront) {
            _frontImagePath = image.path;
          } else {
            _backImagePath = image.path;
          }
          _errorMessage = null;
        });

        // Process images if both are available
        if (_frontImagePath != null && _backImagePath != null) {
          await _processGuarantorNid();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _processGuarantorNid() async {
    if (_frontImagePath == null || _backImagePath == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Extract text from both images
      final frontText = await NidOcrService.extractTextFromImage(
        _frontImagePath!,
      );
      final backText = await NidOcrService.extractTextFromImage(
        _backImagePath!,
      );

      // Combine both texts for better parsing
      final combinedText = '$frontText\n$backText';

      // Parse guarantor NID information
      final guarantorInfo = await NidOcrService.parseNidInfo(combinedText);

      // Auto-populate form fields
      setState(() {
        _nidController.text = guarantorInfo.guarantorNidNumber.isNotEmpty
            ? guarantorInfo.guarantorNidNumber
            : guarantorInfo.nidNumber;
        _nameController.text = guarantorInfo.guarantorName.isNotEmpty
            ? guarantorInfo.guarantorName
            : guarantorInfo.fullName;
        _phoneController.text = guarantorInfo.guarantorPhone;

        // Handle date of birth
        if (guarantorInfo.dateOfBirth.isNotEmpty) {
          final formattedDate = _formatDateFromOCR(guarantorInfo.dateOfBirth);
          _dateController.text = formattedDate;

          // Try to parse the date for the date picker
          DateTime? parsedDate;

          // First try: Standard ISO format
          try {
            parsedDate = DateTime.parse(guarantorInfo.dateOfBirth);
          } catch (e) {
            // Second try: DD/MM/YYYY or DD-MM-YYYY format
            final datePattern1 = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})');
            final match1 = datePattern1.firstMatch(guarantorInfo.dateOfBirth);
            if (match1 != null) {
              try {
                final day = int.parse(match1.group(1)!);
                final month = int.parse(match1.group(2)!);
                final year = int.parse(match1.group(3)!);
                parsedDate = DateTime(year, month, day);
              } catch (e) {
                // Continue to next attempt
              }
            }

            // Third try: Try parsing the formatted date text (e.g., "18 Feb 1998")
            if (parsedDate == null && formattedDate.isNotEmpty) {
              try {
                parsedDate = DateFormat('d MMM yyyy').parse(formattedDate);
              } catch (e) {
                // Continue to next attempt
              }
            }

            // Fourth try: Try MM/DD/YYYY format (alternative order)
            if (parsedDate == null) {
              final datePattern2 = RegExp(r'(\d{2})[/-](\d{2})[/-](\d{4})');
              final match2 = datePattern2.firstMatch(guarantorInfo.dateOfBirth);
              if (match2 != null) {
                try {
                  final month = int.parse(match2.group(1)!);
                  final day = int.parse(match2.group(2)!);
                  final year = int.parse(match2.group(3)!);
                  parsedDate = DateTime(year, month, day);
                } catch (e) {
                  // Continue to next attempt
                }
              }
            }

            // Fifth try: Try to extract date from any numeric format
            if (parsedDate == null) {
              final allNumbers = RegExp(
                r'\d+',
              ).allMatches(guarantorInfo.dateOfBirth);
              if (allNumbers.length >= 3) {
                final numbers = allNumbers
                    .map((m) => int.parse(m.group(0)!))
                    .toList();
                try {
                  // Try different interpretations: YYYY-MM-DD, DD-MM-YYYY, etc.
                  if (numbers[0] > 31 && numbers.length >= 3) {
                    // First number is year
                    parsedDate = DateTime(numbers[0], numbers[1], numbers[2]);
                  } else if (numbers.length >= 3) {
                    // Try DD-MM-YYYY or MM-DD-YYYY
                    if (numbers[1] <= 12) {
                      parsedDate = DateTime(numbers[2], numbers[1], numbers[0]);
                    } else {
                      parsedDate = DateTime(numbers[2], numbers[0], numbers[1]);
                    }
                  }
                } catch (e) {
                  // If all parsing fails, we'll leave it null and user can select manually
                }
              }
            }
          }

          // Set the parsed date if successful
          if (parsedDate != null) {
            _selectedDate = parsedDate;
          }
        }

        _isProcessing = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guarantor information extracted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to process guarantor NID: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing NID: $e'),
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
          'Guarantor Information',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/application/job-income'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Marital Status Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Marital status'),
                value: _maritalStatus,
                items: const [
                  DropdownMenuItem(
                    value: 'Unmarried',
                    child: Text('Unmarried'),
                  ),
                  DropdownMenuItem(value: 'Married', child: Text('Married')),
                  DropdownMenuItem(value: 'Divorced', child: Text('Divorced')),
                  DropdownMenuItem(value: 'Widowed', child: Text('Widowed')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _maritalStatus = value.trim();
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select marital status';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Relationship Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Guarantor Relationship',
                ),
                value: _relationship,
                items: const [
                  DropdownMenuItem(value: 'Father', child: Text('Father')),
                  DropdownMenuItem(value: 'Mother', child: Text('Mother')),
                  DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                  DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                  DropdownMenuItem(value: 'Cousin', child: Text('Cousin')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _relationship = value.trim();
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select relationship';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // NID Card Upload Section
              const Text(
                'Guarantor\'s NID Card',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _pickImage(true),
                      icon: _frontImagePath != null
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.add),
                      label: Text(
                        _frontImagePath != null ? 'Front ✓' : 'Front',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _frontImagePath != null
                            ? Colors.green.shade50
                            : AppTheme.primaryColor,
                        foregroundColor: _frontImagePath != null
                            ? Colors.green
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _pickImage(false),
                      icon: _backImagePath != null
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.add),
                      label: Text(_backImagePath != null ? 'Back ✓' : 'Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _backImagePath != null
                            ? Colors.green.shade50
                            : AppTheme.primaryColor,
                        foregroundColor: _backImagePath != null
                            ? Colors.green
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // Processing indicator
              if (_isProcessing) ...[
                const SizedBox(height: 16),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Processing guarantor NID...'),
                    ],
                  ),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // NID Number Field
              TextFormField(
                controller: _nidController,
                decoration: const InputDecoration(
                  labelText: 'Guarantor\'s NID No.',
                  hintText: '10-13 or 17 digits NID No',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter guarantor\'s NID number';
                  }
                  if (value.length < 10 || value.length > 17) {
                    return 'NID number must be 10-17 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Guarantor\'s Full Name',
                  hintText: 'Enter last and first name is enough',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter guarantor\'s name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth Field
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Guarantor\'s Date of Birth',
                  hintText: 'Select guarantor\'s Date of Birth',
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: _selectDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select guarantor\'s date of birth';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Guarantor\'s Mobile Number',
                  hintText: '+880 Please enter mobile number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter guarantor\'s mobile number';
                  }
                  if (value.length < 11) {
                    return 'Mobile number must be at least 11 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _presentAddressController,
                decoration: const InputDecoration(
                  labelText: 'Guarantor\'s Present Address',
                  hintText: 'Enter present residential address',
                ),
                minLines: 2,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter guarantor\'s present address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _permanentAddressController,
                decoration: const InputDecoration(
                  labelText: 'Guarantor\'s Permanent Address',
                  hintText: 'Enter permanent residential address',
                ),
                minLines: 2,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter guarantor\'s permanent address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Navigation Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/application/job-income'),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Save the information - returns null if successful, error message if failed
                          final errorMessage = _saveGuarantorInfo();

                          if (errorMessage == null) {
                            // Navigate to next screen on successful save
                            context.go('/application/machine');
                          } else {
                            // Show specific error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
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
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/nid_provider.dart';
import '../../../shared/providers/application_provider.dart';
import '../../../shared/models/application_model.dart';

class ConfirmIdInfoScreen extends ConsumerWidget {
  const ConfirmIdInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nidState = ref.watch(nidProvider);
    final nidInfo = nidState.nidInfo;
    final isLoading = nidState.isLoading;
    final error = nidState.error;

    // If no NID info is available, show error or redirect back
    if (nidInfo == null && !isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Confirm Information',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => context.go('/verification/upload-id'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                error ?? 'No NID information found',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/verification/upload-id'),
                child: const Text('Upload ID Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Confirm Information',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/verification/upload-id'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Processing NID card...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NID Information Display
                  if (nidInfo != null) ...[
                    _buildEditableField(
                      ref,
                      'NID No.',
                      nidInfo.nidNumber,
                      'nidNumber',
                    ),
                    _buildEditableField(
                      ref,
                      'Name',
                      nidInfo.fullName,
                      'fullName',
                    ),
                    _buildEditableDateField(
                      ref,
                      'Date of Birth',
                      nidInfo.dateOfBirth,
                    ),
                    const Text(
                      'Age must be between 19 and 54.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                    ),
                    const SizedBox(height: 16),
                    _buildGenderSelection(ref, nidInfo.gender),
                    const SizedBox(height: 16),
                    // Contact Number (editable text field)
                    _buildContactNumberField(ref),
                    const SizedBox(height: 16),
                    // Profile Photo (optional)
                    _buildProfilePhotoField(context, ref),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate contact number is mandatory
                          final contactNumber =
                              ref.read(nidProvider).contactNumber ?? '';
                          if (contactNumber.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contact number is required'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }

                          // Persist personal info into application provider
                          try {
                            final parsedDob = _parseDobToDateTime(
                              nidInfo.dateOfBirth,
                            );
                            final selectedGender =
                                ref.read(nidProvider).selectedGender ??
                                nidInfo.gender;
                            ref
                                .read(applicationDataProvider.notifier)
                                .setPersonalInfo(
                                  PersonalInfo(
                                    nidNumber: nidInfo.nidNumber,
                                    fullName: nidInfo.fullName,
                                    dateOfBirth: parsedDob,
                                    gender: selectedGender,
                                    nidFrontImage: ref
                                        .read(nidProvider)
                                        .frontImagePath,
                                    nidBackImage: ref
                                        .read(nidProvider)
                                        .backImagePath,
                                  ),
                                );
                          } catch (_) {
                            // Fallback: ignore and continue; form will block later if needed
                          }
                          context.go('/application/address');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Next'),
                      ),
                    ),
                  ] else ...[
                    const Center(child: Text('Failed to process NID card')),
                  ],
                ],
              ),
            ),
    );
  }

  DateTime _parseDobToDateTime(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      // Try common formats like dd/MM/yyyy or dd-MM-yyyy
      final match = RegExp(
        r'^(\d{1,2})[\/-](\d{1,2})[\/-](\d{4})',
      ).firstMatch(value);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      }
      // Try format like '18 Feb 1998'
      try {
        return DateFormat('d MMM yyyy').parse(value);
      } catch (_) {
        // Fallback to a safe default if parsing fails
        return DateTime(1990, 1, 1);
      }
    }
  }

  Widget _buildEditableField(
    WidgetRef ref,
    String label,
    String value,
    String fieldType,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _showEditDialog(ref, label, value, fieldType),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isNotEmpty ? value : 'Not detected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: value.isNotEmpty
                            ? AppTheme.textPrimary
                            : AppTheme.textHint,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDateField(WidgetRef ref, String label, String value) {
    String formattedDate = 'Not detected';

    if (value.isNotEmpty) {
      try {
        // Try to parse the date and format it as "18 Feb 1998"
        final parsedDate = DateTime.parse(value);
        formattedDate = DateFormat('d MMM yyyy').format(parsedDate);
      } catch (e) {
        // If parsing fails, try to extract date from common formats
        final datePattern = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})');
        final match = datePattern.firstMatch(value);
        if (match != null) {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final year = int.parse(match.group(3)!);
          final parsedDate = DateTime(year, month, day);
          formattedDate = DateFormat('d MMM yyyy').format(parsedDate);
        } else {
          // If all parsing fails, use the original value
          formattedDate = value;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _showDatePickerDialog(ref, value),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: value.isNotEmpty
                            ? AppTheme.textPrimary
                            : AppTheme.textHint,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    WidgetRef ref,
    String label,
    String currentValue,
    String fieldType,
  ) {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    showDialog(
      context: ref.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $label'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newValue = controller.text.trim();
                if (newValue.isNotEmpty) {
                  switch (fieldType) {
                    case 'nidNumber':
                      ref.read(nidProvider.notifier).updateNidNumber(newValue);
                      break;
                    case 'fullName':
                      ref.read(nidProvider.notifier).updateFullName(newValue);
                      break;
                    case 'contactNumber':
                      ref
                          .read(nidProvider.notifier)
                          .updateContactNumber(newValue);
                      break;
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDatePickerDialog(WidgetRef ref, String currentValue) async {
    DateTime initialDate = DateTime(1990);

    if (currentValue.isNotEmpty) {
      try {
        initialDate = DateTime.parse(currentValue);
      } catch (e) {
        final datePattern = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})');
        final match = datePattern.firstMatch(currentValue);
        if (match != null) {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final year = int.parse(match.group(3)!);
          initialDate = DateTime(year, month, day);
        }
      }
    }

    final DateTime firstDate = DateTime(1950);
    final DateTime lastDate = DateTime.now().subtract(
      const Duration(days: 19 * 365),
    );

    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final DateTime? picked = await showDatePicker(
      context: ref.context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      ref
          .read(nidProvider.notifier)
          .updateDateOfBirth(picked.toIso8601String());
    }
  }

  Widget _buildGenderSelection(WidgetRef ref, String currentGender) {
    final nidState = ref.watch(nidProvider);
    final selectedGender = nidState.selectedGender ?? currentGender;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Radio<String>(
              value: 'Male',
              groupValue: selectedGender,
              onChanged: (value) {
                if (value != null) {
                  ref.read(nidProvider.notifier).updateSelectedGender(value);
                }
              },
              activeColor: AppTheme.primaryColor,
            ),
            const Text('Male'),
            const SizedBox(width: 20),
            Radio<String>(
              value: 'Female',
              groupValue: selectedGender,
              onChanged: (value) {
                if (value != null) {
                  ref.read(nidProvider.notifier).updateSelectedGender(value);
                }
              },
              activeColor: AppTheme.primaryColor,
            ),
            const Text('Female'),
          ],
        ),
      ],
    );
  }

  Widget _buildContactNumberField(WidgetRef ref) {
    return _ContactNumberTextField(ref: ref);
  }

  Widget _buildProfilePhotoField(BuildContext context, WidgetRef ref) {
    final nidState = ref.watch(nidProvider);
    final profilePhotoPath = nidState.profilePhotoPath;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Photo',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showPhotoSourceDialog(context, ref),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: profilePhotoPath != null && profilePhotoPath.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(profilePhotoPath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: AppTheme.errorColor,
                            ),
                          );
                        },
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 32,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to capture photo',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (profilePhotoPath != null && profilePhotoPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showPhotoSourceDialog(context, ref),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Change Photo'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    ref.read(nidProvider.notifier).updateProfilePhoto(null);
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPhotoSourceDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  await _capturePhoto(context, ref, picker, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  await _capturePhoto(
                    context,
                    ref,
                    picker,
                    ImageSource.gallery,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _capturePhoto(
    BuildContext context,
    WidgetRef ref,
    ImagePicker picker,
    ImageSource source,
  ) async {
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        ref.read(nidProvider.notifier).updateProfilePhoto(image.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

// Separate StatefulWidget to manage TextEditingController properly
class _ContactNumberTextField extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _ContactNumberTextField({required this.ref});

  @override
  ConsumerState<_ContactNumberTextField> createState() =>
      _ContactNumberTextFieldState();
}

class _ContactNumberTextFieldState
    extends ConsumerState<_ContactNumberTextField> {
  late TextEditingController _controller;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    final initialValue = ref.read(nidProvider).contactNumber ?? '';
    _controller = TextEditingController(text: initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for external changes (from OCR or other sources)
    final contactNumber = ref.watch(nidProvider).contactNumber ?? '';

    // Only update controller if value changed externally (not from user typing)
    if (!_isUserTyping && _controller.text != contactNumber) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.text = contactNumber;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: contactNumber.length),
          );
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Contact Number',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(fontSize: 14, color: AppTheme.errorColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter contact number',
              hintStyle: TextStyle(fontSize: 14, color: AppTheme.textHint),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            controller: _controller,
            onChanged: (value) {
              _isUserTyping = true;
              ref.read(nidProvider.notifier).updateContactNumber(value);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _isUserTyping = false;
                }
              });
            },
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

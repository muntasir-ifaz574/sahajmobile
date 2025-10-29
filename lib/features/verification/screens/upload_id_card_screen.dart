import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/nid_ocr_service.dart';
import '../../../shared/providers/nid_provider.dart';

class UploadIdCardScreen extends ConsumerStatefulWidget {
  const UploadIdCardScreen({super.key});

  @override
  ConsumerState<UploadIdCardScreen> createState() => _UploadIdCardScreenState();
}

class _UploadIdCardScreenState extends ConsumerState<UploadIdCardScreen> {
  bool isLoading = false;

  Future<void> _captureImage(bool isFront) async {
    try {
      setState(() {
        isLoading = true;
      });

      final imagePath = await NidOcrService.captureImage();

      if (imagePath != null) {
        // Use the NID provider to set the image and trigger OCR
        if (isFront) {
          await ref.read(nidProvider.notifier).setFrontImage(imagePath);
        } else {
          await ref.read(nidProvider.notifier).setBackImage(imagePath);
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${isFront ? 'Front' : 'Back'} image captured successfully',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nidState = ref.watch(nidProvider);
    final isOcrLoading = nidState.isLoading;

    // Listen to OCR errors
    ref.listen(nidErrorProvider, (previous, next) {
      if (next != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR Error: $next'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        ref.read(nidProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Upload ID Card',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/installment/confirm'),
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
            // OCR Status Indicator
            if (isOcrLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Processing OCR...',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Upload Front Side
            _buildUploadSection(
              'Upload Front Side',
              'Upload the front side of your ID card',
              Icons.camera_alt,
              true,
              nidState.frontImagePath,
            ),

            const SizedBox(height: 24),

            // Upload Back Side
            _buildUploadSection(
              'Upload Back Side',
              'Upload the back side of your ID card',
              Icons.camera_alt,
              false,
              nidState.backImagePath,
            ),

            const SizedBox(height: 24),

            // ID Photo Requirements
            _buildRequirementsSection(),

            const SizedBox(height: 40),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (nidState.frontImagePath != null &&
                            nidState.backImagePath != null) &&
                        !isLoading &&
                        !isOcrLoading
                    ? () {
                        context.go('/verification/confirm-info');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (nidState.frontImagePath != null &&
                          nidState.backImagePath != null)
                      ? AppTheme.primaryColor
                      : AppTheme.textHint,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading || isOcrLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        nidState.frontImagePath == null ||
                                nidState.backImagePath == null
                            ? 'Please upload both images'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection(
    String title,
    String description,
    IconData icon,
    bool isFront,
    String? imagePath,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: imagePath != null
              ? AppTheme.successColor
              : AppTheme.borderColor,
          width: imagePath != null ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Image preview or upload icon
          if (imagePath != null)
            Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),

          const SizedBox(height: 16),

          Text(
            description,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Action button - Camera only
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : () => _captureImage(isFront),
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Capture Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          if (imagePath != null) ...[
            const SizedBox(height: 8),
            Text(
              '✓ Image uploaded successfully',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'The ID photo requirements:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        _buildRequirementItem('No Strong Flash', Icons.flash_off),
        _buildRequirementItem('No Incomplete Image', Icons.crop_free),
        _buildRequirementItem('No Blurred Image', Icons.blur_off),
      ],
    );
  }

  Widget _buildRequirementItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

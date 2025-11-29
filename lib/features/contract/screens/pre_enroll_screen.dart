import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/application_provider.dart';
import '../../../shared/models/application_model.dart';

class PreEnrollScreen extends ConsumerStatefulWidget {
  const PreEnrollScreen({super.key});

  @override
  ConsumerState<PreEnrollScreen> createState() => _PreEnrollScreenState();
}

class _PreEnrollScreenState extends ConsumerState<PreEnrollScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch all providers to ensure reactive updates
    final appState = ref.watch(applicationDataProvider);
    final isPersonalDone = ref.watch(isPersonalInfoCompleteProvider);
    final isAddressDone = ref.watch(isAddressInfoCompleteProvider);
    final isJobDone = ref.watch(isJobInfoCompleteProvider);
    final isGuarantorDone = ref.watch(isGuarantorInfoCompleteProvider);
    final guarantorInfo = ref.watch(guarantorInfoProvider);
    final isMachineDone = ref.watch(isMachineInfoCompleteProvider);
    final hasProduct = ref.watch(selectedProductProvider) != null;
    final hasPlan = ref.watch(installmentPlanProvider) != null;
    final productName = ref.watch(productDisplayNameProvider);
    final primaryIMEI = ref.watch(primaryIMEIProvider);
    final secondaryIMEI = ref.watch(secondaryIMEIProvider);
    final paymentSummary = ref.watch(paymentSummaryProvider);

    // Check if we have any data, if not show a message
    final hasData =
        productName != 'No product selected' ||
        primaryIMEI != 'No IMEI available';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pre-Enroll',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/contract/online'),
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
            // Show message if no data is available
            if (!hasData) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Product Information Available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please complete the product selection and machine information steps first.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Missing sections (if any)
            if (!(isPersonalDone &&
                isAddressDone &&
                isJobDone &&
                isGuarantorDone &&
                isMachineDone &&
                hasProduct &&
                hasPlan)) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color.fromARGB(255, 106, 94, 94),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Text(
                          'Incomplete sections',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isPersonalDone)
                      const Text('- Personal information missing'),
                    if (!isAddressDone)
                      const Text('- Address information missing'),
                    if (!isJobDone)
                      const Text('- Job/income information missing'),
                    if (!isGuarantorDone) ...[
                      const Text('- Guarantor information missing:'),
                      ..._getMissingGuarantorFields(guarantorInfo).map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4),
                          child: Text('  • $field'),
                        ),
                      ),
                    ],
                    if (!isMachineDone)
                      const Text('- Machine information missing'),
                    if (!hasProduct) const Text('- Product not selected'),
                    if (!hasPlan) const Text('- Installment plan not set'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Product Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'IMEI Numbers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Primary: $primaryIMEI',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (secondaryIMEI != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Secondary: $secondaryIMEI',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment Summary Card
            if (paymentSummary != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.borderColor.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Term
                    _buildPaymentRow(
                      'Payment Term',
                      '${paymentSummary.paymentTerms} months',
                    ),
                    const SizedBox(height: 8),

                    // Cellphone MRP
                    _buildPaymentRow(
                      'Cellphone MRP',
                      '৳${paymentSummary.orderAmount.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 8),

                    // Customer Down-Payment (percent / amount)
                    _buildPaymentRow(
                      'Customer Down-Payment',
                      '${paymentSummary.downPaymentPercentage.toStringAsFixed(1)}% / ৳${paymentSummary.downPayment.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 8),

                    // Accent summary chip row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(
                          'Payment',
                          paymentSummary.paymentFrequency == 'weekly'
                              ? 'Weekly'
                              : 'Monthly',
                        ),
                        _buildChip(
                          'Installments',
                          '${paymentSummary.paymentTerms}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    appState.isLoading ||
                        !(isPersonalDone &&
                            isAddressDone &&
                            isJobDone &&
                            isGuarantorDone &&
                            isMachineDone &&
                            hasProduct &&
                            hasPlan)
                    ? null
                    : () async {
                        developer.log(
                          'Confirm tapped. Starting submission...',
                          name: 'PreEnrollScreen',
                        );
                        try {
                          developer.log(
                            'Calling submitApplication',
                            name: 'PreEnrollScreen',
                          );
                          final result = await ref
                              .read(applicationDataProvider.notifier)
                              .submitApplication();

                          if (context.mounted) {
                            developer.log(
                              'Submission success. Result: ${result.toString()}',
                              name: 'PreEnrollScreen',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  (result['message']?.toString() ??
                                      'Submitted successfully'),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            developer.log(
                              'Navigating to /contract/activation',
                              name: 'PreEnrollScreen',
                            );
                            context.go('/contract/activation');
                          }
                        } catch (e) {
                          developer.log(
                            'Submission failed: $e',
                            name: 'PreEnrollScreen',
                            level: 1000,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Submission failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: appState.isLoading
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
                    : const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getMissingGuarantorFields(GuarantorInfo? guarantorInfo) {
    final List<String> missing = [];

    if (guarantorInfo == null) {
      return [
        'Relationship',
        'NID Number',
        'Full Name',
        'Date of Birth',
        'Phone Number',
        'Marital Status',
      ];
    }

    if (guarantorInfo.relationship.isEmpty) {
      missing.add('Relationship');
    }
    if (guarantorInfo.nidNumber.isEmpty) {
      missing.add('NID Number');
    }
    if (guarantorInfo.fullName.isEmpty) {
      missing.add('Full Name');
    }
    if (guarantorInfo.phoneNumber.isEmpty) {
      missing.add('Phone Number');
    }
    if (guarantorInfo.maritalStatus.isEmpty) {
      missing.add('Marital Status');
    }

    return missing;
  }
}

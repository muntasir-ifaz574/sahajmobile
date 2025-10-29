import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/application_provider.dart';

class ConfirmInformationScreen extends ConsumerWidget {
  final String? paymentTerm;
  final double? totalPrice;
  final double? downPayment;
  final double? totalOutstanding;
  final double? monthlyPayment;
  final int? months;

  const ConfirmInformationScreen({
    super.key,
    this.paymentTerm,
    this.totalPrice,
    this.downPayment,
    this.totalOutstanding,
    this.monthlyPayment,
    this.months,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get data from provider as fallback
    final selectedProduct = ref.watch(selectedProductProvider);
    final installmentPlan = ref.watch(installmentPlanProvider);

    // Use provider data if parameters are not available
    final displayTotalPrice =
        totalPrice ??
        selectedProduct?.price ??
        installmentPlan?.orderAmount ??
        0.0;
    final displayDownPayment =
        downPayment ?? installmentPlan?.downPayment ?? 0.0;
    final displayTotalOutstanding =
        totalOutstanding ?? installmentPlan?.totalOutstanding ?? 0.0;
    final displayMonthlyPayment =
        monthlyPayment ?? installmentPlan?.monthlyPayment ?? 0.0;
    final displayMonths = months ?? installmentPlan?.paymentTerms ?? 0;

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
          onPressed: () => context.go('/installment/payment-terms'),
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
            // Summary Details
            _buildSummaryDetails(
              displayTotalPrice: displayTotalPrice,
              displayDownPayment: displayDownPayment,
              displayTotalOutstanding: displayTotalOutstanding,
            ),

            const SizedBox(height: 24),

            // Repayment Plan Details
            _buildRepaymentPlanDetails(
              displayMonths: displayMonths,
              displayMonthlyPayment: displayMonthlyPayment,
            ),

            const SizedBox(height: 40),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/verification/upload-id');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
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

  Widget _buildSummaryDetails({
    required double displayTotalPrice,
    required double displayDownPayment,
    required double displayTotalOutstanding,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildDetailRow('Payment Term', paymentTerm ?? '-'),
          _buildDetailRow('Repayment Options', 'By Month'),
          _buildDetailRow(
            'Total Price',
            displayTotalPrice > 0
                ? 'TK ${displayTotalPrice.toStringAsFixed(0)}'
                : '-',
          ),
          _buildDetailRow(
            'Down Payment',
            displayDownPayment > 0
                ? 'TK ${displayDownPayment.toStringAsFixed(0)}'
                : '-',
          ),
          _buildDetailRow(
            'Total Outstanding',
            displayTotalOutstanding > 0
                ? 'TK ${displayTotalOutstanding.toStringAsFixed(0)}'
                : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentPlanDetails({
    required int displayMonths,
    required double displayMonthlyPayment,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Repayment Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayMonths > 0
                ? 'Total $displayMonths terms'
                : 'Repayment terms',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Repayment terms list (show all terms)
          ...List.generate(displayMonths, (index) {
            final dueDate = DateTime.now().add(
              Duration(days: 30 * (index + 1)),
            );
            final monthNames = [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ];
            final formattedDate =
                '${monthNames[dueDate.month - 1]} ${dueDate.day} ${dueDate.year}';
            final termNumber = index + 1;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$formattedDate ${displayMonthlyPayment > 0 ? 'TK ${displayMonthlyPayment.toStringAsFixed(0)}' : ''} $termNumber${_getOrdinalSuffix(termNumber)} term',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

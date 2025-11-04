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
    final displayPaymentFrequency =
        installmentPlan?.paymentFrequency ?? 'monthly';

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
              paymentFrequency: displayPaymentFrequency,
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
    required String paymentFrequency,
  }) {
    // Down payment percent (safe against division by zero)
    final double downPaymentPercent = displayTotalPrice > 0
        ? (displayDownPayment / displayTotalPrice) * 100.0
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.summarize_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Summary Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Term (unchanged)
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Payment Term',
            value: paymentTerm ?? '-',
          ),
          const Divider(height: 24),

          // Repayment Options (unchanged)
          _buildDetailRow(
            icon: Icons.payment_outlined,
            label: 'Repayment Options',
            value: paymentFrequency == 'weekly' ? 'By Week' : 'By Month',
          ),
          const Divider(height: 24),

          // Cellphone MRP
          _buildDetailRow(
            icon: Icons.phone_android_outlined,
            label: 'Cellphone MRP',
            value: displayTotalPrice > 0
                ? 'TK ${displayTotalPrice.toStringAsFixed(0)}'
                : '-',
          ),
          const Divider(height: 24),

          // Customer Down-Payment
          _buildDetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Customer Down-Payment',
            value: displayDownPayment > 0
                ? '${downPaymentPercent.toStringAsFixed(1)}% / TK ${displayDownPayment.toStringAsFixed(0)}'
                : '-',
          ),
          // Intentionally not showing Customer Due and Customer Repayment
        ],
      ),
    );
  }

  Widget _buildRepaymentPlanDetails({
    required int displayMonths,
    required double displayMonthlyPayment,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Repayment Plan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              displayMonths > 0
                  ? 'Total $displayMonths ${displayMonths == 1 ? 'term' : 'terms'}'
                  : 'Repayment terms',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Repayment terms list (show all terms)
          if (displayMonths > 0)
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
                  '${monthNames[dueDate.month - 1]} ${dueDate.day}, ${dueDate.year}';
              final termNumber = index + 1;
              final isLast = index == displayMonths - 1;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              termNumber.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$termNumber${_getOrdinalSuffix(termNumber)} Installment',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (displayMonthlyPayment > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'TK ${displayMonthlyPayment.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.withOpacity(0.1),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    IconData? icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: highlight
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: highlight
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: highlight
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontWeight: highlight ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: highlight ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: highlight ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class InstallmentPlanScreen extends ConsumerStatefulWidget {
  const InstallmentPlanScreen({super.key});

  @override
  ConsumerState<InstallmentPlanScreen> createState() =>
      _InstallmentPlanScreenState();
}

class _InstallmentPlanScreenState extends ConsumerState<InstallmentPlanScreen> {
  double orderAmount = 26299.0;
  double downPaymentPercentage = 15.0;
  int paymentTerms = 9;

  final List<double> downPaymentOptions = [15.0, 20.0, 30.0, 50.0];
  final List<int> paymentTermOptions = [4, 6, 9];

  @override
  Widget build(BuildContext context) {
    final downPayment = orderAmount * (downPaymentPercentage / 100);
    final serviceFeeRate = 0.02; // 2% per month
    final monthlyServiceFee = (orderAmount - downPayment) * serviceFeeRate;
    final monthlyPayment =
        ((orderAmount - downPayment) + (monthlyServiceFee * paymentTerms)) /
        paymentTerms;
    final onSitePayment = orderAmount * 0.18; // 18% on-site payment

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Installment Plan',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/installment/product-selection'),
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
            // Order Amount
            _buildOrderAmount(),

            const SizedBox(height: 24),

            // Installment Product Section
            _buildInstallmentProductSection(),

            const SizedBox(height: 24),

            // Down Payment Section
            _buildDownPaymentSection(downPayment),

            const SizedBox(height: 24),

            // Monthly Payment Section
            _buildMonthlyPaymentSection(),

            const SizedBox(height: 24),

            // Service Fee Rate
            _buildServiceFeeRate(),

            const SizedBox(height: 24),

            // Payment Summary
            _buildPaymentSummary(
              downPayment,
              onSitePayment,
              monthlyPayment,
              monthlyServiceFee,
            ),

            const SizedBox(height: 24),

            // Repayment Plan
            _buildRepaymentPlan(),

            const SizedBox(height: 40),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/installment/confirm');
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

  Widget _buildInstallmentProductSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_cart, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          const Text(
            'Installment Product',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          const Text(
            '1 Product',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderAmount() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Order Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'TK ${orderAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownPaymentSection(double downPayment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Down Payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'TK ${downPayment.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),

        // Down Payment Options
        Row(
          children: downPaymentOptions.map((percentage) {
            final isSelected = downPaymentPercentage == percentage;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      downPaymentPercentage = percentage;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? AppTheme.primaryColor
                        : Colors.white,
                    foregroundColor: isSelected
                        ? Colors.white
                        : AppTheme.textPrimary,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('${percentage.toInt()}%'),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMonthlyPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Payment Terms Options
        Row(
          children: paymentTermOptions.map((terms) {
            final isSelected = paymentTerms == terms;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      paymentTerms = terms;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? AppTheme.primaryColor
                        : Colors.white,
                    foregroundColor: isSelected
                        ? Colors.white
                        : AppTheme.textPrimary,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('$terms Terms'),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Pay in $paymentTerms Terms',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildServiceFeeRate() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Service Fee Rate',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Text(
            '2%/Month',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(
    double downPayment,
    double onSitePayment,
    double monthlyPayment,
    double monthlyServiceFee,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'On-site Payment',
            'TK ${onSitePayment.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Monthly Payment',
            'TK ${monthlyPayment.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
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
    );
  }

  Widget _buildRepaymentPlan() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repayment Plan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Detailed repayment schedule will be shown in the next step.',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

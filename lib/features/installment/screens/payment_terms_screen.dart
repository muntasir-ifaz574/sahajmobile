import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/providers/application_provider.dart';
import '../../../shared/models/installment_model.dart';

class PaymentTermsScreen extends ConsumerStatefulWidget {
  final String? model;
  final String? price; // string input; we'll parse to double
  final String? brand; // brand from product selection
  const PaymentTermsScreen({super.key, this.model, this.price, this.brand});

  @override
  ConsumerState<PaymentTermsScreen> createState() => _PaymentTermsScreenState();
}

class _PaymentTermsScreenState extends ConsumerState<PaymentTermsScreen> {
  String? selectedPaymentTerm;
  String? selectedPaymentTermId; // Payment term ID from API
  String downPaymentType = 'percentage'; // 'percentage' or 'amount'
  double downPaymentValue = 0.0;
  double productPrice = 25000.0; // default; overridden in initState
  // Charges fetched from API
  double chargeDownPmtPercent = 0.0;
  double chargeUpchargePercent = 0.0;
  double chargeBkash = 0.0;
  double chargeLossReservePercent = 0.0;
  double chargePhoneExpense = 0.0;

  List<Map<String, String>> paymentTerms = []; // List of {id, name} maps
  bool _loadingTerms = false;
  String? _termsError;

  // Payment frequency: 'monthly' or 'weekly'
  String paymentFrequency = 'monthly';
  int weeklyRepaymentCount = 12; // Default, will be calculated based on months

  final TextEditingController _downPaymentController = TextEditingController();
  final TextEditingController _weeklyRepaymentController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProductInfoFromWidget();
    _loadPaymentTerms();
    _loadCharges();
    // Set default down payment based on payment term
    _updateDefaultDownPayment();

    // Load from provider after initState to avoid provider modification during widget lifecycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductInfoFromProvider();
    });
  }

  void _loadProductInfoFromWidget() {
    // First try to get product info from widget parameters
    if (widget.price != null) {
      final parsed = double.tryParse(widget.price!.replaceAll(',', '').trim());
      if (parsed != null) productPrice = parsed;
    }
  }

  void _loadProductInfoFromProvider() {
    // If widget parameters are not available, try to load from provider
    if (widget.model == null || widget.price == null) {
      final selectedProduct = ref.read(selectedProductProvider);
      if (selectedProduct != null) {
        setState(() {
          productPrice = selectedProduct.price;
        });
      }
    }
  }

  Future<void> _loadPaymentTerms() async {
    setState(() {
      _loadingTerms = true;
      _termsError = null;
    });
    try {
      final terms = await ApiService.getPaymentTerms();
      setState(() {
        paymentTerms = terms;
        if (paymentTerms.isNotEmpty) {
          selectedPaymentTerm = paymentTerms.first['name'];
          selectedPaymentTermId = paymentTerms.first['id'];
          _updateDefaultDownPayment();
        }
      });
    } catch (e) {
      setState(() {
        _termsError = e.toString();
      });
    } finally {
      setState(() {
        _loadingTerms = false;
      });
    }
  }

  Future<void> _loadCharges() async {
    try {
      final charges = await ApiService.getCharges();
      setState(() {
        chargeDownPmtPercent = charges['down_pmt_percent'] ?? 0;
        chargeUpchargePercent = charges['upcharge_percent'] ?? 0;
        chargeBkash = charges['bkash_charge'] ?? 0;
        chargeLossReservePercent = charges['loss_reserve_percent'] ?? 0;
        chargePhoneExpense = charges['phone_expense'] ?? 0;
        // Initialize default down payment percent from API if present
        if (downPaymentType == 'percentage' && chargeDownPmtPercent > 0) {
          downPaymentValue = chargeDownPmtPercent;
          _downPaymentController.text = downPaymentValue.toStringAsFixed(1);
        }
      });
    } catch (_) {
      // ignore; keep defaults
    }
  }

  void _updateDefaultDownPayment() {
    if (selectedPaymentTerm != null) {
      int months = int.parse(selectedPaymentTerm!.split(' ')[0]);
      double percentage = _getDefaultDownPaymentPercentage(months);
      downPaymentValue = percentage;
      _downPaymentController.text = percentage.toStringAsFixed(1);

      // Update weekly repayment count (default: months * 4 weeks)
      weeklyRepaymentCount = months * 4;
      _weeklyRepaymentController.text = weeklyRepaymentCount.toString();
    }
  }

  void _updateWeeklyRepaymentCount(String value) {
    if (value.isEmpty) {
      setState(() {
        weeklyRepaymentCount = 0;
      });
      return;
    }

    int inputValue = int.tryParse(value) ?? 0;
    setState(() {
      weeklyRepaymentCount = inputValue;
    });
  }

  double _getDefaultDownPaymentPercentage(int months) {
    if (months <= 6) return 20.0; // 20% for 6 months
    if (months <= 9) return 15.0; // 15% for 9 months
    if (months <= 12) return 12.0; // 12% for 12 months
    if (months <= 18) return 10.0; // 10% for 18 months
    return 8.0; // 8% for 24 months
  }

  void _onDownPaymentChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        downPaymentValue = 0.0;
      });
      return;
    }

    double inputValue = double.tryParse(value) ?? 0.0;
    setState(() {
      downPaymentValue = inputValue;
    });
  }

  double _getDownPaymentAmount() {
    if (downPaymentType == 'percentage') {
      return (productPrice * downPaymentValue) / 100;
    } else {
      return downPaymentValue;
    }
  }

  double _getDownPaymentPercentage() {
    if (downPaymentType == 'amount') {
      return (downPaymentValue / productPrice) * 100;
    } else {
      return downPaymentValue;
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
          'Payment Terms',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/installment/product-selection'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Summary Section
            _buildProductSummarySection(),

            const SizedBox(height: 24),

            // Payment Terms Form
            _buildPaymentTermsForm(),

            const SizedBox(height: 24),

            // Payment Summary
            if (selectedPaymentTerm != null &&
                downPaymentValue > 0 &&
                (paymentFrequency == 'monthly' ||
                    (paymentFrequency == 'weekly' && weeklyRepaymentCount > 0)))
              _buildPaymentSummary(),

            const SizedBox(height: 40),

            // Confirm Button
            if (selectedPaymentTerm != null &&
                downPaymentValue > 0 &&
                (paymentFrequency == 'monthly' ||
                    (paymentFrequency == 'weekly' && weeklyRepaymentCount > 0)))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Validate weekly repayment count if weekly is selected
                    if (paymentFrequency == 'weekly' &&
                        weeklyRepaymentCount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a valid number of weekly repayments',
                          ),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      return;
                    }

                    final double downPaymentAmount = _getDownPaymentAmount();
                    final double upchargeAmount =
                        (productPrice * chargeUpchargePercent) / 100.0;
                    final double lossReserveAmount =
                        (productPrice * chargeLossReservePercent) / 100.0;
                    final double baseForBkash =
                        productPrice +
                        upchargeAmount +
                        lossReserveAmount +
                        chargePhoneExpense;
                    final double bkashCalculated =
                        (baseForBkash * chargeBkash) / 1000.0;
                    final double customerRepayment =
                        baseForBkash + bkashCalculated - downPaymentAmount;
                    final int months = int.parse(
                      selectedPaymentTerm!.split(' ')[0],
                    );

                    // Calculate payment based on frequency
                    double paymentAmount;
                    if (paymentFrequency == 'weekly') {
                      paymentAmount = customerRepayment / weeklyRepaymentCount;
                    } else {
                      paymentAmount = customerRepayment / months;
                    }

                    // Save product information to provider
                    final existingProduct = ref.read(selectedProductProvider);
                    final product = Product(
                      id: 'selected_product',
                      brand:
                          widget.brand ??
                          existingProduct?.brand ??
                          _extractBrandFromModel(
                            widget.model ?? existingProduct?.model ?? '',
                          ),
                      model:
                          widget.model ??
                          existingProduct?.model ??
                          'Selected Model',
                      price: productPrice,
                      description:
                          widget.model ??
                          existingProduct?.model ??
                          'Selected Model',
                    );
                    ref
                        .read(applicationDataProvider.notifier)
                        .setSelectedProduct(product);

                    // Save installment plan to provider
                    final installmentPlan = InstallmentPlan(
                      id: 'selected_plan',
                      products: [product],
                      orderAmount: productPrice,
                      downPayment: downPaymentAmount,
                      downPaymentPercentage: _getDownPaymentPercentage(),
                      paymentTerms: paymentFrequency == 'weekly'
                          ? weeklyRepaymentCount
                          : months,
                      paymentTermId: selectedPaymentTermId, // Store the payment term ID
                      monthlyPayment: paymentAmount,
                      serviceFeeRate: chargeUpchargePercent,
                      totalServiceFee:
                          upchargeAmount + lossReserveAmount + bkashCalculated,
                      totalOutstanding: customerRepayment,
                      repaymentTerms: [],
                      paymentFrequency: paymentFrequency,
                    );
                    ref
                        .read(applicationDataProvider.notifier)
                        .setInstallmentPlan(installmentPlan);

                    context.go(
                      '/installment/confirm',
                      extra: {
                        'paymentTerm': selectedPaymentTerm,
                        'paymentFrequency': paymentFrequency,
                        'totalPrice': productPrice,
                        'downPayment': downPaymentAmount,
                        'totalOutstanding': customerRepayment,
                        'paymentAmount': paymentAmount,
                        'weeklyRepaymentCount': paymentFrequency == 'weekly'
                            ? weeklyRepaymentCount
                            : null,
                        'months': paymentFrequency == 'monthly' ? months : null,
                      },
                    );
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

  Widget _buildProductSummarySection() {
    // Get product info from provider if widget parameters are not available
    final selectedProduct = ref.watch(selectedProductProvider);
    final displayModel =
        widget.model ?? selectedProduct?.model ?? 'Selected model';
    final displayBrand = widget.brand ?? selectedProduct?.brand ?? '';

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
            'Selected Product',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayModel,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          if (displayBrand.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              displayBrand,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'TK ${productPrice.toStringAsFixed(0)}',
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

  Widget _buildPaymentTermsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Term Dropdown
        DropdownButtonFormField<String>(
          value: selectedPaymentTerm,
          decoration: InputDecoration(
            labelText: 'Payment Term',
            hintText: 'Select payment term',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: paymentTerms.map((term) {
            return DropdownMenuItem(
              value: term['name'],
              child: Text(term['name']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedPaymentTerm = value;
              // Find and store the corresponding ID
              final selectedTerm = paymentTerms.firstWhere(
                (term) => term['name'] == value,
                orElse: () => paymentTerms.first,
              );
              selectedPaymentTermId = selectedTerm['id'];
            });
            _updateDefaultDownPayment();
          },
        ),

        if (_loadingTerms)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        if (_termsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _termsError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),

        if (selectedPaymentTerm != null) ...[
          const SizedBox(height: 24),

          // Payment Frequency Selection
          const Text(
            'Payment Frequency',
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
                child: RadioListTile<String>(
                  title: const Text('Monthly'),
                  value: 'monthly',
                  groupValue: paymentFrequency,
                  onChanged: (value) {
                    setState(() {
                      paymentFrequency = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Weekly'),
                  value: 'weekly',
                  groupValue: paymentFrequency,
                  onChanged: (value) {
                    setState(() {
                      paymentFrequency = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          // Weekly Repayment Count Input (only show if weekly is selected)
          if (paymentFrequency == 'weekly') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _weeklyRepaymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of Weekly Repayments',
                hintText: 'Enter number of repayments',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText:
                    'Default is ${selectedPaymentTerm != null ? (int.parse(selectedPaymentTerm!.split(' ')[0]) * 4) : 12} weeks (months × 4)',
              ),
              onChanged: _updateWeeklyRepaymentCount,
            ),
          ],
        ],

        const SizedBox(height: 16),

        // Down Payment Type Selection
        const Text(
          'Down Payment',
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
              child: RadioListTile<String>(
                title: const Text('Percentage'),
                value: 'percentage',
                groupValue: downPaymentType,
                onChanged: (value) {
                  setState(() {
                    downPaymentType = value!;
                    _downPaymentController.text = _getDownPaymentPercentage()
                        .toStringAsFixed(1);
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Amount'),
                value: 'amount',
                groupValue: downPaymentType,
                onChanged: (value) {
                  setState(() {
                    downPaymentType = value!;
                    _downPaymentController.text = _getDownPaymentAmount()
                        .toStringAsFixed(0);
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Down Payment Input Field
        TextFormField(
          controller: _downPaymentController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: downPaymentType == 'percentage'
                ? 'Down Payment (%)'
                : 'Down Payment (TK)',
            hintText: downPaymentType == 'percentage'
                ? 'Enter percentage'
                : 'Enter amount',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixText: downPaymentType == 'percentage' ? '%' : 'TK',
          ),
          onChanged: _onDownPaymentChanged,
        ),

        const SizedBox(height: 16),

        // Conversion Display
        if (downPaymentValue > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  downPaymentType == 'percentage' ? 'Amount:' : 'Percentage:',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  downPaymentType == 'percentage'
                      ? 'TK ${_getDownPaymentAmount().toStringAsFixed(0)}'
                      : '${_getDownPaymentPercentage().toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    final double downPaymentAmount = _getDownPaymentAmount();
    // upcharge and loss reserve are percent of price
    final double upchargeAmount =
        (productPrice * chargeUpchargePercent) / 100.0;
    final double lossReserveAmount =
        (productPrice * chargeLossReservePercent) / 100.0;
    // base for bkash: price + upcharge + loss reserve + phone expense
    final double baseForBkash =
        productPrice + upchargeAmount + lossReserveAmount + chargePhoneExpense;
    // bkash formula: ((base) * bkash_charge) / 1000
    final double bkashCalculated = (baseForBkash * chargeBkash) / 1000.0;
    // Customer repayment: base + bkash - downPayment
    final double customerRepayment =
        baseForBkash + bkashCalculated - downPaymentAmount;
    // Per rule: due before EMI is only price - down payment (no fees yet)
    final double customerDueBeforeEmi = productPrice - downPaymentAmount;
    final int months = int.parse(selectedPaymentTerm!.split(' ')[0]);

    // Calculate payment based on frequency
    double paymentAmount;
    if (paymentFrequency == 'weekly') {
      paymentAmount = weeklyRepaymentCount > 0
          ? customerRepayment / weeklyRepaymentCount
          : 0;
    } else {
      paymentAmount = customerRepayment / months;
    }

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
            'Payment Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Cellphone MRP',
            'TK ${productPrice.toStringAsFixed(0)}',
          ),
          _buildSummaryRow(
            'Customer Down-Payment',
            downPaymentType == 'percentage'
                ? '${downPaymentValue.toStringAsFixed(1)}% / TK ${downPaymentAmount.toStringAsFixed(0)}'
                : 'TK ${downPaymentAmount.toStringAsFixed(0)} / ${_getDownPaymentPercentage().toStringAsFixed(1)}%',
          ),
          _buildSummaryRow(
            'Customer due (before EMI fee)',
            'TK ${customerDueBeforeEmi.toStringAsFixed(0)}',
          ),
          _buildSummaryRow(
            'Customer Repayment',
            'TK ${customerRepayment.toStringAsFixed(0)}',
          ),
          const Divider(),
          _buildSummaryRow('Payment Term', selectedPaymentTerm!),
          _buildSummaryRow(
            'Payment Frequency',
            paymentFrequency == 'weekly' ? 'Weekly' : 'Monthly',
          ),
          if (paymentFrequency == 'weekly')
            _buildSummaryRow(
              'Number of Repayments',
              '$weeklyRepaymentCount weeks',
            ),
          _buildSummaryRow(
            paymentFrequency == 'weekly' ? 'Weekly Payment' : 'Monthly Payment',
            'TK ${paymentAmount.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  String _extractBrandFromModel(String model) {
    // Try to extract brand from model string
    // Common brands in the system
    final brands = [
      'Infinix',
      'Samsung',
      'Xiaomi',
      'Realme',
      'Oppo',
      'Vivo',
      'OnePlus',
      'Apple',
      'Huawei',
    ];

    for (final brand in brands) {
      if (model.toLowerCase().contains(brand.toLowerCase())) {
        return brand;
      }
    }

    // If no brand found, try to extract first word
    final words = model.split(' ');
    if (words.isNotEmpty) {
      return words[0];
    }

    return 'Unknown Brand';
  }

  @override
  void dispose() {
    _downPaymentController.dispose();
    _weeklyRepaymentController.dispose();
    super.dispose();
  }
}

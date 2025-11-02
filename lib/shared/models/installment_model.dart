import 'package:json_annotation/json_annotation.dart';

part 'installment_model.g.dart';

@JsonSerializable()
class Product {
  final String id;
  final String brand;
  final String model;
  final double price;
  final String? imageUrl;
  final String description;

  const Product({
    required this.id,
    required this.brand,
    required this.model,
    required this.price,
    this.imageUrl,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

@JsonSerializable()
class InstallmentPlan {
  final String id;
  final List<Product> products;
  final double orderAmount;
  final double downPayment;
  final double downPaymentPercentage;
  final int paymentTerms;
  final String? paymentTermId; // Payment term ID from get_month API
  final double monthlyPayment;
  final double serviceFeeRate;
  final double totalServiceFee;
  final double totalOutstanding;
  final List<RepaymentTerm> repaymentTerms;
  final String paymentFrequency; // 'monthly' or 'weekly'

  const InstallmentPlan({
    required this.id,
    required this.products,
    required this.orderAmount,
    required this.downPayment,
    required this.downPaymentPercentage,
    required this.paymentTerms,
    this.paymentTermId,
    required this.monthlyPayment,
    required this.serviceFeeRate,
    required this.totalServiceFee,
    required this.totalOutstanding,
    required this.repaymentTerms,
    this.paymentFrequency = 'monthly', // Default to monthly for backward compatibility
  });

  factory InstallmentPlan.fromJson(Map<String, dynamic> json) =>
      _$InstallmentPlanFromJson(json);
  Map<String, dynamic> toJson() => _$InstallmentPlanToJson(this);
}

@JsonSerializable()
class RepaymentTerm {
  final int termNumber;
  final DateTime dueDate;
  final double amount;
  final String status;

  const RepaymentTerm({
    required this.termNumber,
    required this.dueDate,
    required this.amount,
    required this.status,
  });

  factory RepaymentTerm.fromJson(Map<String, dynamic> json) =>
      _$RepaymentTermFromJson(json);
  Map<String, dynamic> toJson() => _$RepaymentTermToJson(this);
}

@JsonSerializable()
class InstallmentCalculation {
  final double orderAmount;
  final double downPaymentPercentage;
  final double downPayment;
  final int paymentTerms;
  final double serviceFeeRate;
  final double monthlyServiceFee;
  final double monthlyPayment;
  final double totalServiceFee;
  final double totalOutstanding;

  const InstallmentCalculation({
    required this.orderAmount,
    required this.downPaymentPercentage,
    required this.downPayment,
    required this.paymentTerms,
    required this.serviceFeeRate,
    required this.monthlyServiceFee,
    required this.monthlyPayment,
    required this.totalServiceFee,
    required this.totalOutstanding,
  });

  factory InstallmentCalculation.fromJson(Map<String, dynamic> json) =>
      _$InstallmentCalculationFromJson(json);
  Map<String, dynamic> toJson() => _$InstallmentCalculationToJson(this);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: json['id'] as String,
  brand: json['brand'] as String,
  model: json['model'] as String,
  price: (json['price'] as num).toDouble(),
  imageUrl: json['imageUrl'] as String?,
  description: json['description'] as String,
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'brand': instance.brand,
  'model': instance.model,
  'price': instance.price,
  'imageUrl': instance.imageUrl,
  'description': instance.description,
};

InstallmentPlan _$InstallmentPlanFromJson(Map<String, dynamic> json) =>
    InstallmentPlan(
      id: json['id'] as String,
      products: (json['products'] as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderAmount: (json['orderAmount'] as num).toDouble(),
      downPayment: (json['downPayment'] as num).toDouble(),
      downPaymentPercentage: (json['downPaymentPercentage'] as num).toDouble(),
      paymentTerms: (json['paymentTerms'] as num).toInt(),
      monthlyPayment: (json['monthlyPayment'] as num).toDouble(),
      serviceFeeRate: (json['serviceFeeRate'] as num).toDouble(),
      totalServiceFee: (json['totalServiceFee'] as num).toDouble(),
      totalOutstanding: (json['totalOutstanding'] as num).toDouble(),
      repaymentTerms: (json['repaymentTerms'] as List<dynamic>)
          .map((e) => RepaymentTerm.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentFrequency: json['paymentFrequency'] as String? ?? 'monthly',
    );

Map<String, dynamic> _$InstallmentPlanToJson(InstallmentPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'products': instance.products,
      'orderAmount': instance.orderAmount,
      'downPayment': instance.downPayment,
      'downPaymentPercentage': instance.downPaymentPercentage,
      'paymentTerms': instance.paymentTerms,
      'monthlyPayment': instance.monthlyPayment,
      'serviceFeeRate': instance.serviceFeeRate,
      'totalServiceFee': instance.totalServiceFee,
      'totalOutstanding': instance.totalOutstanding,
      'repaymentTerms': instance.repaymentTerms,
      'paymentFrequency': instance.paymentFrequency,
    };

RepaymentTerm _$RepaymentTermFromJson(Map<String, dynamic> json) =>
    RepaymentTerm(
      termNumber: (json['termNumber'] as num).toInt(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$RepaymentTermToJson(RepaymentTerm instance) =>
    <String, dynamic>{
      'termNumber': instance.termNumber,
      'dueDate': instance.dueDate.toIso8601String(),
      'amount': instance.amount,
      'status': instance.status,
    };

InstallmentCalculation _$InstallmentCalculationFromJson(
  Map<String, dynamic> json,
) => InstallmentCalculation(
  orderAmount: (json['orderAmount'] as num).toDouble(),
  downPaymentPercentage: (json['downPaymentPercentage'] as num).toDouble(),
  downPayment: (json['downPayment'] as num).toDouble(),
  paymentTerms: (json['paymentTerms'] as num).toInt(),
  serviceFeeRate: (json['serviceFeeRate'] as num).toDouble(),
  monthlyServiceFee: (json['monthlyServiceFee'] as num).toDouble(),
  monthlyPayment: (json['monthlyPayment'] as num).toDouble(),
  totalServiceFee: (json['totalServiceFee'] as num).toDouble(),
  totalOutstanding: (json['totalOutstanding'] as num).toDouble(),
);

Map<String, dynamic> _$InstallmentCalculationToJson(
  InstallmentCalculation instance,
) => <String, dynamic>{
  'orderAmount': instance.orderAmount,
  'downPaymentPercentage': instance.downPaymentPercentage,
  'downPayment': instance.downPayment,
  'paymentTerms': instance.paymentTerms,
  'serviceFeeRate': instance.serviceFeeRate,
  'monthlyServiceFee': instance.monthlyServiceFee,
  'monthlyPayment': instance.monthlyPayment,
  'totalServiceFee': instance.totalServiceFee,
  'totalOutstanding': instance.totalOutstanding,
};

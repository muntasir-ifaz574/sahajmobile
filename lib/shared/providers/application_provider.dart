import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/installment_model.dart';
import '../models/application_model.dart';
import '../models/division_model.dart';
import '../models/district_model.dart';
import '../models/thana_model.dart';
import '../models/union_model.dart';
import '../services/api_service.dart';
import 'nid_provider.dart';
import '../services/storage_service.dart';

// Application Data State
class ApplicationDataState {
  final Product? selectedProduct;
  final InstallmentPlan? installmentPlan;
  final MachineInfo? machineInfo;
  final PersonalInfo? personalInfo;
  final AddressInfo? addressInfo;
  final JobInfo? jobInfo;
  final GuarantorInfo? guarantorInfo;
  final bool isLoading;
  final String? error;

  const ApplicationDataState({
    this.selectedProduct,
    this.installmentPlan,
    this.machineInfo,
    this.personalInfo,
    this.addressInfo,
    this.jobInfo,
    this.guarantorInfo,
    this.isLoading = false,
    this.error,
  });

  ApplicationDataState copyWith({
    Product? selectedProduct,
    InstallmentPlan? installmentPlan,
    MachineInfo? machineInfo,
    PersonalInfo? personalInfo,
    AddressInfo? addressInfo,
    JobInfo? jobInfo,
    GuarantorInfo? guarantorInfo,
    bool? isLoading,
    String? error,
  }) {
    return ApplicationDataState(
      selectedProduct: selectedProduct ?? this.selectedProduct,
      installmentPlan: installmentPlan ?? this.installmentPlan,
      machineInfo: machineInfo ?? this.machineInfo,
      personalInfo: personalInfo ?? this.personalInfo,
      addressInfo: addressInfo ?? this.addressInfo,
      jobInfo: jobInfo ?? this.jobInfo,
      guarantorInfo: guarantorInfo ?? this.guarantorInfo,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Application Data Notifier
class ApplicationDataNotifier extends Notifier<ApplicationDataState> {
  @override
  ApplicationDataState build() {
    return const ApplicationDataState();
  }

  // Submit the application to backend
  Future<Map<String, dynamic>> submitApplication({
    String? bkashStatementPath,
    String? bankStatementPath,
    String? customerSignaturePath,
  }) async {
    if (!isApplicationComplete()) {
      final List<String> missing = [];
      if (state.personalInfo == null) missing.add('Personal information');
      if (state.addressInfo == null) missing.add('Address information');
      if (state.jobInfo == null) missing.add('Job/income information');
      if (state.guarantorInfo == null) missing.add('Guarantor information');
      if (state.machineInfo == null) missing.add('Machine information');
      if (state.selectedProduct == null) missing.add('Selected product');
      if (state.installmentPlan == null) missing.add('Installment plan');

      final message =
          'Application is incomplete: ${missing.isEmpty ? 'Unknown sections' : missing.join(', ')}';
      developer.log(message, name: 'ApplicationDataNotifier', level: 900);
      throw Exception(message);
    }

    setLoading(true);
    try {
      final product = state.selectedProduct!;
      final plan = state.installmentPlan!;
      final machine = state.machineInfo!;
      final personal = state.personalInfo!;
      final address = state.addressInfo!;
      final job = state.jobInfo!;
      final guarantor = state.guarantorInfo!;
      // Prefer selected IDs from location provider when available
      final location = ref.read(locationDataProvider);
      final String preDivisionId =
          location.selectedDivision?.id ?? address.division;
      final String preDistrictId =
          location.selectedDistrict?.id ?? address.district;
      final String preThanaId = location.selectedThana?.id ?? address.upazila;
      final String preUnionId = location.selectedUnion?.id ?? '';
      // Get shop ID from storage
      final shopId = await StorageService.getShopId();

      // Text fields mapping per API contract
      final Map<String, dynamic> textFields = {
        'name': personal.fullName,
        'store': shopId,
        'brand': product.brand,
        'model': product.model,
        'months_repay': plan.paymentTerms.toString(),
        'cellphone_MRP': product.price.toString(),
        'discountRate': '0',
        'discount_percent': '0',
        'phone_cost': plan.orderAmount.toString(),
        'downPayment': plan.downPayment.toString(),
        'down_payment_percent': plan.downPaymentPercentage.toString(),
        'advance': plan.downPayment.toString(),
        'gross_moic': plan.totalOutstanding.toString(),
        'customer_due': (plan.orderAmount - plan.downPayment).toString(),
        'customer_upcharge': plan.totalServiceFee.toString(),
        'customer_repayment': plan.totalOutstanding.toString(),
        'loss_reserve': '0',
        'loss_reserve_percent': '0',
        'total_repayment': plan.totalOutstanding.toString(),
        'per_phone_gross': (plan.totalOutstanding - plan.orderAmount)
            .toString(),
        'loss_adj_moic': plan.totalOutstanding.toString(),
        'phone_lock_expense': '0',
        'net_repayment': plan.totalOutstanding.toString(),
        'net_net_moic': plan.totalOutstanding.toString(),
        'week_type': plan.paymentFrequency,
        'transaction_charge': '0',
        'installmentAmount': plan.monthlyPayment.toString(),
        'installmentStartDate': DateTime.now()
            .toIso8601String()
            .split('T')
            .first,
        'nationalId': personal.nidNumber,
        'contact_number': (ref.read(nidProvider).contactNumber ?? ''),
        'birthDate': personal.dateOfBirth.toIso8601String().split('T').first,
        'occupation': job.occupation,
        'comnpany_name': job.companyName,
        'monthly_income': job.monthlyIncome.toString(),
        'certifier_mobile': job.certifierPhone,
        'work_certifier': job.certifierName,
        'guarantor_name': guarantor.fullName,
        'relationship_guarantor': guarantor.relationship,
        'guarantor_nid': guarantor.nidNumber,
        'gaurantor_mobile': guarantor.phoneNumber,
        'present_residential_address': address.addressDetails,
        'permanent_residential_address': address.addressDetails,
        'guarantor_dob': guarantor.dateOfBirth
            .toIso8601String()
            .split('T')
            .first,
        'guarantor_marital_status': guarantor.maritalStatus,
        'pre_divsion': preDivisionId,
        'pre_district': preDistrictId,
        'pre_thana': preThanaId,
        'pre_unions': preUnionId,
        'is_present': '1',
        'per_divsion': preDivisionId,
        'per_district': preDistrictId,
        'per_thana': preThanaId,
        'per_unions': preUnionId,
        'imei1': machine.imei1,
        'imei2': machine.imei2,
      };

      // File fields (paths)
      final Map<String, String?> filePaths = {
        'work_certifier': job.workIdFrontImage,
        'front_nid': personal.nidFrontImage,
        'back_nid': personal.nidBackImage,
        'gaurantor_front_nid': guarantor.nidFrontImage,
        'gaurantor_back_nid': guarantor.nidBackImage,
        'bKash_statement': bkashStatementPath,
        'bank_statement': bankStatementPath,
        'customer_signature': customerSignaturePath,
      };

      final result = await ApiService.submitApplication(
        textFields: textFields,
        filePaths: filePaths,
      );

      // Logging success summary
      developer.log(
        'submitApplication success',
        name: 'ApplicationDataNotifier',
        error: null,
        stackTrace: null,
      );
      if (result.containsKey('status')) {
        developer.log(
          'submitApplication response status: ${result['status']}',
          name: 'ApplicationDataNotifier',
        );
      }

      // If backend indicates success, clear all stored form data
      final dynamic status = result['status'];
      final bool isSuccess =
          status == 1 || status == '1' || result['success'] == true;
      if (isSuccess) {
        // Reset application data
        reset();
        // Reset related providers
        ref.read(nidProvider.notifier).reset();
        ref.read(locationDataProvider.notifier).reset();
      }

      setLoading(false);
      return result;
    } catch (e) {
      developer.log(
        'submitApplication failed: $e',
        name: 'ApplicationDataNotifier',
        level: 1000,
      );
      setError(e.toString());
      rethrow;
    }
  }

  void setSelectedProduct(Product product) {
    state = state.copyWith(selectedProduct: product, error: null);
  }

  void setInstallmentPlan(InstallmentPlan plan) {
    state = state.copyWith(installmentPlan: plan, error: null);
  }

  void setMachineInfo(MachineInfo machineInfo) {
    state = state.copyWith(machineInfo: machineInfo, error: null);
  }

  void setPersonalInfo(PersonalInfo personalInfo) {
    state = state.copyWith(personalInfo: personalInfo, error: null);
  }

  void setAddressInfo(AddressInfo addressInfo) {
    state = state.copyWith(addressInfo: addressInfo, error: null);
  }

  void setJobInfo(JobInfo jobInfo) {
    state = state.copyWith(jobInfo: jobInfo, error: null);
  }

  void setGuarantorInfo(GuarantorInfo guarantorInfo) {
    state = state.copyWith(guarantorInfo: guarantorInfo, error: null);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const ApplicationDataState();
  }

  // Form validation methods
  bool isPersonalInfoComplete() {
    return state.personalInfo != null;
  }

  bool isAddressInfoComplete() {
    return state.addressInfo != null;
  }

  bool isJobInfoComplete() {
    return state.jobInfo != null;
  }

  bool isGuarantorInfoComplete() {
    return state.guarantorInfo != null;
  }

  bool isMachineInfoComplete() {
    return state.machineInfo != null;
  }

  bool isApplicationComplete() {
    return isPersonalInfoComplete() &&
        isAddressInfoComplete() &&
        isJobInfoComplete() &&
        isGuarantorInfoComplete() &&
        isMachineInfoComplete() &&
        state.selectedProduct != null &&
        state.installmentPlan != null;
  }

  // Data persistence methods
  Map<String, dynamic> toJson() {
    return {
      'selectedProduct': state.selectedProduct?.toJson(),
      'installmentPlan': state.installmentPlan?.toJson(),
      'machineInfo': state.machineInfo?.toJson(),
      'personalInfo': state.personalInfo?.toJson(),
      'addressInfo': state.addressInfo?.toJson(),
      'jobInfo': state.jobInfo?.toJson(),
      'guarantorInfo': state.guarantorInfo?.toJson(),
    };
  }

  void fromJson(Map<String, dynamic> json) {
    if (json['selectedProduct'] != null) {
      setSelectedProduct(Product.fromJson(json['selectedProduct']));
    }
    if (json['installmentPlan'] != null) {
      setInstallmentPlan(InstallmentPlan.fromJson(json['installmentPlan']));
    }
    if (json['machineInfo'] != null) {
      setMachineInfo(MachineInfo.fromJson(json['machineInfo']));
    }
    if (json['personalInfo'] != null) {
      setPersonalInfo(PersonalInfo.fromJson(json['personalInfo']));
    }
    if (json['addressInfo'] != null) {
      setAddressInfo(AddressInfo.fromJson(json['addressInfo']));
    }
    if (json['jobInfo'] != null) {
      setJobInfo(JobInfo.fromJson(json['jobInfo']));
    }
    if (json['guarantorInfo'] != null) {
      setGuarantorInfo(GuarantorInfo.fromJson(json['guarantorInfo']));
    }
  }

  // Helper method to get formatted product name
  String getProductDisplayName() {
    if (state.selectedProduct == null) return 'No product selected';

    final product = state.selectedProduct!;
    return '${product.brand}, ${product.model}, ${product.description}';
  }

  // Helper method to get primary IMEI
  String getPrimaryIMEI() {
    if (state.machineInfo == null) return 'No IMEI available';
    return state.machineInfo!.imei1;
  }

  // Helper method to get secondary IMEI (if available)
  String? getSecondaryIMEI() {
    if (state.machineInfo == null) return null;
    return state.machineInfo!.imei2.isNotEmpty
        ? state.machineInfo!.imei2
        : null;
  }

  // Helper method to get payment summary
  PaymentSummary? getPaymentSummary() {
    if (state.installmentPlan == null) return null;

    final plan = state.installmentPlan!;
    return PaymentSummary(
      orderAmount: plan.orderAmount,
      downPayment: plan.downPayment,
      downPaymentPercentage: plan.downPaymentPercentage,
      paymentTerms: plan.paymentTerms,
      monthlyPayment: plan.monthlyPayment,
      serviceFeeRate: plan.serviceFeeRate,
      totalServiceFee: plan.totalServiceFee,
      totalOutstanding: plan.totalOutstanding,
      paymentFrequency: plan.paymentFrequency,
    );
  }
}

// Payment Summary data class for easy display
class PaymentSummary {
  final double orderAmount;
  final double downPayment;
  final double downPaymentPercentage;
  final int paymentTerms;
  final double monthlyPayment;
  final double serviceFeeRate;
  final double totalServiceFee;
  final double totalOutstanding;
  final String paymentFrequency;

  const PaymentSummary({
    required this.orderAmount,
    required this.downPayment,
    required this.downPaymentPercentage,
    required this.paymentTerms,
    required this.monthlyPayment,
    required this.serviceFeeRate,
    required this.totalServiceFee,
    required this.totalOutstanding,
    this.paymentFrequency = 'monthly',
  });
}

// Providers
final applicationDataProvider =
    NotifierProvider<ApplicationDataNotifier, ApplicationDataState>(() {
      return ApplicationDataNotifier();
    });

final selectedProductProvider = Provider<Product?>((ref) {
  return ref.watch(applicationDataProvider).selectedProduct;
});

final installmentPlanProvider = Provider<InstallmentPlan?>((ref) {
  return ref.watch(applicationDataProvider).installmentPlan;
});

final machineInfoProvider = Provider<MachineInfo?>((ref) {
  return ref.watch(applicationDataProvider).machineInfo;
});

final paymentSummaryProvider = Provider<PaymentSummary?>((ref) {
  return ref.read(applicationDataProvider.notifier).getPaymentSummary();
});

final productDisplayNameProvider = Provider<String>((ref) {
  return ref.read(applicationDataProvider.notifier).getProductDisplayName();
});

final primaryIMEIProvider = Provider<String>((ref) {
  return ref.read(applicationDataProvider.notifier).getPrimaryIMEI();
});

final secondaryIMEIProvider = Provider<String?>((ref) {
  return ref.read(applicationDataProvider.notifier).getSecondaryIMEI();
});

// Additional providers for form data
final personalInfoProvider = Provider<PersonalInfo?>((ref) {
  return ref.watch(applicationDataProvider).personalInfo;
});

final addressInfoProvider = Provider<AddressInfo?>((ref) {
  return ref.watch(applicationDataProvider).addressInfo;
});

final jobInfoProvider = Provider<JobInfo?>((ref) {
  return ref.watch(applicationDataProvider).jobInfo;
});

final guarantorInfoProvider = Provider<GuarantorInfo?>((ref) {
  return ref.watch(applicationDataProvider).guarantorInfo;
});

// Location Data State
class LocationDataState {
  final List<Division> divisions;
  final List<District> districts;
  final List<Thana> thanas;
  final List<UnionModel> unions;
  final Division? selectedDivision;
  final District? selectedDistrict;
  final Thana? selectedThana;
  final UnionModel? selectedUnion;
  final bool isLoadingDivisions;
  final bool isLoadingDistricts;
  final bool isLoadingThanas;
  final bool isLoadingUnions;
  final String? divisionError;
  final String? districtError;
  final String? thanaError;
  final String? unionError;

  const LocationDataState({
    this.divisions = const [],
    this.districts = const [],
    this.thanas = const [],
    this.unions = const [],
    this.selectedDivision,
    this.selectedDistrict,
    this.selectedThana,
    this.selectedUnion,
    this.isLoadingDivisions = false,
    this.isLoadingDistricts = false,
    this.isLoadingThanas = false,
    this.isLoadingUnions = false,
    this.divisionError,
    this.districtError,
    this.thanaError,
    this.unionError,
  });

  LocationDataState copyWith({
    List<Division>? divisions,
    List<District>? districts,
    List<Thana>? thanas,
    List<UnionModel>? unions,
    Division? selectedDivision,
    District? selectedDistrict,
    Thana? selectedThana,
    UnionModel? selectedUnion,
    bool? isLoadingDivisions,
    bool? isLoadingDistricts,
    bool? isLoadingThanas,
    bool? isLoadingUnions,
    String? divisionError,
    String? districtError,
    String? thanaError,
    String? unionError,
  }) {
    return LocationDataState(
      divisions: divisions ?? this.divisions,
      districts: districts ?? this.districts,
      thanas: thanas ?? this.thanas,
      unions: unions ?? this.unions,
      selectedDivision: selectedDivision ?? this.selectedDivision,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      selectedThana: selectedThana ?? this.selectedThana,
      selectedUnion: selectedUnion ?? this.selectedUnion,
      isLoadingDivisions: isLoadingDivisions ?? this.isLoadingDivisions,
      isLoadingDistricts: isLoadingDistricts ?? this.isLoadingDistricts,
      isLoadingThanas: isLoadingThanas ?? this.isLoadingThanas,
      isLoadingUnions: isLoadingUnions ?? this.isLoadingUnions,
      divisionError: divisionError ?? this.divisionError,
      districtError: districtError ?? this.districtError,
      thanaError: thanaError ?? this.thanaError,
      unionError: unionError ?? this.unionError,
    );
  }
}

// Location Data Notifier
class LocationDataNotifier extends Notifier<LocationDataState> {
  @override
  LocationDataState build() {
    return const LocationDataState();
  }

  void setDivisions(List<Division> divisions) {
    state = state.copyWith(divisions: divisions, divisionError: null);
  }

  void setDistricts(List<District> districts) {
    state = state.copyWith(districts: districts, districtError: null);
  }

  void setThanas(List<Thana> thanas) {
    state = state.copyWith(thanas: thanas, thanaError: null);
  }

  void setUnions(List<UnionModel> unions) {
    state = state.copyWith(unions: unions, unionError: null);
  }

  void setSelectedDivision(Division division) {
    state = state.copyWith(
      selectedDivision: division,
      selectedDistrict: null,
      selectedThana: null,
      selectedUnion: null,
      districts: const [],
      thanas: const [],
      unions: const [],
    );
  }

  void setSelectedDistrict(District district) {
    state = state.copyWith(
      selectedDistrict: district,
      selectedThana: null,
      selectedUnion: null,
      thanas: const [],
      unions: const [],
    );
  }

  void setSelectedThana(Thana thana) {
    state = state.copyWith(
      selectedThana: thana,
      selectedUnion: null,
      unions: const [],
    );
  }

  void setSelectedUnion(UnionModel unionModel) {
    state = state.copyWith(selectedUnion: unionModel);
  }

  void setLoadingDivisions(bool loading) {
    state = state.copyWith(isLoadingDivisions: loading);
  }

  void setLoadingDistricts(bool loading) {
    state = state.copyWith(isLoadingDistricts: loading);
  }

  void setLoadingThanas(bool loading) {
    state = state.copyWith(isLoadingThanas: loading);
  }

  void setLoadingUnions(bool loading) {
    state = state.copyWith(isLoadingUnions: loading);
  }

  void setDivisionError(String error) {
    state = state.copyWith(divisionError: error, isLoadingDivisions: false);
  }

  void setDistrictError(String error) {
    state = state.copyWith(districtError: error, isLoadingDistricts: false);
  }

  void setThanaError(String error) {
    state = state.copyWith(thanaError: error, isLoadingThanas: false);
  }

  void setUnionError(String error) {
    state = state.copyWith(unionError: error, isLoadingUnions: false);
  }

  void clearErrors() {
    state = state.copyWith(
      divisionError: null,
      districtError: null,
      thanaError: null,
      unionError: null,
    );
  }

  void reset() {
    state = const LocationDataState();
  }
}

// Location Data Provider
final locationDataProvider =
    NotifierProvider<LocationDataNotifier, LocationDataState>(() {
      return LocationDataNotifier();
    });

// Validation and completion status providers
final isPersonalInfoCompleteProvider = Provider<bool>((ref) {
  return ref.read(applicationDataProvider.notifier).isPersonalInfoComplete();
});

final isAddressInfoCompleteProvider = Provider<bool>((ref) {
  return ref.read(applicationDataProvider.notifier).isAddressInfoComplete();
});

final isJobInfoCompleteProvider = Provider<bool>((ref) {
  return ref.read(applicationDataProvider.notifier).isJobInfoComplete();
});

final isGuarantorInfoCompleteProvider = Provider<bool>((ref) {
  return ref.read(applicationDataProvider.notifier).isGuarantorInfoComplete();
});

final isMachineInfoCompleteProvider = Provider<bool>((ref) {
  return ref.read(applicationDataProvider.notifier).isMachineInfoComplete();
});

final isApplicationCompleteProvider = Provider<bool>((ref) {
  return ref.read(applicationDataProvider.notifier).isApplicationComplete();
});

// Application progress provider
final applicationProgressProvider = Provider<double>((ref) {
  int completedSteps = 0;
  int totalSteps =
      6; // personal, address, job, guarantor, machine, product/installment

  if (ref.watch(isPersonalInfoCompleteProvider)) completedSteps++;
  if (ref.watch(isAddressInfoCompleteProvider)) completedSteps++;
  if (ref.watch(isJobInfoCompleteProvider)) completedSteps++;
  if (ref.watch(isGuarantorInfoCompleteProvider)) completedSteps++;
  if (ref.watch(isMachineInfoCompleteProvider)) completedSteps++;
  if (ref.watch(selectedProductProvider) != null &&
      ref.watch(installmentPlanProvider) != null)
    completedSteps++;

  return completedSteps / totalSteps;
});

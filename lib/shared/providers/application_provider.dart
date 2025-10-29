import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/installment_model.dart';
import '../models/application_model.dart';
import '../models/division_model.dart';
import '../models/district_model.dart';
import '../models/thana_model.dart';

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

  const PaymentSummary({
    required this.orderAmount,
    required this.downPayment,
    required this.downPaymentPercentage,
    required this.paymentTerms,
    required this.monthlyPayment,
    required this.serviceFeeRate,
    required this.totalServiceFee,
    required this.totalOutstanding,
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
  final Division? selectedDivision;
  final District? selectedDistrict;
  final Thana? selectedThana;
  final bool isLoadingDivisions;
  final bool isLoadingDistricts;
  final bool isLoadingThanas;
  final String? divisionError;
  final String? districtError;
  final String? thanaError;

  const LocationDataState({
    this.divisions = const [],
    this.districts = const [],
    this.thanas = const [],
    this.selectedDivision,
    this.selectedDistrict,
    this.selectedThana,
    this.isLoadingDivisions = false,
    this.isLoadingDistricts = false,
    this.isLoadingThanas = false,
    this.divisionError,
    this.districtError,
    this.thanaError,
  });

  LocationDataState copyWith({
    List<Division>? divisions,
    List<District>? districts,
    List<Thana>? thanas,
    Division? selectedDivision,
    District? selectedDistrict,
    Thana? selectedThana,
    bool? isLoadingDivisions,
    bool? isLoadingDistricts,
    bool? isLoadingThanas,
    String? divisionError,
    String? districtError,
    String? thanaError,
  }) {
    return LocationDataState(
      divisions: divisions ?? this.divisions,
      districts: districts ?? this.districts,
      thanas: thanas ?? this.thanas,
      selectedDivision: selectedDivision ?? this.selectedDivision,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      selectedThana: selectedThana ?? this.selectedThana,
      isLoadingDivisions: isLoadingDivisions ?? this.isLoadingDivisions,
      isLoadingDistricts: isLoadingDistricts ?? this.isLoadingDistricts,
      isLoadingThanas: isLoadingThanas ?? this.isLoadingThanas,
      divisionError: divisionError ?? this.divisionError,
      districtError: districtError ?? this.districtError,
      thanaError: thanaError ?? this.thanaError,
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

  void setSelectedDivision(Division division) {
    state = state.copyWith(
      selectedDivision: division,
      selectedDistrict: null,
      selectedThana: null,
      districts: const [],
      thanas: const [],
    );
  }

  void setSelectedDistrict(District district) {
    state = state.copyWith(
      selectedDistrict: district,
      selectedThana: null,
      thanas: const [],
    );
  }

  void setSelectedThana(Thana thana) {
    state = state.copyWith(selectedThana: thana);
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

  void setDivisionError(String error) {
    state = state.copyWith(divisionError: error, isLoadingDivisions: false);
  }

  void setDistrictError(String error) {
    state = state.copyWith(districtError: error, isLoadingDistricts: false);
  }

  void setThanaError(String error) {
    state = state.copyWith(thanaError: error, isLoadingThanas: false);
  }

  void clearErrors() {
    state = state.copyWith(
      divisionError: null,
      districtError: null,
      thanaError: null,
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

import 'package:json_annotation/json_annotation.dart';

part 'application_model.g.dart';

@JsonSerializable()
class Application {
  final String id;
  final String customerId;
  final String productId;
  final String status;
  final double orderAmount;
  final double downPayment;
  final int paymentTerms;
  final double monthlyPayment;
  final double serviceFee;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ApplicationDetails? details;

  const Application({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.status,
    required this.orderAmount,
    required this.downPayment,
    required this.paymentTerms,
    required this.monthlyPayment,
    required this.serviceFee,
    required this.createdAt,
    required this.updatedAt,
    this.details,
  });

  factory Application.fromJson(Map<String, dynamic> json) =>
      _$ApplicationFromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationToJson(this);
}

@JsonSerializable()
class ApplicationDetails {
  final PersonalInfo personalInfo;
  final AddressInfo addressInfo;
  final JobInfo jobInfo;
  final GuarantorInfo guarantorInfo;
  final MachineInfo machineInfo;

  const ApplicationDetails({
    required this.personalInfo,
    required this.addressInfo,
    required this.jobInfo,
    required this.guarantorInfo,
    required this.machineInfo,
  });

  factory ApplicationDetails.fromJson(Map<String, dynamic> json) =>
      _$ApplicationDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationDetailsToJson(this);
}

@JsonSerializable()
class PersonalInfo {
  final String nidNumber;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String? nidFrontImage;
  final String? nidBackImage;

  const PersonalInfo({
    required this.nidNumber,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.nidFrontImage,
    this.nidBackImage,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) =>
      _$PersonalInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PersonalInfoToJson(this);
}

@JsonSerializable()
class AddressInfo {
  final String division;
  final String district;
  final String upazila;
  final String addressDetails;
  final String permanentDivision;
  final String permanentDistrict;
  final String permanentUpazila;
  final String permanentUnion;
  final String permanentAddressDetails;

  const AddressInfo({
    required this.division,
    required this.district,
    required this.upazila,
    required this.addressDetails,
    required this.permanentDivision,
    required this.permanentDistrict,
    required this.permanentUpazila,
    required this.permanentUnion,
    required this.permanentAddressDetails,
  });

  factory AddressInfo.fromJson(Map<String, dynamic> json) =>
      _$AddressInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AddressInfoToJson(this);
}

@JsonSerializable()
class JobInfo {
  final String occupation;
  final String companyName;
  final String workCertifier;
  final String certifierName;
  final String certifierPhone;
  final double monthlyIncome;
  final String? workIdFrontImage;
  final String? workIdBackImage;

  const JobInfo({
    required this.occupation,
    required this.companyName,
    required this.workCertifier,
    required this.certifierName,
    required this.certifierPhone,
    required this.monthlyIncome,
    this.workIdFrontImage,
    this.workIdBackImage,
  });

  factory JobInfo.fromJson(Map<String, dynamic> json) =>
      _$JobInfoFromJson(json);
  Map<String, dynamic> toJson() => _$JobInfoToJson(this);
}

@JsonSerializable()
class GuarantorInfo {
  final String relationship;
  final String nidNumber;
  final String fullName;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String maritalStatus;
  final String presentAddress;
  final String permanentAddress;
  final String? nidFrontImage;
  final String? nidBackImage;

  const GuarantorInfo({
    required this.relationship,
    required this.nidNumber,
    required this.fullName,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.maritalStatus,
    required this.presentAddress,
    required this.permanentAddress,
    this.nidFrontImage,
    this.nidBackImage,
  });

  factory GuarantorInfo.fromJson(Map<String, dynamic> json) =>
      _$GuarantorInfoFromJson(json);
  Map<String, dynamic> toJson() => _$GuarantorInfoToJson(this);
}

@JsonSerializable()
class MachineInfo {
  final String imei1;
  final String imei2;
  final String? imeiImage;

  const MachineInfo({required this.imei1, required this.imei2, this.imeiImage});

  factory MachineInfo.fromJson(Map<String, dynamic> json) =>
      _$MachineInfoFromJson(json);
  Map<String, dynamic> toJson() => _$MachineInfoToJson(this);
}

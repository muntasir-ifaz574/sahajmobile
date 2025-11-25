// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Application _$ApplicationFromJson(Map<String, dynamic> json) => Application(
  id: json['id'] as String,
  customerId: json['customerId'] as String,
  productId: json['productId'] as String,
  status: json['status'] as String,
  orderAmount: (json['orderAmount'] as num).toDouble(),
  downPayment: (json['downPayment'] as num).toDouble(),
  paymentTerms: (json['paymentTerms'] as num).toInt(),
  monthlyPayment: (json['monthlyPayment'] as num).toDouble(),
  serviceFee: (json['serviceFee'] as num).toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  details: json['details'] == null
      ? null
      : ApplicationDetails.fromJson(json['details'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ApplicationToJson(Application instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerId': instance.customerId,
      'productId': instance.productId,
      'status': instance.status,
      'orderAmount': instance.orderAmount,
      'downPayment': instance.downPayment,
      'paymentTerms': instance.paymentTerms,
      'monthlyPayment': instance.monthlyPayment,
      'serviceFee': instance.serviceFee,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'details': instance.details,
    };

ApplicationDetails _$ApplicationDetailsFromJson(Map<String, dynamic> json) =>
    ApplicationDetails(
      personalInfo: PersonalInfo.fromJson(
        json['personalInfo'] as Map<String, dynamic>,
      ),
      addressInfo: AddressInfo.fromJson(
        json['addressInfo'] as Map<String, dynamic>,
      ),
      jobInfo: JobInfo.fromJson(json['jobInfo'] as Map<String, dynamic>),
      guarantorInfo: GuarantorInfo.fromJson(
        json['guarantorInfo'] as Map<String, dynamic>,
      ),
      machineInfo: MachineInfo.fromJson(
        json['machineInfo'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ApplicationDetailsToJson(ApplicationDetails instance) =>
    <String, dynamic>{
      'personalInfo': instance.personalInfo,
      'addressInfo': instance.addressInfo,
      'jobInfo': instance.jobInfo,
      'guarantorInfo': instance.guarantorInfo,
      'machineInfo': instance.machineInfo,
    };

PersonalInfo _$PersonalInfoFromJson(Map<String, dynamic> json) => PersonalInfo(
  nidNumber: json['nidNumber'] as String,
  fullName: json['fullName'] as String,
  dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
  gender: json['gender'] as String,
  nidFrontImage: json['nidFrontImage'] as String?,
  nidBackImage: json['nidBackImage'] as String?,
);

Map<String, dynamic> _$PersonalInfoToJson(PersonalInfo instance) =>
    <String, dynamic>{
      'nidNumber': instance.nidNumber,
      'fullName': instance.fullName,
      'dateOfBirth': instance.dateOfBirth.toIso8601String(),
      'gender': instance.gender,
      'nidFrontImage': instance.nidFrontImage,
      'nidBackImage': instance.nidBackImage,
    };

AddressInfo _$AddressInfoFromJson(Map<String, dynamic> json) => AddressInfo(
  division: json['division'] as String,
  district: json['district'] as String,
  upazila: json['upazila'] as String,
  addressDetails: json['addressDetails'] as String,
  permanentDivision: json['permanentDivision'] as String,
  permanentDistrict: json['permanentDistrict'] as String,
  permanentUpazila: json['permanentUpazila'] as String,
  permanentUnion: json['permanentUnion'] as String,
  permanentAddressDetails: json['permanentAddressDetails'] as String,
);

Map<String, dynamic> _$AddressInfoToJson(AddressInfo instance) =>
    <String, dynamic>{
      'division': instance.division,
      'district': instance.district,
      'upazila': instance.upazila,
      'addressDetails': instance.addressDetails,
      'permanentDivision': instance.permanentDivision,
      'permanentDistrict': instance.permanentDistrict,
      'permanentUpazila': instance.permanentUpazila,
      'permanentUnion': instance.permanentUnion,
      'permanentAddressDetails': instance.permanentAddressDetails,
    };

JobInfo _$JobInfoFromJson(Map<String, dynamic> json) => JobInfo(
  occupation: json['occupation'] as String,
  companyName: json['companyName'] as String,
  workCertifier: json['workCertifier'] as String,
  certifierName: json['certifierName'] as String,
  certifierPhone: json['certifierPhone'] as String,
  monthlyIncome: (json['monthlyIncome'] as num).toDouble(),
  workIdFrontImage: json['workIdFrontImage'] as String?,
  workIdBackImage: json['workIdBackImage'] as String?,
  officeAddress: json['officeAddress'] as String?,
);

Map<String, dynamic> _$JobInfoToJson(JobInfo instance) => <String, dynamic>{
  'occupation': instance.occupation,
  'companyName': instance.companyName,
  'workCertifier': instance.workCertifier,
  'certifierName': instance.certifierName,
  'certifierPhone': instance.certifierPhone,
  'monthlyIncome': instance.monthlyIncome,
  'workIdFrontImage': instance.workIdFrontImage,
  'workIdBackImage': instance.workIdBackImage,
  'officeAddress': instance.officeAddress,
};

GuarantorInfo _$GuarantorInfoFromJson(Map<String, dynamic> json) =>
    GuarantorInfo(
      relationship: json['relationship'] as String,
      nidNumber: json['nidNumber'] as String,
      fullName: json['fullName'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      phoneNumber: json['phoneNumber'] as String,
      maritalStatus: json['maritalStatus'] as String,
      presentAddress: json['presentAddress'] as String,
      permanentAddress: json['permanentAddress'] as String,
      nidFrontImage: json['nidFrontImage'] as String?,
      nidBackImage: json['nidBackImage'] as String?,
    );

Map<String, dynamic> _$GuarantorInfoToJson(GuarantorInfo instance) =>
    <String, dynamic>{
      'relationship': instance.relationship,
      'nidNumber': instance.nidNumber,
      'fullName': instance.fullName,
      'dateOfBirth': instance.dateOfBirth.toIso8601String(),
      'phoneNumber': instance.phoneNumber,
      'maritalStatus': instance.maritalStatus,
      'presentAddress': instance.presentAddress,
      'permanentAddress': instance.permanentAddress,
      'nidFrontImage': instance.nidFrontImage,
      'nidBackImage': instance.nidBackImage,
    };

MachineInfo _$MachineInfoFromJson(Map<String, dynamic> json) => MachineInfo(
  imei1: json['imei1'] as String,
  imei2: json['imei2'] as String,
  imeiImage: json['imeiImage'] as String?,
);

Map<String, dynamic> _$MachineInfoToJson(MachineInfo instance) =>
    <String, dynamic>{
      'imei1': instance.imei1,
      'imei2': instance.imei2,
      'imeiImage': instance.imeiImage,
    };

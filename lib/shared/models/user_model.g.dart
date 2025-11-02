// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  username: json['username'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  fullName: json['fullName'] as String,
  profileImage: json['profileImage'] as String?,
  role: json['role'] as String,
  shopId: json['shopId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'phone': instance.phone,
  'fullName': instance.fullName,
  'profileImage': instance.profileImage,
  'role': instance.role,
  'shopId': instance.shopId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  username: json['username'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

CustomerLoginResult _$CustomerLoginResultFromJson(Map<String, dynamic> json) =>
    CustomerLoginResult(
      id: json['id'] as String,
      username: json['username'] as String,
      shopId: json['shopId'] as String,
      roleName: json['roleName'] as String,
    );

Map<String, dynamic> _$CustomerLoginResultToJson(
  CustomerLoginResult instance,
) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'shopId': instance.shopId,
  'roleName': instance.roleName,
};

CustomerLoginResponse _$CustomerLoginResponseFromJson(
  Map<String, dynamic> json,
) => CustomerLoginResponse(
  response: json['response'] as String,
  message: json['message'] as String,
  status: (json['status'] as num).toInt(),
  result: CustomerLoginResult.fromJson(json['result'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CustomerLoginResponseToJson(
  CustomerLoginResponse instance,
) => <String, dynamic>{
  'response': instance.response,
  'message': instance.message,
  'status': instance.status,
  'result': instance.result,
};

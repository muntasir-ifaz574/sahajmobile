import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String username;
  final String email;
  final String phone;
  final String fullName;
  final String? profileImage;
  final String role;
  final String? shopId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.fullName,
    this.profileImage,
    required this.role,
    this.shopId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

class LoginResponse {
  final User user;

  const LoginResponse({required this.user});
}

// Real API response models for the new login endpoint
@JsonSerializable()
class CustomerLoginResult {
  final String id;
  final String username;
  final String shopId;
  final String roleName;

  const CustomerLoginResult({
    required this.id,
    required this.username,
    required this.shopId,
    required this.roleName,
  });

  factory CustomerLoginResult.fromJson(Map<String, dynamic> json) =>
      _$CustomerLoginResultFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerLoginResultToJson(this);
}

@JsonSerializable()
class CustomerLoginResponse {
  final String response;
  final String message;
  final int status;
  final CustomerLoginResult result;

  const CustomerLoginResponse({
    required this.response,
    required this.message,
    required this.status,
    required this.result,
  });

  factory CustomerLoginResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerLoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerLoginResponseToJson(this);
}

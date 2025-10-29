import 'package:dio/dio.dart';
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/division_model.dart';
import '../models/district_model.dart';
import '../models/thana_model.dart';
import 'storage_service.dart';

class ApiService {
  static final Dio _dio = Dio();

  static void initialize() {
    _dio.options.baseUrl = AppConstants.baseUrl + AppConstants.apiVersion;
    _dio.options.connectTimeout = Duration(
      milliseconds: AppConstants.connectTimeout,
    );
    _dio.options.receiveTimeout = Duration(
      milliseconds: AppConstants.receiveTimeout,
    );

    // Add interceptors
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          final token = _getStoredToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Handle unauthorized access
            _clearStoredToken();
          }
          handler.next(error);
        },
      ),
    );
  }

  static String? _getStoredToken() {
    // Get token from secure storage
    return null; // Will be implemented with async call
  }

  static void _clearStoredToken() {
    // Clear token from secure storage
    StorageService.clearToken();
  }

  static void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Auth endpoints
  static Future<bool> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/customer_login',
        data: FormData.fromMap({
          'username': request.username,
          'password': request.password,
        }),
      );
      // Backend sometimes returns JSON with content-type text/html
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);
      final status = data['status'] as int?;
      if (status == 1) {
        final result = data['result'] as Map<String, dynamic>;
        final shopId = (result['shop_id'] ?? result['shopId'])?.toString();
        final username = result['username']?.toString();

        if (shopId != null && username != null) {
          await StorageService.storeShopId(shopId);
          await StorageService.storeUsername(username);
          await StorageService.setLoggedIn(true);
          return true;
        }
        throw Exception('Invalid response structure');
      } else {
        final message = data['message']?.toString() ?? 'Login failed';
        throw Exception(message);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> logout() async {
    try {
      // Clear all stored data
      await StorageService.clearAll();
      await StorageService.setLoggedIn(false);
      clearAuthToken();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<User> getProfile() async {
    try {
      // Get stored user data
      final shopId = await StorageService.getShopId();
      final username = await StorageService.getUsername();

      if (shopId != null && username != null) {
        return User(
          id: '1', // Default ID since not stored
          username: username,
          email: '$username@sahajmobile.org',
          phone: '', // Not stored
          fullName: username,
          role: 'Shop', // Default role
          shopId: shopId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        throw Exception('No user data found');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  static Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'An error occurred';
        return Exception('Error $statusCode: $message');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.connectionError:
        return Exception('No internet connection');
      default:
        return Exception('An unexpected error occurred');
    }
  }

  // Installment endpoints
  static Future<List<String>> getBrands({required String shopId}) async {
    try {
      final response = await _dio.post(
        '/get_brand',
        data: FormData.fromMap({'shop_id': shopId}),
      );
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);
      if ((data['status'] as int?) == 1) {
        final result = data['result'] as Map<String, dynamic>;
        final List<dynamic> brands = (result['brand'] as List<dynamic>? ?? []);
        return brands.map((e) => e.toString()).toList();
      }
      throw Exception(data['message']?.toString() ?? 'Failed to load brands');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, String>>> getModels({
    required String brand,
  }) async {
    try {
      final response = await _dio.post(
        '/get_model',
        data: FormData.fromMap({'brand_name': brand}),
      );
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);
      if ((data['status'] as int?) == 1) {
        final List<dynamic> result = data['result'] as List<dynamic>;
        return result
            .map(
              (e) => {
                'description': e['description']?.toString() ?? '',
                'price': e['price']?.toString() ?? '',
              },
            )
            .toList();
      }
      throw Exception(data['message']?.toString() ?? 'Failed to load models');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<String>> getPaymentTerms() async {
    try {
      final response = await _dio.post(
        '/get_month',
        data: FormData.fromMap({'username': 'retail', 'password': 'retail'}),
      );
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);
      if ((data['status'] as int?) == 1) {
        final result = data['result'];
        if (result is List) {
          // API returns list of { id, name }
          return result
              .map(
                (e) => e is Map ? (e['name']?.toString() ?? '') : e.toString(),
              )
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
      throw Exception(data['message']?.toString() ?? 'Failed to load terms');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, double>> getCharges() async {
    try {
      final response = await _dio.post(
        '/get_charge',
        data: FormData.fromMap({'username': 'retail', 'password': 'retail'}),
      );
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);
      if ((data['status'] as int?) == 1) {
        final List<dynamic> result = data['result'] as List<dynamic>;
        if (result.isNotEmpty && result.first is Map) {
          final m = result.first as Map<String, dynamic>;
          double parseNum(String key) =>
              double.tryParse(m[key]?.toString() ?? '0') ?? 0.0;
          return {
            'down_pmt_percent': parseNum('down_pmt_percent'),
            'upcharge_percent': parseNum('upcharge_percent'),
            'bkash_charge': parseNum('bkash_charge'),
            'loss_reserve_percent': parseNum('loss_reserve_percent'),
            'phone_expense': parseNum('phone_expense'),
          };
        }
      }
      throw Exception(data['message']?.toString() ?? 'Failed to load charges');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Division>> getDivisions() async {
    try {
      final response = await _dio.post('/get_divisions');
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);
      if ((data['status'] as int?) == 1) {
        final List<dynamic> result = data['result'] as List<dynamic>;
        return result
            .whereType<Map<String, dynamic>>()
            .map((e) => Division.fromJson(e))
            .toList();
      }
      throw Exception(
        data['message']?.toString() ?? 'Failed to load divisions',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<District>> getDistricts({
    required String datadivisionId,
  }) async {
    try {
      final response = await _dio.post(
        '/get_districts',
        data: {'division_id': datadivisionId},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);

      if ((data['status'] as int?) == 1) {
        final List<dynamic> result = data['result'] as List<dynamic>;

        final districts = result
            .whereType<Map<String, dynamic>>()
            .map((e) => District.fromJson(e))
            .toList();

        return districts;
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to load districts',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Thana>> getThanas({required String districtId}) async {
    try {
      final response = await _dio.post(
        '/get_thanas',
        data: {'district_id': districtId},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);

      if ((data['status'] as int?) == 1) {
        final List<dynamic> result = data['result'] as List<dynamic>;

        final thanas = result
            .whereType<Map<String, dynamic>>()
            .map((e) => Thana.fromJson(e))
            .toList();

        return thanas;
      }

      throw Exception(data['message']?.toString() ?? 'Failed to load thanas');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      rethrow;
    }
  }
}

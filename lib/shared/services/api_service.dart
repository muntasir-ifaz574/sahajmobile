import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/division_model.dart';
import '../models/district_model.dart';
import '../models/thana_model.dart';
import '../models/union_model.dart';
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

  // Application submission (multipart/form-data)
  static Future<Map<String, dynamic>> submitApplication({
    required Map<String, dynamic> textFields,
    Map<String, String?> filePaths = const {},
  }) async {
    try {
      developer.log(
        '=== Starting customer_verify_and_save API call ===',
        name: 'ApiService',
      );

      final Map<String, dynamic> payload = {...textFields};

      // Verify and attach files with detailed logging
      final List<String> uploadedFiles = [];
      final List<String> missingFiles = [];
      final List<String> invalidFiles = [];

      developer.log(
        'Total file fields expected: ${filePaths.length}',
        name: 'ApiService',
      );

      for (final entry in filePaths.entries) {
        final String fieldName = entry.key;
        final String? path = entry.value;

        developer.log(
          'Processing file field: $fieldName, path: ${path ?? "null"}',
          name: 'ApiService',
        );

        if (path == null || path.isEmpty) {
          missingFiles.add(fieldName);
          developer.log(
            'WARNING: File field "$fieldName" is null or empty - skipping',
            name: 'ApiService',
            level: 900,
          );
          continue;
        }

        // Check if file exists
        final file = File(path);
        if (!await file.exists()) {
          invalidFiles.add('$fieldName: File does not exist at path: $path');
          developer.log(
            'ERROR: File for field "$fieldName" does not exist at path: $path',
            name: 'ApiService',
            level: 1000,
          );
          continue;
        }

        // Get file information
        final fileStat = await file.stat();
        final fileSize = fileStat.size;
        final fileName = path.split('/').isNotEmpty
            ? path.split('/').last
            : 'upload';

        developer.log(
          'File "$fieldName" exists: ✓\n'
          '  - Path: $path\n'
          '  - Filename: $fileName\n'
          '  - Size: ${fileSize} bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)',
          name: 'ApiService',
        );

        // Verify file size is greater than 0
        if (fileSize == 0) {
          invalidFiles.add('$fieldName: File is empty (0 bytes)');
          developer.log(
            'ERROR: File for field "$fieldName" is empty (0 bytes)',
            name: 'ApiService',
            level: 1000,
          );
          continue;
        }

        try {
          // Create MultipartFile
          final multipartFile = await MultipartFile.fromFile(
            path,
            filename: fileName,
          );

          payload[fieldName] = multipartFile;
          uploadedFiles.add('$fieldName: $fileName (${fileSize} bytes)');

          developer.log(
            'Successfully attached file "$fieldName" to payload',
            name: 'ApiService',
          );
        } catch (e) {
          invalidFiles.add('$fieldName: Failed to create MultipartFile - $e');
          developer.log(
            'ERROR: Failed to create MultipartFile for "$fieldName": $e',
            name: 'ApiService',
            level: 1000,
          );
        }
      }

      // Log summary of file upload status
      developer.log(
        '\n=== File Upload Summary ===\n'
        'Successfully uploaded files (${uploadedFiles.length}):\n'
        '${uploadedFiles.isEmpty ? "  None" : uploadedFiles.map((f) => "  ✓ $f").join("\n")}\n\n'
        'Missing/Empty files (${missingFiles.length}):\n'
        '${missingFiles.isEmpty ? "  None" : missingFiles.map((f) => "  ✗ $f").join("\n")}\n\n'
        'Invalid files (${invalidFiles.length}):\n'
        '${invalidFiles.isEmpty ? "  None" : invalidFiles.map((f) => "  ✗ $f").join("\n")}\n'
        '==========================',
        name: 'ApiService',
        level: invalidFiles.isNotEmpty || uploadedFiles.isEmpty ? 1000 : 500,
      );

      // Warn if critical files are missing
      final criticalFields = [
        'front_nid',
        'back_nid',
        'work_certifier',
        'gaurantor_front_nid',
        'gaurantor_back_nid',
      ];
      final missingCritical = criticalFields
          .where((field) => !uploadedFiles.any((f) => f.startsWith(field)))
          .toList();

      if (missingCritical.isNotEmpty) {
        developer.log(
          'WARNING: Missing critical files: ${missingCritical.join(", ")}',
          name: 'ApiService',
          level: 1000,
        );
      }

      final formData = FormData.fromMap(payload);

      // Log text fields summary (without sensitive data)
      final textFieldKeys = textFields.keys.toList();
      developer.log(
        'Text fields in payload (${textFieldKeys.length}): ${textFieldKeys.join(", ")}',
        name: 'ApiService',
      );

      // Log FormData structure
      developer.log(
        'FormData created with:\n'
        '  - Text fields: ${formData.fields.length}\n'
        '  - File fields: ${formData.files.length}',
        name: 'ApiService',
      );

      // Log file details from FormData
      for (final fileEntry in formData.files) {
        developer.log(
          'FormData file: ${fileEntry.key} -> ${fileEntry.value.filename} '
          '(${fileEntry.value.length} bytes)',
          name: 'ApiService',
        );
      }

      developer.log(
        'Sending POST request to /customer_verify_and_save...',
        name: 'ApiService',
      );

      final response = await _dio.post(
        '/customer_verify_and_save',
        data: formData,
      );

      developer.log(
        'API Response received:\n'
        '  - Status Code: ${response.statusCode}\n'
        '  - Headers: ${response.headers.map}',
        name: 'ApiService',
      );

      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);

      developer.log(
        'API Response parsed successfully:\n'
        '  - Status: ${data['status']}\n'
        '  - Message: ${data['message'] ?? "N/A"}',
        name: 'ApiService',
      );

      developer.log(
        '=== customer_verify_and_save API call completed ===',
        name: 'ApiService',
      );

      return data;
    } on DioException catch (e) {
      developer.log(
        'ERROR in customer_verify_and_save API:\n'
        '  - Type: ${e.type}\n'
        '  - Message: ${e.message}\n'
        '  - Response: ${e.response?.data}\n'
        '  - Status Code: ${e.response?.statusCode}',
        name: 'ApiService',
        level: 1000,
        error: e,
        stackTrace: e.stackTrace,
      );
      throw _handleError(e);
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected ERROR in customer_verify_and_save API: $e',
        name: 'ApiService',
        level: 1000,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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

  /// Get payment terms as a list of maps with 'id' and 'name' keys
  static Future<List<Map<String, String>>> getPaymentTerms() async {
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
              .whereType<Map<String, dynamic>>()
              .map(
                (e) => {
                  'id': e['id']?.toString() ?? '',
                  'name': e['name']?.toString() ?? '',
                },
              )
              .where((e) => e['id']!.isNotEmpty && e['name']!.isNotEmpty)
              .toList();
        }
      }
      throw Exception(data['message']?.toString() ?? 'Failed to load terms');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get payment terms as a simple list of names (for backward compatibility)
  static Future<List<String>> getPaymentTermNames() async {
    final terms = await getPaymentTerms();
    return terms.map((e) => e['name']!).toList();
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

  static Future<List<UnionModel>> getUnions({
    required String upazillaId,
  }) async {
    try {
      final response = await _dio.post(
        '/get_unions',
        data: {'upazilla_id': upazillaId},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);

      if ((data['status'] as int?) == 1) {
        final List<dynamic> result = data['result'] as List<dynamic>;

        final unions = result
            .whereType<Map<String, dynamic>>()
            .map((e) => UnionModel.fromJson(e))
            .toList();

        return unions;
      }

      throw Exception(data['message']?.toString() ?? 'Failed to load unions');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      rethrow;
    }
  }

  // Dashboard summary
  static Future<Map<String, int>> getDashboardCounts() async {
    try {
      final shopId = await StorageService.getShopId();
      final response = await _dio.post(
        '/get_dashboard',
        data: FormData.fromMap({if (shopId != null) 'shop_id': shopId}),
      );
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);
      if ((data['status'] as int?) == 1) {
        final result = data['result'] as Map<String, dynamic>;
        int parseInt(String key) =>
            int.tryParse(result[key]?.toString() ?? '0') ?? 0;
        return {
          'tot_pending_cust': parseInt('tot_pending_cust'),
          'tot_approve_cust': parseInt('tot_approve_cust'),
          'tot_disapprove_cust': parseInt('tot_disapprove_cust'),
        };
      }
      throw Exception(
        data['message']?.toString() ?? 'Failed to load dashboard',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get customer shop list
  static Future<List<Map<String, dynamic>>> getCustomerShopList() async {
    try {
      final shopId = await StorageService.getShopId();
      final response = await _dio.post(
        '/get_customer_shop_list',
        data: FormData.fromMap({if (shopId != null) 'shop_id': shopId}),
      );
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : (raw as Map<String, dynamic>);
      if ((data['status'] as int?) == 1) {
        final result = data['result'] as List<dynamic>;
        return result
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      throw Exception(
        data['message']?.toString() ?? 'Failed to load customer list',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}

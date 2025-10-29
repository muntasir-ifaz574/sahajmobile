import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Auth token storage
  static Future<void> storeToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  // Shop ID storage
  static Future<void> storeShopId(String shopId) async {
    await _storage.write(key: 'shop_id', value: shopId);
  }

  static Future<String?> getShopId() async {
    return await _storage.read(key: 'shop_id');
  }

  static Future<void> clearShopId() async {
    await _storage.delete(key: 'shop_id');
  }

  // Username storage
  static Future<void> storeUsername(String username) async {
    await _storage.write(key: 'username', value: username);
  }

  static Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  static Future<void> clearUsername() async {
    await _storage.delete(key: 'username');
  }

  // User data storage
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: AppConstants.userKey, value: userData.toString());
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: AppConstants.userKey);
    if (data != null) {
      // Parse the stored data - you might want to use JSON encoding/decoding
      return {'raw_data': data};
    }
    return null;
  }

  static Future<void> clearUserData() async {
    await _storage.delete(key: AppConstants.userKey);
  }

  // Onboarding completion storage
  static Future<void> setOnboardingCompleted() async {
    await _storage.write(key: AppConstants.onboardingKey, value: 'true');
  }

  static Future<bool> isOnboardingCompleted() async {
    final value = await _storage.read(key: AppConstants.onboardingKey);
    return value == 'true';
  }

  static Future<void> clearOnboardingStatus() async {
    await _storage.delete(key: AppConstants.onboardingKey);
  }

  // Clear all stored data
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final status = await _storage.read(key: 'logged_in');
    if (status != null) {
      return status == 'true';
    }
    // Fallback: treat presence of essential fields as logged-in
    final shopId = await getShopId();
    final username = await getUsername();
    return shopId != null && username != null;
  }

  // Explicit login status flag
  static Future<void> setLoggedIn(bool value) async {
    await _storage.write(key: 'logged_in', value: value ? 'true' : 'false');
  }
}

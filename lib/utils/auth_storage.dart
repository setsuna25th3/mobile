import 'package:get_storage/get_storage.dart';

class AuthStorage {
  static const String _adminLoggedInKey = 'admin_logged_in';
  static const String _adminEmailKey = 'admin_email';
  
  static final _storage = GetStorage();

  // Check if admin is logged in
  static bool isAdminLoggedIn() {
    return _storage.read(_adminLoggedInKey) ?? false;
  }

  // Set admin login status
  static void setAdminLoggedIn(bool isLoggedIn) {
    _storage.write(_adminLoggedInKey, isLoggedIn);
  }

  // Admin logout
  static void adminLogout() {
    _storage.remove(_adminLoggedInKey);
    _storage.remove(_adminEmailKey);
  }

  // Get admin email
  static String? getAdminEmail() {
    return _storage.read(_adminEmailKey);
  }

  // Set admin email
  static void setAdminEmail(String email) {
    _storage.write(_adminEmailKey, email);
  }

  // Clear all auth data
  static void clearAuth() {
    _storage.remove(_adminLoggedInKey);
    _storage.remove(_adminEmailKey);
  }
} 
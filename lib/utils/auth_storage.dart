import 'package:get_storage/get_storage.dart';

class AuthStorage {
  static final GetStorage _storage = GetStorage();
  
  // Keys
  static const String _keyIsAdminLoggedIn = 'isAdminLoggedIn';
  static const String _keyAdminEmail = 'adminEmail';
  
  // Lưu trạng thái đăng nhập admin
  static Future<void> saveAdminLoginState(bool isLoggedIn, String email) async {
    try {
      print('saveAdminLoginState: Lưu trạng thái đăng nhập: $isLoggedIn, email: $email');
      await _storage.write(_keyIsAdminLoggedIn, isLoggedIn);
      await _storage.write(_keyAdminEmail, email);
      print('saveAdminLoginState: Đã lưu thành công');
    } catch (e) {
      print('saveAdminLoginState: Lỗi khi lưu trạng thái đăng nhập: $e');
    }
  }
  
  // Kiểm tra trạng thái đăng nhập admin
  static bool isAdminLoggedIn() {
    try {
      final result = _storage.read(_keyIsAdminLoggedIn) ?? false;
      print('isAdminLoggedIn: Kết quả kiểm tra: $result');
      return result;
    } catch (e) {
      print('isAdminLoggedIn: Lỗi khi kiểm tra trạng thái đăng nhập: $e');
      return false;
    }
  }
  
  // Lấy email của admin đã đăng nhập
  static String? getAdminEmail() {
    try {
      final email = _storage.read(_keyAdminEmail);
      print('getAdminEmail: Email admin đã lưu: $email');
      return email;
    } catch (e) {
      print('getAdminEmail: Lỗi khi lấy email admin: $e');
      return null;
    }
  }
  
  // Đăng xuất admin
  static Future<void> adminLogout() async {
    try {
      print('adminLogout: Đang đăng xuất admin');
      await _storage.write(_keyIsAdminLoggedIn, false);
      await _storage.remove(_keyAdminEmail);
      print('adminLogout: Đã xóa trạng thái đăng nhập');
    } catch (e) {
      print('adminLogout: Lỗi khi đăng xuất: $e');
    }
  }
} 
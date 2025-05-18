import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../config.dart';
import '../../utils/auth_storage.dart';
import 'admin_dashboard.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    // Pre-fill admin credentials for easier testing
    _emailController.text = AppConfig.adminEmail;
    _passwordController.text = AppConfig.adminPassword;
  }

  // Kiểm tra trạng thái đăng nhập khi mở ứng dụng
  Future<void> _checkLoginStatus() async {
    if (AuthStorage.isAdminLoggedIn()) {
      // Nếu đã đăng nhập, chuyển đến trang dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Đang đăng nhập với email: ${_emailController.text}');
      
      // Đơn giản hoá việc xác thực: kiểm tra chính xác thông tin đăng nhập từ config
      if (_emailController.text == AppConfig.adminEmail && 
          _passwordController.text == AppConfig.adminPassword) {
        
        print('Thông tin đăng nhập admin khớp với cấu hình');
        
        // Lưu trạng thái đăng nhập admin
        await AuthStorage.saveAdminLoginState(true, _emailController.text);
        
        print('Đăng nhập thành công, chuyển đến trang dashboard');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      } else {
        setState(() {
          _errorMessage = 'Email hoặc mật khẩu không đúng';
        });
      }
    } catch (e) {
      print('Lỗi khi đăng nhập: $e');
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Đăng nhập Admin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Đăng Nhập'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
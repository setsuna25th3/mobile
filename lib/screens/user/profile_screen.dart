import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'home_screen.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = SupabaseService.getCurrentUserId();
      if (userId != null) {
        // Đảm bảo trường address tồn tại
        await SupabaseService.ensureUserProfileHasAddressField(userId);
      }
      
      final user = await SupabaseService.getCurrentUser();
      if (user != null) {
        _nameController.text = user['full_name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _emailController.text = user['email'] ?? '';
        _addressController.text = user['address'] ?? '';
        
        print('Đã tải địa chỉ: ${_addressController.text}');
      }
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final userId = SupabaseService.getCurrentUserId();
    if (userId == null) return;
    
    try {
      // Đảm bảo trường address tồn tại
      await SupabaseService.ensureUserProfileHasAddressField(userId);
      
      final Map<String, dynamic> profileData = {
        'full_name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text, // Luôn đưa address vào, ngay cả khi trống
      };
      
      // In thông tin dữ liệu trước khi cập nhật
      print('Dữ liệu cập nhật: $profileData');
      
      await SupabaseService.updateUserProfile(userId, profileData);
      
      // Kiểm tra xem đã cập nhật thành công chưa
      final updatedUser = await SupabaseService.getCurrentUser();
      print('Dữ liệu sau khi cập nhật: $updatedUser');
      print('Địa chỉ sau khi cập nhật: ${updatedUser?['address']}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
      }
    } catch (e) {
      print('Lỗi khi cập nhật profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    // Clear the cart data using GetX controller
    if (Get.isRegistered<ProductController>()) {
      final productController = Get.find<ProductController>();
      await productController.xoahet(); // Clear the cart
    }
    
    // Then logout
    await SupabaseService.signOut();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePageFood()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Họ tên'),
                        validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập họ tên' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Số điện thoại'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Địa chỉ'),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Cập nhật thông tin'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _logout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Đăng xuất'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
} 
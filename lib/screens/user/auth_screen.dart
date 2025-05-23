import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'home_screen.dart';

class PageAuthUser extends StatelessWidget {
  const PageAuthUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đăng nhập"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.restaurant, size: 120, color: Colors.green),
          const SizedBox(height: 32),
          const Text('Cửa hàng đồ ăn KTX', textAlign: TextAlign.center, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 12),
          const Text('Đăng nhập bằng email', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 48),
          
          SupaEmailAuth(
            redirectTo: null,
            onSignInComplete: (response) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomePageFood())),
            onSignUpComplete: (response) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomePageFood())),
            onPasswordResetEmailSent: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã gửi email reset mật khẩu!'), backgroundColor: Colors.green)),
            metadataFields: [
              MetaDataField(
                prefixIcon: const Icon(Icons.person),
                label: 'Họ và tên',
                key: 'full_name',
                validator: (val) => val?.isEmpty == true ? 'Nhập họ tên' : null,
              ),
              MetaDataField(prefixIcon: const Icon(Icons.phone), label: 'Số điện thoại', key: 'phone'),
            ],
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}


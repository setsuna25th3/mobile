import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'admin_dashboard.dart';
import '../../utils/auth_storage.dart';

class AdminAuthScreen extends StatelessWidget {
  const AdminAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          
          if (session != null) {
            // Đã đăng nhập -> lưu session và chuyển dashboard
            AuthStorage.setAdminLoggedIn(true);
            return const AdminDashboard();
          }
          
          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Admin Icon
              const Icon(
                Icons.admin_panel_settings,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Admin Panel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Email Auth for Admin
              SupaEmailAuth(
                redirectTo: null,
                onSignInComplete: (response) {
                  AuthStorage.setAdminLoggedIn(true);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const AdminDashboard()),
                  );
                },
                onSignUpComplete: (response) {
                  AuthStorage.setAdminLoggedIn(true);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const AdminDashboard()),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
} 
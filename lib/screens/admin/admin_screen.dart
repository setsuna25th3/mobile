import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'admin_login.dart';
import 'admin_dashboard.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: SupabaseService.isAdmin(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return (snapshot.hasData && snapshot.data == true)
          ? const AdminDashboard()
          : const AdminLogin();
    },
  );
} 
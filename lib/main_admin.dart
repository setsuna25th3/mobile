import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'services/supabase_service.dart';
import 'screens/admin/admin_auth_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'utils/auth_storage.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await SupabaseService.initialize();
  
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        title: AppConfig.adminAppTitle,
        theme: ThemeData(
          primaryColor: Color(AppConfig.primaryColorHex),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(AppConfig.primaryColorHex),
            secondary: Color(AppConfig.accentColorHex),
          ),
        ),
        home: AuthStorage.isAdminLoggedIn()
            ? const AdminDashboard()
            : const AdminAuthScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/admin-auth': (context) => const AdminAuthScreen(),
          '/admin-dashboard': (context) => const AdminDashboard(),
        },
      );
} 
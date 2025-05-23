import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'services/supabase_service.dart';
import 'screens/user/auth_screen.dart';
import 'screens/user/home_screen.dart';
import 'controllers/product_controller.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  
  runApp(const FoodStoreApp());
}

class FoodStoreApp extends StatelessWidget {
  const FoodStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.userAppTitle,
      debugShowCheckedModeBanner: false,
      initialBinding: FoodStoreBinding(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 3, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: HomePageFood(),
      routes: {
        '/login': (context) => const PageAuthUser(),
        '/home': (context) => HomePageFood(),
      },
    );
  }
}


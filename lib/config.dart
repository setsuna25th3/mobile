class AppConfig {
  // App settings
  static final bool isUser = true;
  
  // Supabase configuration - should be loaded from environment variables in production
  static const String supabaseUrl = 'https://mraocvqjtuzsxbqrrdsd.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1yYW9jdnFqdHV6c3hicXJyZHNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcxMjk1NzYsImV4cCI6MjA2MjcwNTU3Nn0.aJsRsc_xa7Mb5i3kODt790hUD2EzufftENulkeudxGY';
  
  // App title
  static const String userAppTitle = 'Cửa hàng Đồ ăn';
  static const String adminAppTitle = 'Admin Dashboard';
  
  // Theme colors
  static const int primaryColorHex = 0xFF4CAF50; // Green
  static const int accentColorHex = 0xFF2196F3; // Blue

  // Admin credentials - should be stored securely in production
  static const String adminEmail = 'admin@example.com';
  static const String adminPassword = 'admin123';
  
  // Hàm in thông tin cấu hình để debug
  static void printConfig() {
    print('==== APP CONFIG ====');
    print('Admin Email: $adminEmail');
    print('Admin Password: $adminPassword');
    print('Supabase URL: $supabaseUrl');
    print(' --------');
  }
} 
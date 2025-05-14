import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../config.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  // PHẦN XÁCH THỰC NGƯỜI DÙNG
  
  // Kiểm tra người dùng đã đăng nhập hay chưa
  static bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }
  
  // Lấy ID người dùng hiện tại
  static String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }
  
  // Lấy thông tin người dùng
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    
    final response = await supabase
      .from('user_profiles')
      .select('*')
      .eq('id', userId)
      .single();
      
    return response;
  }
  
  // Đăng nhập
  static Future<bool> signIn(String email, String password) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    return response.user != null;
  }
  
  // Đăng ký
  static Future<bool> signUp(String email, String password, String name, String phone) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    
    if (response.user != null) {
      // Tạo hồ sơ người dùng
      await supabase.from('user_profiles').insert({
        'id': response.user!.id,
        'full_name': name,
        'phone': phone,
        'role': 'user',
      });
      
      return true;
    }
    
    return false;
  }
  
  // Đăng xuất
  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }
  
  // PHẦN DÀNH CHO ỨNG DỤNG NGƯỜI DÙNG
  
  // Lấy danh sách sản phẩm theo danh mục
  static Future<List<Map<String, dynamic>>> getProductsByCategory(ProductCategory category) async {
    final response = await supabase
      .from('products')
      .select('*')
      .eq('category', category.toString().split('.').last)
      .order('created_at', ascending: false);
    
    return response;
  }
  
  // Lấy tất cả sản phẩm
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    final response = await supabase
      .from('products')
      .select('*')
      .order('created_at', ascending: false);
    
    return response;
  }
  
  // Tìm kiếm sản phẩm
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final response = await supabase
      .from('products')
      .select('*')
      .ilike('ten', '%$query%')
      .order('created_at', ascending: false);
    
    return response;
  }
  
  // Thêm sản phẩm vào giỏ hàng
  static Future<bool> addToCart(String productId, int quantity) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;
    
    try {
      // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
      final existingItem = await supabase
        .from('cart_items')
        .select('*')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
      
      if (existingItem != null) {
        // Cập nhật số lượng
        await supabase
          .from('cart_items')
          .update({'quantity': existingItem['quantity'] + quantity})
          .eq('id', existingItem['id']);
      } else {
        // Thêm mới vào giỏ hàng
        await supabase
          .from('cart_items')
          .insert({
            'user_id': userId,
            'product_id': productId,
            'quantity': quantity,
          });
      }
      
      return true;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }
  
  // Lấy danh sách sản phẩm trong giỏ hàng
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    
    final response = await supabase
      .from('cart_items')
      .select('*, products(*)')
      .eq('user_id', userId);
    
    return response;
  }
}

class MySupabaseConnect extends StatefulWidget {
  final String errorMessage;
  final String connectingMessage;
  final Widget Function(BuildContext context) builder;
  
  const MySupabaseConnect({
    Key? key,
    required this.errorMessage,
    required this.connectingMessage,
    required this.builder,
  }) : super(key: key);

  @override
  State<MySupabaseConnect> createState() => _MySupabaseConnectState();
}

class _MySupabaseConnectState extends State<MySupabaseConnect> {
  bool ketNoi = false;
  bool loi = false;
  
  @override
  Widget build(BuildContext context) {
    if(loi){
      return Container(
        color: Colors.white,
        child: Center(
          child: Text(widget.errorMessage,
          style: const TextStyle(fontSize: 16, color: Colors.red),
            textDirection: TextDirection.ltr,
          ),
        ),
      );
    } else if(ketNoi == false) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              Text(widget.connectingMessage,
                style: const TextStyle(fontSize: 16),
                textDirection: TextDirection.ltr,
              )
            ],
          ),
        ),
      );
    } else {
      return widget.builder(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _khoiTaoSupabase();
  }

  _khoiTaoSupabase() {
    SupabaseService.initialize().then((value) {
      setState(() {
        ketNoi = true;
      });
    }).catchError((error) {
      setState(() {
        loi = true;
      });
    }).whenComplete(() => {
      print("Hoàn tất kết nối Supabase")
    });
  }
} 
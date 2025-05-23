import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../controllers/product_controller.dart';
import '../config.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  // PHẦN AUTHENTICATION
  
  static bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }
  
  static String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }
  
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;
      
      // Thử lấy user profile từ database
      final userProfile = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
      
      // Nếu chưa có profile và user đã verify email, tạo profile từ auth metadata
      if (userProfile == null) {
        final user = supabase.auth.currentUser;
        if (user != null && user.emailConfirmedAt != null) {
          await _createUserProfileFromAuth();
          // Thử lấy lại sau khi tạo
          return await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', userId)
            .maybeSingle();
        }
      }
      
      return userProfile;
    } catch (e) {
      return null;
    }
  }
  
  // Tạo user profile từ auth metadata sau khi email được verify
  static Future<void> _createUserProfileFromAuth() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null || user.emailConfirmedAt == null) return;
      
      // Lấy metadata từ user auth
      final fullName = user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User';
      final phone = user.userMetadata?['phone'] ?? '';
      
      await supabase.from('user_profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'phone': phone,
        'role': 'user',
        'email': user.email,
      });
    } catch (e) {
      // Bỏ qua lỗi nếu profile đã tồn tại
    }
  }
  
  static Future<bool> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      return response.user != null;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> signOut() async {
    try {
      if (GetInstance().isRegistered<ProductController>()) {
        final productController = GetInstance().find<ProductController>();
        await productController.xoahet();
      }
    } catch (e) {
      // Ignore any errors with clearing cart
    }
    
    await supabase.auth.signOut();
  }
  
  // PHẦN SẢN PHẨM
  
  static Future<List<Map<String, dynamic>>> getProductsByCategory(ProductCategory category) async {
    try {
      return await supabase
        .from('products')
        .select('*')
        .eq('category', category.toString().split('.').last)
        .order('created_at', ascending: false);
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final response = await supabase
        .from('products')
        .select('*')
        .order('created_at', ascending: false);
        
      return response;
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      return await supabase
        .from('products')
        .select('*')
        .ilike('ten', '%$query%')
        .order('created_at', ascending: false);
    } catch (e) {
      return [];
    }
  }
  
  // PHẦN GIỎ HÀNG
  
  static Future<bool> addToCart(String productId, int quantity) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;
    
    try {
      // Đảm bảo user_profiles tồn tại trước khi thêm vào cart
      await _ensureUserProfileExists(userId);
      
      // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
      final existingItem = await supabase
        .from('cart_items')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
      
      if (existingItem != null) {
        // Cập nhật số lượng
        final newQuantity = (existingItem['quantity'] ?? 0) + quantity;
        await supabase
          .from('cart_items')
          .update({'quantity': newQuantity})
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
      return false;
    }
  }
  
  // Đảm bảo user profile tồn tại
  static Future<void> _ensureUserProfileExists(String userId) async {
    try {
      // Kiểm tra xem user profile đã tồn tại chưa
      final existingProfile = await supabase
        .from('user_profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
      
      if (existingProfile == null) {
        // Tạo user profile từ auth user
        await _createUserProfileFromAuth();
      }
    } catch (e) {
      // Bỏ qua lỗi
    }
  }
  
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    
    try {
      // Thử với foreign key constraint name cụ thể
      final response = await supabase
        .from('cart_items')
        .select('''
          *,
          products!cart_items_product_id_fkey(
            id,
            ten,
            gia,
            image,
            category,
            mota,
            stock
          )
        ''')
        .eq('user_id', userId);
      
      return response;
    } catch (e) {
      // Fallback: Thử với tên relationship khác
      try {
        final response = await supabase
          .from('cart_items')
          .select('''
            *,
            products!fk_product_id(
              id,
              ten,
              gia,
              image,
              category,
              mota,
              stock
            )
          ''')
          .eq('user_id', userId);
        
        return response;
      } catch (e2) {
        // Fallback: Lấy cart items và join manually
        final cartItems = await supabase
          .from('cart_items')
          .select('*')
          .eq('user_id', userId);
        
        // Manual join với products
        List<Map<String, dynamic>> result = [];
        for (var cartItem in cartItems) {
          try {
            final productId = cartItem['product_id'];
            final product = await supabase
              .from('products')
              .select('*')
              .eq('id', productId)
              .single();
            
            result.add({
              ...cartItem,
              'products': product,
            });
          } catch (productError) {
            // Keep cart item without product info
            result.add({
              ...cartItem,
              'products': null,
            });
          }
        }
        
        return result;
      }
    }
  }

  // PHẦN QUYỀN ADMIN
  
  static Future<bool> isAdmin() async {
    try {
      final user = await getCurrentUser();
      return user != null && user['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
  
  // PHẦN SẢN PHẨM - ADMIN
  
  static Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      Map<String, dynamic> cleanData = {};
      
      for (final key in ['ten', 'gia', 'image', 'category', 'mota', 'stock']) {
        if (productData[key] != null) {
          cleanData[key] = productData[key];
        }
      }
      
      await supabase
        .from('products')
        .update(cleanData)
        .eq('id', productId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await supabase
        .from('products')
        .insert(productData);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteProduct(String productId) async {
    try {
      await supabase
        .from('products')
        .delete()
        .eq('id', productId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<int> getProductCount() async {
    try {
      final response = await supabase
        .from('products')
        .select('id');
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // PHẦN ĐƠN HÀNG
  
  static Future<int> getOrderCount() async {
    try {
      final response = await supabase
        .from('orders')
        .select('id');
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      // Lấy tất cả orders với thông tin user
      return await supabase
        .from('orders')
        .select('''
          *,
          user_profiles!orders_user_profiles_fkey(
            id,
            full_name,
            phone,
            email
          )
        ''')
        .order('created_at', ascending: false);
    } catch (e) {
      // Fallback: Lấy orders đơn thuần
      try {
        return await supabase
          .from('orders')
          .select('*')
          .order('created_at', ascending: false);
      } catch (e2) {
        return [];
      }
    }
  }

  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      // Lấy order với full details sử dụng đúng relationships
      final orderResponse = await supabase
        .from('orders')
        .select('''
          *,
          user_profiles!orders_user_profiles_fkey(
            id,
            full_name,
            phone,
            email
          ),
          order_items!order_items_order_id_fkey(
            *,
            products!order_items_product_id_fkey(
              id,
              ten,
              gia,
              image,
              category
            )
          )
        ''')
        .eq('id', orderId)
        .single();
      
      return orderResponse;
    } catch (e) {
      // Fallback: Thử với tên relationship khác
      try {
        final orderResponse = await supabase
          .from('orders')
          .select('''
            *,
            user_profiles!orders_user_profiles_fkey(
              id,
              full_name,
              phone,
              email
            ),
            order_items!order_items_order_id_fkey(
              *,
              products!fk_product_id(
                id,
                ten,
                gia,
                image,
                category
              )
            )
          ''')
          .eq('id', orderId)
          .single();
        
        return orderResponse;
      } catch (e2) {
        // Fallback cuối: Lấy order đơn thuần
        return await supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();
      }
    }
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await supabase
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteOrder(String orderId) async {
    try {
      // Xóa các chi tiết đơn hàng trước
      await supabase
        .from('order_items')
        .delete()
        .eq('order_id', orderId);
      
      // Sau đó xóa đơn hàng
      await supabase
        .from('orders')
        .delete()
        .eq('id', orderId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await supabase
        .from('products')
        .update({'stock': newStock})
        .eq('id', productId);
    } catch (e) {
      rethrow;
    }
  }
  
  static Future<bool> checkProductInStock(String productId, int quantity) async {
    try {
      final response = await supabase
        .from('products')
        .select('stock')
        .eq('id', productId)
        .maybeSingle();
          
      if (response == null) return false;
      
      int currentStock = response['stock'] ?? 0;
      return currentStock >= quantity;
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      await supabase
        .from('user_profiles')
        .update(userData)
        .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }
  
  // Kiểm tra và cập nhật schema của user_profiles nếu cần
  static Future<void> ensureUserProfileHasAddressField(String userId) async {
    try {
      // Kiểm tra xem user_profiles đã có address chưa
      final user = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .single();
      
      // Cập nhật trực tiếp
      await supabase
        .from('user_profiles')
        .update({
          'address': user['address'] ?? '' // Giữ nguyên nếu đã có, không thì tạo rỗng
        })
        .eq('id', userId);
    } catch (e) {
      // Bỏ qua lỗi
    }
  }

  static Future<List<Map<String, dynamic>>> getOrdersByUser(String userId) async {
    try {
      // Lấy orders theo user_id với join đúng relationships
      final response = await supabase
        .from('orders')
        .select('''
          *,
          order_items!order_items_order_id_fkey(
            *,
            products!order_items_product_id_fkey(
              id,
              ten,
              gia,
              image,
              category
            )
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
      
      return response;
    } catch (e) {
      // Fallback: Thử với tên relationship khác
      try {
        final response = await supabase
          .from('orders')
          .select('''
            *,
            order_items!order_items_order_id_fkey(
              *,
              products!fk_product_id(
                id,
                ten,
                gia,
                image,
                category
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
        
        return response;
      } catch (e2) {
        // Fallback cuối: Lấy orders đơn thuần nếu join lỗi
        return await supabase
          .from('orders')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      }
    }
  }

  static Future<bool> testConnection() async {
    try {
      await supabase.from('products').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
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
    });
  }
  
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
} 
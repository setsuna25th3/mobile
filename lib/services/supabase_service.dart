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
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return null;
      }
      
      final response = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
        
      return response;
    } catch (e) {
      return null;
    }
  }
  
  // Đăng nhập
  static Future<bool> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
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
        'email': email,
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
    try {
      // Thử truy vấn từ các bảng khác nhau để xem bảng nào có dữ liệu
      List<String> possibleTableNames = ['products', 'product', 'mon_an', 'san_pham']; 
      List<Map<String, dynamic>> finalResponse = [];
      
      for (String tableName in possibleTableNames) {
        try {
          final response = await supabase
            .from(tableName)
            .select('*')
            .order('created_at', ascending: false); // Lấy tất cả sản phẩm thay vì giới hạn 10
          
          if (response.isNotEmpty) {
            finalResponse = response;
            break;
          }
        } catch (e) {
          // Bỏ qua lỗi và tiếp tục thử bảng khác
        }
      }
      
      if (finalResponse.isEmpty) {
        return [];
      }
      
      // Chuẩn hóa tên trường dữ liệu nếu cần
      List<Map<String, dynamic>> normalizedProducts = [];
      for (var product in finalResponse) {
        Map<String, dynamic> normalizedProduct = {...product};
        
        // Các tên trường có thể có
        final possibleImageFields = ['hinh_anh', 'image', 'anh'];
        final possibleDescFields = ['mo_ta', 'moTa', 'description', 'desc'];
        final possibleNameFields = ['ten', 'name', 'title'];
        final possiblePriceFields = ['gia', 'price'];
        
        // Chuẩn hóa trường hình ảnh
        for (var field in possibleImageFields) {
          if (product[field] != null) {
            normalizedProduct['hinh_anh'] = product[field];
            break;
          }
        }
        
        // Chuẩn hóa trường mô tả
        for (var field in possibleDescFields) {
          if (product[field] != null) {
            normalizedProduct['mo_ta'] = product[field];
            break;
          }
        }
        
        // Chuẩn hóa trường tên
        for (var field in possibleNameFields) {
          if (product[field] != null) {
            normalizedProduct['ten'] = product[field];
            break;
          }
        }
        
        // Chuẩn hóa trường giá
        for (var field in possiblePriceFields) {
          if (product[field] != null) {
            normalizedProduct['gia'] = product[field];
            break;
          }
        }
        
        normalizedProducts.add(normalizedProduct);
      }
      
      return normalizedProducts;
    } catch (e) {
      throw e;
    }
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
      // Kiểm tra tồn kho trước khi thêm vào giỏ hàng
      bool hasStock = await checkProductInStock(productId, quantity);
      if (!hasStock) {
        return false;
      }
      
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

  static Future<bool> isAdmin() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return false;
      }
      
      final user = await getCurrentUser();
      if (user == null) {
        return false;
      }
      
      final isAdminUser = user['role'] == 'admin';
      
      return isAdminUser;
    } catch (e) {
      return false;
    }
  }
  
  // Cập nhật sản phẩm
  static Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      // Đảm bảo chỉ có các trường hợp lệ trong database
      Map<String, dynamic> cleanData = {
        'ten': productData['ten'],
        'gia': productData['gia'],
        'image': productData['image'],
        'category': productData['category'],
        'mota': productData['mota'],
        'stock': productData['stock'],
      };
      
      // Loại bỏ các giá trị null
      cleanData.removeWhere((key, value) => value == null);
      
      await supabase
          .from('products')
          .update(cleanData)
          .eq('id', productId);
    } catch (e) {
      throw e;
    }
  }

  // Lấy số lượng sản phẩm
  static Future<int> getProductCount() async {
    try {
      final response = await supabase
        .from('products')
        .select();
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Lấy số lượng đơn hàng
  static Future<int> getOrderCount() async {
    try {
      final response = await supabase
        .from('orders')
        .select();
      return response.length;
    } catch (e) {
      // It's common for orders table to not exist initially or have a different name
      return 0;
    }
  }

  // Lấy số lượng người dùng
  static Future<int> getUserCount() async {
    try {
      final response = await supabase
        .from('user_profiles')
        .select();
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Thêm mới: Lấy danh sách tất cả người dùng
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      // Thử join với bảng auth.users để xem thông tin email
      try {
        final authJoin = await supabase.rpc('get_users_with_email');
        if (authJoin.isNotEmpty) {
          return authJoin;
        }
      } catch (e) {
        // Bỏ qua lỗi và tiếp tục thử bảng khác
      }
      
      // Thử truy vấn trực tiếp vào auth.users (chỉ hoạt động nếu có quyền admin)
      try {
        final authUsers = await supabase.from('auth.users').select('id, email').limit(5);
        return authUsers;
      } catch (e) {
        // Bỏ qua lỗi và tiếp tục thử bảng khác
      }
      
      // Lấy thông tin người dùng cơ bản từ user_profiles
      final response = await supabase
        .from('user_profiles')
        .select()
        .order('created_at', ascending: false);
      
      return response;
    } catch (e) {
      return [];
    }
  }

  // Thêm mới: Lấy danh sách tất cả đơn hàng
  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await supabase
        .from('orders')
        .select()
        .order('created_at', ascending: false);
      
      return response;
    } catch (e) {
      return [];
    }
  }

  // Thêm mới: Lấy chi tiết đơn hàng theo ID
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final response = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .single();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  // Thêm mới: Cập nhật trạng thái đơn hàng
  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await supabase
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
    } catch (e) {
      throw e;
    }
  }

  // Thêm mới: Xóa đơn hàng
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
      throw e;
    }
  }

  // Thêm mới: Cập nhật thông tin người dùng
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      await supabase
        .from('user_profiles')
        .update(userData)
        .eq('id', userId);
    } catch (e) {
      throw e;
    }
  }

  // Thêm mới: Xóa người dùng
  static Future<void> deleteUser(String userId) async {
    try {
      // Chỉ xóa profile người dùng
      await supabase
        .from('user_profiles')
        .delete()
        .eq('id', userId);
      
      // Lưu ý: Để xóa hoàn toàn tài khoản người dùng cần dùng Admin API của Supabase
    } catch (e) {
      throw e;
    }
  }

  // Thêm mới: Cập nhật chỉ số lượng tồn kho của sản phẩm
  static Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await supabase
          .from('products')
          .update({'stock': newStock})
          .eq('id', productId);
    } catch (e) {
      throw e;
    }
  }
  
  // Thêm mới: Kiểm tra sản phẩm có còn hàng không
  static Future<bool> checkProductInStock(String productId, int quantity) async {
    try {
      final response = await supabase
          .from('products')
          .select('stock')
          .eq('id', productId)
          .maybeSingle();
          
      if (response == null) {
        return false;
      }
      
      int currentStock = response['stock'] ?? 0;
      return currentStock >= quantity;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getOrdersByUser(String userId) async {
    final response = await supabase
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
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
    });
  }
} 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'product.dart';

class ProductSnapshot {
  Product product;
  String id;

  ProductSnapshot({
    required this.product,
    required this.id,
  });

  Map<String, dynamic> toMap() {
    return {
      'product': this.product.toJson(),
      'id': this.id,
    };
  }

  factory ProductSnapshot.fromMap(Map<String, dynamic> data) {
    try {
      return ProductSnapshot(
        product: Product.fromJson(data),
        id: data['id'].toString(),
      );
    } catch (e) {
      print('Lỗi khi chuyển đổi dữ liệu thành ProductSnapshot: $e');
      print('Dữ liệu: $data');
      rethrow;
    }
  }

  static Future<String> them(Product product) async {
    try {
      // Bỏ qua trường id để Supabase tự sinh
      final productData = product.toJson();
      
      print('Dữ liệu sản phẩm sẽ thêm: $productData');
      
      final response = await supabase
          .from('products')
          .insert(productData)
          .select()
          .single();
      
      print('Kết quả thêm sản phẩm: $response');
      
      return response['id'].toString();
    } catch (e) {
      print('Lỗi khi thêm sản phẩm: $e');
      rethrow;
    }
  }

  Future<void> capNhat(Product product) async {
    return supabase
        .from('products')
        .update(product.toJson())
        .eq('id', id);
  }
  
  Future<void> xoa() async {
    return supabase
        .from('products')
        .delete()
        .eq('id', id);
  }
  
  static Stream<List<ProductSnapshot>> getAll() {
    return supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .map((data) => 
          data.map((item) => ProductSnapshot.fromMap(item)).toList()
        );
  }

  static Stream<List<ProductSnapshot>> getByCategory(ProductCategory category) {
    return supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('category', category.toString().split('.').last)
        .map((data) => 
          data.map((item) => ProductSnapshot.fromMap(item)).toList()
        );
  }

  // Truy vấn data 1 lần
  static Future<List<ProductSnapshot>> getAll2() async {
    try {
      print('Đang truy vấn tất cả sản phẩm...');
      final data = await supabase
          .from('products')
          .select()
          .order('ten');
      
      print('Kết quả truy vấn từ Supabase: $data');
      
      return data.map<ProductSnapshot>((item) => 
        ProductSnapshot.fromMap(item)
      ).toList();
    } catch (e) {
      print('Lỗi khi lấy tất cả sản phẩm: $e');
      return [];
    }
  }
  
  // Truy vấn theo loại sản phẩm
  static Future<List<ProductSnapshot>> getByCategory2(ProductCategory category) async {
    try {
      print('Đang truy vấn sản phẩm theo loại ${category.toString()}...');
      final data = await supabase
          .from('products')
          .select()
          .eq('category', category.toString().split('.').last)
          .order('ten');
      
      print('Kết quả truy vấn theo loại từ Supabase: $data');
      
      return data.map<ProductSnapshot>((item) => 
        ProductSnapshot.fromMap(item)
      ).toList();
    } catch (e) {
      print('Lỗi khi lấy sản phẩm theo loại: $e');
      return [];
    }
  }
} 
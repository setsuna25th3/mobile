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
      'product': product.toJson(),
      'id': id,
    };
  }

  factory ProductSnapshot.fromMap(Map<String, dynamic> data) {
    try {
      return ProductSnapshot(
        product: Product.fromJson(data),
        id: data['id'].toString(),
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> them(Product product) async {
    try {
      // Bỏ qua trường id để Supabase tự sinh
      final productData = product.toJson();
      
      final response = await supabase
          .from('products')
          .insert(productData)
          .select()
          .single();
      
      return response['id'].toString();
    } catch (e) {
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

  // Truy vấn tất cả sản phẩm
  static Future<List<ProductSnapshot>> getAll2() async {
    try {
      final data = await supabase
          .from('products')
          .select()
          .order('ten');
      
      return data.map<ProductSnapshot>((item) => 
        ProductSnapshot.fromMap(item)
      ).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Truy vấn theo loại sản phẩm
  static Future<List<ProductSnapshot>> getByCategory2(ProductCategory category) async {
    try {
      final data = await supabase
          .from('products')
          .select()
          .eq('category', category.toString().split('.').last)
          .order('ten');
      
      return data.map<ProductSnapshot>((item) => 
        ProductSnapshot.fromMap(item)
      ).toList();
    } catch (e) {
      return [];
    }
  }
} 
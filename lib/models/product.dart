import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

enum ProductCategory {
  FOOD,
  DRINK,
  SNACK
}

class Product {
  late String id, ten;
  late int gia;
  late int stock;
  late String? image;
  late String moTa;
  late ProductCategory category;
  
  Product({
    required this.gia, 
    required this.id, 
    required this.ten, 
    this.image, 
    required this.moTa,
    required this.category,
    this.stock = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
      'gia': gia,
      'image': image,
      'mota': moTa,
      'category': category.toString().split('.').last,
      'stock': stock,
    };
  }

  factory Product.fromJson(Map<String, dynamic> map) {
    try {
      // Chuẩn hóa tên trường
      String? id = map['id']?.toString();
      String? name = map['ten']?.toString() ?? map['name']?.toString() ?? map['title']?.toString() ?? 'Sản phẩm không tên';
      
      var priceValue = map['gia'] ?? map['price'] ?? 0;
      int price = priceValue is int ? priceValue : int.parse(priceValue.toString());
      
      var stockValue = map['stock'] ?? 0;
      int stock = stockValue is int ? stockValue : int.parse(stockValue.toString());
      
      String? imageUrl = map['image']?.toString() ?? map['hinh_anh']?.toString() ?? map['anh']?.toString();
      String description = map['mota']?.toString() ?? map['mo_ta']?.toString() ?? map['moTa']?.toString() ?? map['description']?.toString() ?? '';
      
      String categoryStr = map['category']?.toString() ?? 'FOOD';
      
      return Product(
        id: id!,
        ten: name,
        gia: price,
        image: imageUrl,
        moTa: description,
        category: _getCategoryFromString(categoryStr),
        stock: stock,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  static ProductCategory _getCategoryFromString(String category) {
    switch(category.toUpperCase()) {
      case 'FOOD': return ProductCategory.FOOD;
      case 'DRINK': return ProductCategory.DRINK;
      case 'SNACK': return ProductCategory.SNACK;
      default: return ProductCategory.FOOD;
    }
  }
}

class GioHangItem {
  Product mh;
  int sl = 1;
  GioHangItem({required this.mh, required this.sl});
} 
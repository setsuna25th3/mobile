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
  late String? image;
  late String moTa;
  late ProductCategory category;
  
  Product({
    required this.gia, 
    required this.id, 
    required this.ten, 
    this.image, 
    required this.moTa,
    required this.category
  });

  Map<String, dynamic> toJson() {
    return {
      // Không bao gồm id để Supabase tự sinh UUID
      'ten': this.ten,
      'gia': this.gia,
      'image': this.image,
      'moTa': this.moTa,
      'category': this.category.toString().split('.').last,
    };
  }

  factory Product.fromJson(Map<String, dynamic> map) {
    try {
      return Product(
        id: map['id'].toString(),
        ten: map['ten'].toString(),
        gia: int.parse(map['gia'].toString()),
        image: map['image']?.toString(),
        moTa: map['moTa']?.toString() ?? '',
        category: _getCategoryFromString(map['category']?.toString() ?? 'FOOD'),
      );
    } catch (e) {
      print('Lỗi khi chuyển đổi JSON thành Product: $e');
      print('Dữ liệu JSON: $map');
      rethrow;
    }
  }
  
  static ProductCategory _getCategoryFromString(String category) {
    switch(category) {
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
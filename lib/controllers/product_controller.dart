import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/product.dart';
import '../models/product_repository.dart';

final supabase = Supabase.instance.client;

class ProductController extends GetxController {
  final _dssp = <Product>[].obs;
  final _gioHang = <GioHangItem>[].obs;
  final _selectedCategory = Rx<ProductCategory?>(null);
  
  ProductController();

  List<Product> get dssp => _dssp.value;
  List<GioHangItem> get gioHang => _gioHang.value;
  ProductCategory? get selectedCategory => _selectedCategory.value;
  
  bool get isLoggedIn => SupabaseService.isLoggedIn();
  String get userName => "Khách hàng";

  int get slmh => gioHang.fold(0, (sum, item) => sum + item.sl);

  @override
  void onReady() {
    super.onReady();
    docDL();
    // Sync cart từ database nếu user đã login
    if (SupabaseService.isLoggedIn()) {
      syncCartFromDatabase();
    }
  }

  void setCategory(ProductCategory? category) {
    _selectedCategory.value = category;
    docDL();
  }

  bool check_giohang(Product f) {
    for (var x in _gioHang) {
      if (x.mh.id == f.id) return true;
    }
    return false;
  }

  int find_index_GH(GioHangItem gh) {
    for (int i = 0; i < _gioHang.length; ++i) {
      if (_gioHang[i] == gh) return i;
    }
    return -1;
  }

  void addSP(GioHangItem gh) {
    int index = find_index_GH(gh);
    if (index != -1) {
      _gioHang[index].sl++;
      _gioHang.refresh();
    }
  }

  void subtractSP(GioHangItem gh) {
    int index = find_index_GH(gh);
    if (index != -1) {
      _gioHang[index].sl--;
      if (_gioHang[index].sl == 0) _gioHang.removeAt(index);
      _gioHang.refresh();
    }
  }

  void delSP(GioHangItem gh) {
    int index = find_index_GH(gh);
    if (index != -1) {
      _gioHang.removeAt(index);
      _gioHang.refresh();
    }
  }

  double tongThanhToan() {
    double s = 0;
    for (var x in _gioHang) {
      s += x.sl * x.mh.gia;
    }
    return s;
  }

  Future<void> xoahet() async {
    try {
      // Xóa giỏ hàng ở cơ sở dữ liệu
      final userId = SupabaseService.getCurrentUserId();
      if (userId != null) {
        await supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId);
      }
    } catch (e) {
      // Xử lý lỗi
    } finally {
      // Xóa giỏ hàng local
      _gioHang.clear();
      _gioHang.refresh();
    }
  }

  Future<bool> addGioHang(Product f) async {
    // Kiểm tra đăng nhập trước
    if (!SupabaseService.isLoggedIn()) {
      return false;
    }

    try {
      // Thêm vào database trước (Database-first)
      final success = await SupabaseService.addToCart(f.id, 1);
      
      if (!success) {
        return false;
      }
      
      // Chỉ khi database thành công mới cập nhật local
      int index = _gioHang.indexWhere((item) => item.mh.id == f.id);
      if (index == -1) {
        _gioHang.add(GioHangItem(mh: f, sl: 1));
      } else {
        _gioHang[index].sl++;
      }
      _gioHang.refresh();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> docDL() async {
    try {
      if (_selectedCategory.value == null) {
        var list = await ProductSnapshot.getAll2();
        _dssp.value = list.map((productSnap) => productSnap.product).toList();
      } else {
        var list = await ProductSnapshot.getByCategory2(_selectedCategory.value!);
        _dssp.value = list.map((productSnap) => productSnap.product).toList();
      }
      
      _dssp.refresh();
    } catch (e) {
      // Handle error silently
    }
  }

  // Sync cart từ database
  Future<void> syncCartFromDatabase() async {
    try {
      final cartItems = await SupabaseService.getCartItems();
      
      // Clear local cart trước
      _gioHang.clear();
      
      // Convert database cart items to local cart items
      for (var item in cartItems) {
        try {
          final productData = item['products'];
          if (productData != null) {
            final product = Product.fromJson(productData);
            final gioHangItem = GioHangItem(
              mh: product, 
              sl: item['quantity'] ?? 1
            );
            _gioHang.add(gioHangItem);
          }
        } catch (e) {
          // Bỏ qua lỗi converting
        }
      }
      
      _gioHang.refresh();
    } catch (e) {
      // Bỏ qua lỗi sync
    }
  }
}

class FoodStoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ProductController());
  }
}

showMySnackBar(BuildContext context, String thongBao, int thoiGian) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(thongBao),
        duration: Duration(seconds: thoiGian),
      )
  );
} 
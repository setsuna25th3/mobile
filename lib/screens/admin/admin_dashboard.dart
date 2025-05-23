import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/product_controller.dart';
import '../../services/supabase_service.dart';
import '../../utils/auth_storage.dart';
import 'product_management.dart';
import 'order_management.dart';

class AdminPages {
  static const int dashboard = 0, products = 1, orders = 2;
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = AdminPages.dashboard;
  final List<Widget> _pages = [const DashboardHome(), const ProductManagement(), const OrderManagement()];

  void _navigateToPage(int index) => setState(() => _selectedIndex = index);

  Future<void> _logout() async {
    try {
      if (Get.isRegistered<ProductController>()) {
        await Get.find<ProductController>().xoahet();
      }
      await SupabaseService.signOut();
      AuthStorage.adminLogout();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/admin-auth');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi đăng xuất: $e')));
    }
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings, size: 30, color: Colors.green)),
                  const SizedBox(height: 10),
                  Text('Admin: ${AuthStorage.getAdminEmail() ?? "Admin"}', style: const TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', AdminPages.dashboard),
            _buildDrawerItem(Icons.inventory, 'Quản lý Sản phẩm', AdminPages.products),
            _buildDrawerItem(Icons.receipt_long, 'Quản lý Đơn hàng', AdminPages.orders),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Đăng xuất'), onTap: _logout),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});
  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  int _productCount = 0, _orderCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final productCount = await SupabaseService.getProductCount();
      
      // Lấy tất cả orders và đếm
      final ordersData = await Supabase.instance.client
          .from('orders')
          .select('id');
      
      setState(() {
        _productCount = productCount;
        _orderCount = ordersData.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToSection(int index) {
    final state = context.findAncestorStateOfType<_AdminDashboardState>();
    state?._navigateToPage(index);
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Stats cards section
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard('Sản phẩm', _productCount.toString(), Icons.inventory, Colors.green, () => _navigateToSection(AdminPages.products)),
                  _buildStatCard('Đơn hàng', _orderCount.toString(), Icons.receipt_long, Colors.blue, () => _navigateToSection(AdminPages.orders)),
                ],
              ),
            ],
          ),
        );
  }
} 
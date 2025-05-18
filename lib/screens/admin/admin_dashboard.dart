import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../utils/auth_storage.dart';
import 'product_management.dart';
import 'order_management.dart';
import 'user_management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const DashboardHome(),
    const ProductManagement(),
    const OrderManagement(),
    const UserManagement(),
  ];

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      // Đăng xuất khỏi Supabase
      await SupabaseService.signOut();
      // Xóa trạng thái đăng nhập đã lưu
      await AuthStorage.adminLogout();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/admin-login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.green,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, size: 30, color: Colors.green),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Admin: ${AuthStorage.getAdminEmail() ?? "Admin"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Quản lý Sản phẩm'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Quản lý Đơn hàng'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Quản lý Người dùng'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: _logout,
            ),
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
  int _productCount = 0;
  int _orderCount = 0;
  int _userCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final productCount = await SupabaseService.getProductCount();
      final orderCount = await SupabaseService.getOrderCount();
      final userCount = await SupabaseService.getUserCount();
      setState(() {
        _productCount = productCount;
        _orderCount = orderCount;
        _userCount = userCount;
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi tải dữ liệu dashboard: $e");
      setState(() {
        _isLoading = false;
        // Optionally show an error message on the dashboard
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                title: 'Sản phẩm',
                count: _productCount.toString(),
                icon: Icons.inventory,
                color: Colors.green,
                onTap: () => _navigateToSection(1),
              ),
              _buildStatCard(
                title: 'Đơn hàng',
                count: _orderCount.toString(),
                icon: Icons.shopping_cart,
                color: Colors.orange,
                onTap: () => _navigateToSection(2),
              ),
              _buildStatCard(
                title: 'Người dùng',
                count: _userCount.toString(),
                icon: Icons.people,
                color: Colors.blue,
                onTap: () => _navigateToSection(3),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _navigateToSection(int index) {
    // Đơn giản hóa logic điều hướng
    final state = context.findAncestorStateOfType<_AdminDashboardState>();
    if (state != null) {
      state._navigateToPage(index);
    }
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
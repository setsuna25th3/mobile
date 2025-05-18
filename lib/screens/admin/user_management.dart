import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

// Biến global để lưu trữ reference đến BuildContext hiện tại
final GlobalKey<ScaffoldMessengerState> userManagementScaffoldKey = GlobalKey<ScaffoldMessengerState>();

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Remove debug code
      final users = await SupabaseService.getAllUsers();
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải danh sách người dùng: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty && _selectedRole.isEmpty) {
      return _users;
    }
    
    return _users.where((user) {
      bool matchesSearch = _searchQuery.isEmpty || 
        (user['email'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) || 
        (user['full_name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (user['phone'] ?? '').toString().contains(_searchQuery);
      
      bool matchesRole = _selectedRole.isEmpty || user['role'] == _selectedRole;
      
      return matchesSearch && matchesRole;
    }).toList();
  }

  // Cập nhật vai trò người dùng
  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await supabase
          .from('user_profiles')
          .update({'role': newRole})
          .eq('id', userId);
      
      _loadUsers();
      
      // Sử dụng ScaffoldMessenger an toàn
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật vai trò người dùng thành công')),
        );
      }
    } catch (e) {
      // Sử dụng ScaffoldMessenger an toàn
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật vai trò: $e')),
        );
      }
    }
  }

  // Hiển thị form chỉnh sửa thông tin người dùng
  void _showEditUserDialog(Map<String, dynamic> user) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: user['full_name'] ?? '');
    final _phoneController = TextEditingController(text: user['phone'] ?? '');
    final _emailController = TextEditingController(text: user['email'] ?? '');
    String? _selectedRoleInForm = user['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa thông tin người dùng'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Vai trò',
                    ),
                    value: _selectedRoleInForm,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Người dùng')),
                      DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                    ],
                    onChanged: (value) {
                      _selectedRoleInForm = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  
                  try {
                    await supabase
                        .from('user_profiles')
                        .update({
                          'full_name': _nameController.text,
                          'phone': _phoneController.text,
                          'role': _selectedRoleInForm,
                          'email': _emailController.text,
                        })
                        .eq('id', user['id']);
                    
                    _loadUsers();
                    
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cập nhật thông tin người dùng thành công')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi cập nhật thông tin: $e')),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  // Hiển thị dialog xác nhận xóa người dùng
  void _showDeleteConfirmationDialog(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa người dùng này? Hành động này không thể khôi phục.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  // Xóa profile người dùng
                  await supabase
                      .from('user_profiles')
                      .delete()
                      .eq('id', userId);
                  
                  // Không thể xóa trực tiếp tài khoản người dùng từ admin
                  // Cần xác thực qua Supabase Auth Admin API
                  
                  _loadUsers();
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa người dùng thành công')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xóa người dùng: $e')),
                  );
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Hiển thị thông tin chi tiết người dùng
  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thông tin người dùng'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('ID:', user['id']),
                _buildInfoRow('Email:', user['email'] ?? 'Chưa có email'),
                _buildInfoRow('Họ tên:', user['full_name'] ?? 'Chưa có tên'),
                _buildInfoRow('Số điện thoại:', user['phone'] ?? 'Chưa có SĐT'),
                _buildInfoRow('Vai trò:', _getRoleText(user['role'])),
                _buildInfoRow('Ngày tạo:', _formatDate(user['created_at'])),
                
                const SizedBox(height: 16),
                const Text('Cập nhật vai trò:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: user['role'] == 'user' ? null : () {
                        Navigator.of(context).pop();
                        _updateUserRole(user['id'], 'user');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Người dùng'),
                    ),
                    ElevatedButton(
                      onPressed: user['role'] == 'admin' ? null : () {
                        Navigator.of(context).pop();
                        _updateUserRole(user['id'], 'admin');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Quản trị viên'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditUserDialog(user);
              },
              child: const Text('Chỉnh sửa'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  // Build hàng thông tin
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Format date string
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Không có';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateString;
    }
  }

  // Chuyển đổi mã vai trò thành text hiển thị
  String _getRoleText(String? role) {
    switch (role) {
      case 'admin': return 'Quản trị viên';
      case 'user': return 'Người dùng';
      default: return role ?? 'Không xác định';
    }
  }

  // Lấy màu cho vai trò
  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin': return Colors.purple;
      case 'user': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.green.shade50,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm người dùng...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleFilterChip('', 'Tất cả'),
                _buildRoleFilterChip('user', 'Người dùng'),
                _buildRoleFilterChip('admin', 'Quản trị viên'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String role, String label) {
    final isSelected = _selectedRole == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() => _selectedRole = selected ? role : '');
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.green.shade100,
        checkmarkColor: Colors.green,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.people_outline, size: 80, color: Colors.green),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: const Text(
              'Không tìm thấy người dùng nào',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            (user['full_name'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(color: Colors.green),
          ),
        ),
        title: Text(
          user['full_name'] ?? 'Không có tên',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? 'Không có email'),
            if (user['phone'] != null) Text(user['phone']),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoleChip(user['role'] ?? 'user'),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditUserDialog(user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmationDialog(user['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.blue : Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'User',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // Thêm phương thức hiển thị dialog thêm người dùng mới
  void _showAddUserDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _phoneController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    String? _selectedRoleInForm = 'user';
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm người dùng mới'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Nhập email người dùng',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Vui lòng nhập email';
                      if (!value!.contains('@') || !value.contains('.')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu cho tài khoản',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Vui lòng nhập mật khẩu';
                      if (value!.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên',
                      hintText: 'Nhập họ tên người dùng',
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      hintText: 'Nhập số điện thoại người dùng',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Vai trò'),
                    value: _selectedRoleInForm,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Người dùng')),
                      DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                    ],
                    onChanged: (value) => _selectedRoleInForm = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  
                  try {
                    final result = await SupabaseService.signUp(
                      _emailController.text,
                      _passwordController.text,
                      _nameController.text,
                      _phoneController.text,
                    );
                    
                    if (result) {
                      Navigator.of(context).pop();
                      
                      if (_selectedRoleInForm == 'admin') {
                        final users = await SupabaseService.getAllUsers();
                        final newUser = users.firstWhere(
                          (user) => user['email'] == _emailController.text,
                          orElse: () => {},
                        );
                        
                        if (newUser.isNotEmpty) {
                          await supabase
                              .from('user_profiles')
                              .update({'role': 'admin'})
                              .eq('id', newUser['id']);
                        }
                      }
                      
                      _loadUsers();
                      
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tạo người dùng mới thành công')),
                      );
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lỗi khi tạo người dùng mới')),
                      );
                    }
                  } catch (e) {
                    Navigator.of(context).pop();
                    
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi tạo người dùng: $e')),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Tạo người dùng'),
            ),
          ],
        ),
      ),
    );
  }
} 
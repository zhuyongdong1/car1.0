import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../models/api_exception.dart';

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  CustomerStatistics? _selectedCustomerStats;
  CustomerOverview? _overview;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // 分页相关
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _hasMorePages = false;

  // 统计数据
  int _vipCount = 0;
  int _todayVisits = 0;

  // 搜索和筛选
  String _searchQuery = '';
  String? _filterCustomerType;
  String? _filterVipLevel;

  // Getters
  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  CustomerStatistics? get selectedCustomerStats => _selectedCustomerStats;
  CustomerOverview? get overview => _overview;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // 别名
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  bool get hasMorePages => _hasMorePages;
  bool get hasMore => _hasMorePages; // 别名
  String get searchQuery => _searchQuery;
  String? get filterCustomerType => _filterCustomerType;
  String? get filterVipLevel => _filterVipLevel;
  int get vipCount => _vipCount;
  int get todayVisits => _todayVisits;

  // 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 设置错误信息
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  // 获取客户列表
  Future<void> fetchCustomers({
    int page = 1,
    int limit = 10,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _customers.clear();
      } else {
        _currentPage = page;
      }

      _setLoading(true);
      clearError();

      final result = await CustomerService.getCustomers(
        page: _currentPage,
        limit: limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        customerType: _filterCustomerType,
        vipLevel: _filterVipLevel,
      );

      final newCustomers = result['customers'] as List<Customer>;
      final pagination = result['pagination'];

      if (refresh || _currentPage == 1) {
        _customers = newCustomers;
      } else {
        _customers.addAll(newCustomers);
      }

      _totalPages = pagination['pages'] ?? 1;
      _totalCount = pagination['total'] ?? 0;
      _hasMorePages = _currentPage < _totalPages;

      // 更新统计信息
      _updateStats();

      _setLoading(false);
    } catch (e) {
      if (e is ApiException) {
        _setError(e.message);
      } else {
        _setError('获取客户列表失败: ${e.toString()}');
      }
    }
  }

  // 更新统计信息
  void _updateStats() {
    _vipCount = _customers.where((c) => c.vipLevel.name != '普通').length;
    final today = DateTime.now();
    _todayVisits = _customers
        .where((c) =>
            c.lastVisitDate != null &&
            c.lastVisitDate!.year == today.year &&
            c.lastVisitDate!.month == today.month &&
            c.lastVisitDate!.day == today.day)
        .length;
  }

  // 加载更多客户
  Future<void> loadMoreCustomers() async {
    if (_hasMorePages && !_isLoading && !_isLoadingMore) {
      _isLoadingMore = true;
      notifyListeners();

      try {
        await fetchCustomers(page: _currentPage + 1);
      } finally {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  // 搜索客户
  Future<void> searchCustomers(String query) async {
    _searchQuery = query;
    await fetchCustomers(refresh: true);
  }

  // 设置筛选条件
  Future<void> setFilter({
    String? customerType,
    String? vipLevel,
  }) async {
    _filterCustomerType = customerType;
    _filterVipLevel = vipLevel;
    await fetchCustomers(refresh: true);
  }

  // 清除筛选条件
  Future<void> clearFilters() async {
    _searchQuery = '';
    _filterCustomerType = null;
    _filterVipLevel = null;
    await fetchCustomers(refresh: true);
  }

  // 获取客户详情
  Future<void> fetchCustomerById(int id) async {
    try {
      _setLoading(true);
      clearError();

      final result = await CustomerService.getCustomerById(id);
      _selectedCustomer = result['customer'];
      _selectedCustomerStats = result['stats'];

      _setLoading(false);
    } catch (e) {
      if (e is ApiException) {
        _setError(e.message);
      } else {
        _setError('获取客户详情失败: ${e.toString()}');
      }
    }
  }

  // 创建客户
  Future<bool> createCustomer(Customer customer) async {
    try {
      _setLoading(true);
      clearError();

      final newCustomer = await CustomerService.createCustomer(customer);

      // 添加到列表头部
      _customers.insert(0, newCustomer);
      _totalCount++;

      _setLoading(false);
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.message);
      } else {
        _setError('创建客户失败: ${e.toString()}');
      }
      return false;
    }
  }

  // 更新客户
  Future<bool> updateCustomer(int id, Customer customer) async {
    try {
      _setLoading(true);
      clearError();

      final updatedCustomer =
          await CustomerService.updateCustomer(id, customer);

      // 更新列表中的客户
      final index = _customers.indexWhere((c) => c.id == id);
      if (index != -1) {
        _customers[index] = updatedCustomer;
      }

      // 如果是当前选中的客户，也要更新
      if (_selectedCustomer?.id == id) {
        _selectedCustomer = updatedCustomer;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.message);
      } else {
        _setError('更新客户失败: ${e.toString()}');
      }
      return false;
    }
  }

  // 删除客户
  Future<bool> deleteCustomer(int id) async {
    try {
      _setLoading(true);
      clearError();

      await CustomerService.deleteCustomer(id);

      // 从列表中移除
      _customers.removeWhere((c) => c.id == id);
      _totalCount--;

      // 如果删除的是当前选中的客户，清除选中状态
      if (_selectedCustomer?.id == id) {
        _selectedCustomer = null;
        _selectedCustomerStats = null;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.message);
      } else {
        _setError('删除客户失败: ${e.toString()}');
      }
      return false;
    }
  }

  // 更新客户到店信息
  Future<void> updateVisit(int customerId) async {
    try {
      _setLoading(true);
      clearError();

      await CustomerService.updateCustomerVisit(customerId);

      // 更新本地客户信息
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        final customer = _customers[index];
        _customers[index] = customer.copyWith(
          visitCount: customer.visitCount + 1,
          lastVisitDate: DateTime.now(),
        );
      }

      // 如果是当前选中的客户，也要更新
      if (_selectedCustomer?.id == customerId) {
        _selectedCustomer = _selectedCustomer!.copyWith(
          visitCount: _selectedCustomer!.visitCount + 1,
          lastVisitDate: DateTime.now(),
        );
      }

      _setLoading(false);
    } catch (e) {
      if (e is ApiException) {
        _setError(e.message);
      } else {
        _setError('更新到店信息失败: ${e.toString()}');
      }
    }
  }

  // 快速搜索客户
  Future<List<Customer>> quickSearchCustomers(String keyword) async {
    try {
      return await CustomerService.searchCustomers(keyword, limit: 5);
    } catch (e) {
      if (kDebugMode) {
        print('快速搜索失败: $e');
      }
      return [];
    }
  }

  // 获取VIP客户列表
  Future<List<Customer>> getVipCustomers() async {
    try {
      return await CustomerService.getVipCustomers();
    } catch (e) {
      if (kDebugMode) {
        print('获取VIP客户失败: $e');
      }
      return [];
    }
  }

  // 更新客户到店信息
  Future<bool> updateCustomerVisit(int id, {double? amount}) async {
    try {
      final updatedCustomer =
          await CustomerService.updateCustomerVisit(id, amount: amount);

      // 更新列表中的客户
      final index = _customers.indexWhere((c) => c.id == id);
      if (index != -1) {
        _customers[index] = updatedCustomer;
      }

      // 如果是当前选中的客户，也要更新
      if (_selectedCustomer?.id == id) {
        _selectedCustomer = updatedCustomer;
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('更新到店信息失败: $e');
      }
      return false;
    }
  }

  // 获取客户统计概览
  Future<void> fetchCustomerOverview() async {
    try {
      _overview = await CustomerService.getCustomerOverview();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('获取客户统计失败: $e');
      }
    }
  }

  // 选中客户
  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  // 清除选中的客户
  void clearSelectedCustomer() {
    _selectedCustomer = null;
    _selectedCustomerStats = null;
    notifyListeners();
  }

  // 根据ID查找客户
  Customer? findCustomerById(int id) {
    try {
      return _customers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
    }
  }

  // 根据手机号查找客户
  Customer? findCustomerByPhone(String phone) {
    try {
      return _customers.firstWhere((customer) => customer.phone == phone);
    } catch (e) {
      return null;
    }
  }

  // 获取客户统计信息
  Map<String, dynamic> getCustomerStats() {
    final totalCustomers = _customers.length;
    final vipCustomers = _customers.where((c) => c.isVip).length;
    final companyCustomers =
        _customers.where((c) => c.customerType == CustomerType.company).length;
    final totalSpent = _customers.fold(0.0, (sum, c) => sum + c.totalSpent);
    final avgSpent = totalCustomers > 0 ? totalSpent / totalCustomers : 0.0;

    return {
      'totalCustomers': totalCustomers,
      'vipCustomers': vipCustomers,
      'companyCustomers': companyCustomers,
      'personalCustomers': totalCustomers - companyCustomers,
      'totalSpent': totalSpent,
      'avgSpent': avgSpent,
    };
  }

  // 验证客户数据
  Map<String, String> validateCustomer(Customer customer) {
    final errors = <String, String>{};

    if (customer.name.trim().length < 2) {
      errors['name'] = '客户姓名至少2个字符';
    }

    if (!CustomerService.isValidPhoneNumber(customer.phone)) {
      errors['phone'] = '请输入有效的手机号码';
    }

    if (customer.email != null && customer.email!.isNotEmpty) {
      if (!CustomerService.isValidEmail(customer.email!)) {
        errors['email'] = '请输入有效的邮箱地址';
      }
    }

    if (customer.idCard != null && customer.idCard!.isNotEmpty) {
      if (!CustomerService.isValidIdCard(customer.idCard!)) {
        errors['idCard'] = '请输入有效的身份证号';
      }
    }

    return errors;
  }

  // 重置Provider状态
  void reset() {
    _customers.clear();
    _selectedCustomer = null;
    _selectedCustomerStats = null;
    _overview = null;
    _isLoading = false;
    _errorMessage = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalCount = 0;
    _hasMorePages = false;
    _searchQuery = '';
    _filterCustomerType = null;
    _filterVipLevel = null;
    notifyListeners();
  }
}

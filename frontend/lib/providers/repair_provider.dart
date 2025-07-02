import 'package:flutter/foundation.dart';
import '../models/car.dart';
import '../services/api_service.dart';

class RepairProvider with ChangeNotifier {
  List<Repair> _repairs = [];
  Repair? _selectedRepair;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Getters
  List<Repair> get repairs => _repairs;
  Repair? get selectedRepair => _selectedRepair;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMoreData => _hasMoreData;

  // 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 设置错误信息
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // 添加维修记录
  Future<bool> addRepair(Repair repair) async {
    try {
      _setLoading(true);
      clearError();

      final newRepair = await ApiService.createRepair(repair);
      _repairs.insert(0, newRepair);

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('添加维修记录失败: ${e.toString()}');
      return false;
    }
  }

  // 获取维修记录列表
  Future<void> fetchRepairs({
    int? carId,
    String? plateNumber,
    String? startDate,
    String? endDate,
    String? search,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _hasMoreData = true;
        _repairs.clear();
      }

      _setLoading(true);
      clearError();

      final repairs = await ApiService.getRepairs(
        carId: carId,
        plateNumber: plateNumber,
        startDate: startDate,
        endDate: endDate,
        search: search,
        page: _currentPage,
        limit: 10,
      );

      if (refresh) {
        _repairs = repairs;
      } else {
        _repairs.addAll(repairs);
      }

      _hasMoreData = repairs.length == 10;
      _currentPage++;

      _setLoading(false);
      notifyListeners();
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('获取维修记录失败: ${e.toString()}');
    }
  }

  // 获取单个维修记录详情
  Future<bool> fetchRepairById(int id) async {
    try {
      _setLoading(true);
      clearError();

      final repair = await ApiService.getRepair(id);
      _selectedRepair = repair;

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('获取维修记录详情失败: ${e.toString()}');
      return false;
    }
  }

  // 更新维修记录
  Future<bool> updateRepair(Repair repair) async {
    try {
      _setLoading(true);
      clearError();

      final updatedRepair = await ApiService.updateRepair(repair.id!, repair);

      // 更新列表中的维修记录
      final index = _repairs.indexWhere((r) => r.id == repair.id);
      if (index != -1) {
        _repairs[index] = updatedRepair;
      }

      // 更新选中的维修记录
      if (_selectedRepair?.id == repair.id) {
        _selectedRepair = updatedRepair;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('更新维修记录失败: ${e.toString()}');
      return false;
    }
  }

  // 删除维修记录
  Future<bool> deleteRepair(int id) async {
    try {
      _setLoading(true);
      clearError();

      await ApiService.deleteRepair(id);

      // 从列表中移除
      _repairs.removeWhere((r) => r.id == id);

      // 如果删除的是当前选中的记录，清空选中状态
      if (_selectedRepair?.id == id) {
        _selectedRepair = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('删除维修记录失败: ${e.toString()}');
      return false;
    }
  }

  // 搜索维修记录
  Future<void> searchRepairs(String query) async {
    await fetchRepairs(search: query, refresh: true);
  }

  // 根据车辆ID获取维修记录
  Future<void> fetchRepairsByCarId(int carId) async {
    await fetchRepairs(carId: carId, refresh: true);
  }

  // 根据车牌号获取维修记录
  Future<void> fetchRepairsByPlateNumber(String plateNumber) async {
    await fetchRepairs(plateNumber: plateNumber, refresh: true);
  }

  // 根据日期范围获取维修记录
  Future<void> fetchRepairsByDateRange(String startDate, String endDate) async {
    await fetchRepairs(startDate: startDate, endDate: endDate, refresh: true);
  }

  // 加载更多维修记录
  Future<void> loadMoreRepairs({
    int? carId,
    String? plateNumber,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    if (!_hasMoreData || _isLoading) return;

    await fetchRepairs(
      carId: carId,
      plateNumber: plateNumber,
      startDate: startDate,
      endDate: endDate,
      search: search,
    );
  }

  // 选择维修记录
  void selectRepair(Repair repair) {
    _selectedRepair = repair;
    notifyListeners();
  }

  // 清除选择的维修记录
  void clearSelectedRepair() {
    _selectedRepair = null;
    notifyListeners();
  }

  // 刷新维修记录列表
  Future<void> refreshRepairs() async {
    await fetchRepairs(refresh: true);
  }

  // 重置状态
  void reset() {
    _repairs.clear();
    _selectedRepair = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _hasMoreData = true;
    notifyListeners();
  }

  // 根据ID查找维修记录
  Repair? findRepairById(int id) {
    try {
      return _repairs.firstWhere((repair) => repair.id == id);
    } catch (e) {
      return null;
    }
  }

  // 获取总维修费用
  double get totalRepairCost {
    return _repairs.fold(0.0, (sum, repair) => sum + repair.price);
  }

  // 获取维修记录数量
  int get totalRepairs => _repairs.length;

  // 获取最近的维修记录
  Repair? get latestRepair {
    if (_repairs.isEmpty) return null;
    return _repairs
        .reduce((a, b) => a.repairDate.isAfter(b.repairDate) ? a : b);
  }

  // 根据车辆ID获取该车辆的维修记录
  List<Repair> getRepairsByCarId(int carId) {
    return _repairs.where((repair) => repair.carId == carId).toList();
  }

  // 获取指定日期范围内的维修记录
  List<Repair> getRepairsByDateRange(DateTime startDate, DateTime endDate) {
    return _repairs
        .where((repair) =>
            repair.repairDate
                .isAfter(startDate.subtract(const Duration(days: 1))) &&
            repair.repairDate.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }
}

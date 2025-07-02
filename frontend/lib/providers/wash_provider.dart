import 'package:flutter/foundation.dart';
import '../models/car.dart';
import '../services/api_service.dart';

class WashProvider with ChangeNotifier {
  List<WashLog> _washLogs = [];
  WashLog? _selectedWashLog;
  Map<String, dynamic>? _washStats;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Getters
  List<WashLog> get washLogs => _washLogs;
  WashLog? get selectedWashLog => _selectedWashLog;
  Map<String, dynamic>? get washStats => _washStats;
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

  // 添加洗车记录
  Future<bool> addWashLog(WashLog washLog) async {
    try {
      _setLoading(true);
      clearError();

      final newWashLog = await ApiService.createWashLog(washLog);
      _washLogs.insert(0, newWashLog);

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('添加洗车记录失败: ${e.toString()}');
      return false;
    }
  }

  // 获取某车辆的洗车记录和统计信息
  Future<bool> fetchWashLogsByPlateNumber(
    String plateNumber, {
    String? startDate,
    String? endDate,
    String? washType,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _hasMoreData = true;
        _washLogs.clear();
      }

      _setLoading(true);
      clearError();

      final washLogs = await ApiService.getWashLogs(
        plateNumber: plateNumber,
        startDate: startDate,
        endDate: endDate,
        washType: washType,
        page: _currentPage,
        limit: 10,
      );

      if (refresh) {
        _washLogs = washLogs;
        _washStats = null; // API没有返回stats，设为null
      } else {
        _washLogs.addAll(washLogs);
      }

      _hasMoreData = washLogs.length == 10;
      _currentPage++;

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('获取洗车记录失败: ${e.toString()}');
      return false;
    }
  }

  // 获取所有洗车记录
  Future<void> fetchAllWashLogs({
    int? carId,
    String? plateNumber,
    String? startDate,
    String? endDate,
    String? washType,
    String? location,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _hasMoreData = true;
        _washLogs.clear();
      }

      _setLoading(true);
      clearError();

      final washLogs = await ApiService.getWashLogs(
        carId: carId,
        plateNumber: plateNumber,
        startDate: startDate,
        endDate: endDate,
        washType: washType,
        location: location,
        page: _currentPage,
        limit: 10,
      );

      if (refresh) {
        _washLogs = washLogs;
      } else {
        _washLogs.addAll(washLogs);
      }

      _hasMoreData = washLogs.length == 10;
      _currentPage++;

      _setLoading(false);
      notifyListeners();
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('获取洗车记录失败: ${e.toString()}');
    }
  }

  // 更新洗车记录
  Future<bool> updateWashLog(WashLog washLog) async {
    try {
      _setLoading(true);
      clearError();

      final updatedWashLog =
          await ApiService.updateWashLog(washLog.id!, washLog);

      // 更新列表中的洗车记录
      final index = _washLogs.indexWhere((w) => w.id == washLog.id);
      if (index != -1) {
        _washLogs[index] = updatedWashLog;
      }

      // 更新选中的洗车记录
      if (_selectedWashLog?.id == washLog.id) {
        _selectedWashLog = updatedWashLog;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('更新洗车记录失败: ${e.toString()}');
      return false;
    }
  }

  // 删除洗车记录
  Future<bool> deleteWashLog(int id) async {
    try {
      _setLoading(true);
      clearError();

      await ApiService.deleteWashLog(id);

      // 从列表中移除
      _washLogs.removeWhere((w) => w.id == id);

      // 如果删除的是当前选中的记录，清空选中状态
      if (_selectedWashLog?.id == id) {
        _selectedWashLog = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('删除洗车记录失败: ${e.toString()}');
      return false;
    }
  }

  // 根据车辆ID获取洗车记录
  Future<void> fetchWashLogsByCarId(int carId) async {
    await fetchAllWashLogs(carId: carId, refresh: true);
  }

  // 根据洗车类型过滤
  Future<void> fetchWashLogsByType(String washType) async {
    await fetchAllWashLogs(washType: washType, refresh: true);
  }

  // 根据地点搜索
  Future<void> searchWashLogsByLocation(String location) async {
    await fetchAllWashLogs(location: location, refresh: true);
  }

  // 根据日期范围获取洗车记录
  Future<void> fetchWashLogsByDateRange(
      String startDate, String endDate) async {
    await fetchAllWashLogs(
        startDate: startDate, endDate: endDate, refresh: true);
  }

  // 加载更多洗车记录
  Future<void> loadMoreWashLogs({
    int? carId,
    String? plateNumber,
    String? startDate,
    String? endDate,
    String? washType,
    String? location,
  }) async {
    if (!_hasMoreData || _isLoading) return;

    await fetchAllWashLogs(
      carId: carId,
      plateNumber: plateNumber,
      startDate: startDate,
      endDate: endDate,
      washType: washType,
      location: location,
    );
  }

  // 选择洗车记录
  void selectWashLog(WashLog washLog) {
    _selectedWashLog = washLog;
    notifyListeners();
  }

  // 清除选择的洗车记录
  void clearSelectedWashLog() {
    _selectedWashLog = null;
    notifyListeners();
  }

  // 刷新洗车记录列表
  Future<void> refreshWashLogs() async {
    await fetchAllWashLogs(refresh: true);
  }

  // 重置状态
  void reset() {
    _washLogs.clear();
    _selectedWashLog = null;
    _washStats = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _hasMoreData = true;
    notifyListeners();
  }

  // 根据ID查找洗车记录
  WashLog? findWashLogById(int id) {
    try {
      return _washLogs.firstWhere((washLog) => washLog.id == id);
    } catch (e) {
      return null;
    }
  }

  // 获取总洗车费用
  double get totalWashCost {
    return _washLogs.fold(0.0, (sum, washLog) => sum + washLog.price);
  }

  // 获取洗车次数
  int get totalWashes => _washLogs.length;

  // 获取最近的洗车记录
  WashLog? get latestWash {
    if (_washLogs.isEmpty) return null;
    return _washLogs.reduce((a, b) => a.washTime.isAfter(b.washTime) ? a : b);
  }

  // 根据车辆ID获取该车辆的洗车记录
  List<WashLog> getWashLogsByCarId(int carId) {
    return _washLogs.where((washLog) => washLog.carId == carId).toList();
  }

  // 根据洗车类型获取记录
  List<WashLog> getWashLogsByType(String washType) {
    return _washLogs.where((washLog) => washLog.washType == washType).toList();
  }

  // 获取指定日期范围内的洗车记录
  List<WashLog> getWashLogsByDateRange(DateTime startDate, DateTime endDate) {
    return _washLogs
        .where((washLog) =>
            washLog.washTime
                .isAfter(startDate.subtract(const Duration(days: 1))) &&
            washLog.washTime.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  // 按洗车类型统计
  Map<String, int> getWashTypeStats() {
    final stats = <String, int>{};
    for (final washLog in _washLogs) {
      stats[washLog.washType] = (stats[washLog.washType] ?? 0) + 1;
    }
    return stats;
  }

  // 按月份统计洗车次数
  Map<String, int> getMonthlyWashStats() {
    final stats = <String, int>{};
    for (final washLog in _washLogs) {
      final month =
          '${washLog.washTime.year}-${washLog.washTime.month.toString().padLeft(2, '0')}';
      stats[month] = (stats[month] ?? 0) + 1;
    }
    return stats;
  }

  // 获取平均洗车费用
  double get averageWashCost {
    if (_washLogs.isEmpty) return 0.0;
    return totalWashCost / _washLogs.length;
  }

  // 快速添加洗车打卡记录
  Future<bool> quickWashCheckIn(
    String plateNumber, {
    String washType = 'manual',
    double price = 0.0,
    String? location,
  }) async {
    final washLog = WashLog(
      carId: 0, // 会通过plateNumber查找
      washTime: DateTime.now(),
      washType: washType,
      price: price,
      location: location,
    );

    // 需要在数据中包含plateNumber
    final washData = washLog.toJson();
    washData['plate_number'] = plateNumber;

    try {
      _setLoading(true);
      clearError();

      // 临时创建洗车记录数据，包含车牌号
      final washData = {
        'car_id': 0,
        'plate_number': plateNumber,
        'wash_time': DateTime.now().toIso8601String(),
        'wash_type': washType,
        'price': price,
        if (location != null) 'location': location,
      };

      final response = await ApiService.request(
        method: 'POST',
        endpoint: '/wash',
        data: washData,
      );

      final newWashLog = WashLog.fromJson(response['data']);
      _washLogs.insert(0, newWashLog);

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('洗车打卡失败: ${e.toString()}');
      return false;
    }
  }
}

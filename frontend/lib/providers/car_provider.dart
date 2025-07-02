import 'package:flutter/foundation.dart';
import '../models/car.dart';
import '../services/api_service.dart';

class CarProvider with ChangeNotifier {
  List<Car> _cars = [];
  Car? _selectedCar;
  Map<String, dynamic>? _carDetails;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Getters
  List<Car> get cars => _cars;
  Car? get selectedCar => _selectedCar;
  Map<String, dynamic>? get carDetails => _carDetails;
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

  // 添加车辆
  Future<bool> addCar(Car car) async {
    try {
      _setLoading(true);
      clearError();

      final newCar = await ApiService.createCar(car);
      _cars.insert(0, newCar);

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('添加车辆失败: ${e.toString()}');
      return false;
    }
  }

  // 获取车辆列表
  Future<void> fetchCars({
    String? search,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _hasMoreData = true;
        _cars.clear();
      }

      _setLoading(true);
      clearError();

      final cars = await ApiService.getCars(
        search: search,
        page: _currentPage,
        limit: 10,
      );

      if (refresh) {
        _cars = cars;
      } else {
        _cars.addAll(cars);
      }

      _hasMoreData = cars.length == 10;
      _currentPage++;

      _setLoading(false);
      notifyListeners();
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('获取车辆列表失败: ${e.toString()}');
    }
  }

  // 根据车牌号查询车辆详情
  Future<bool> fetchCarByPlateNumber(String plateNumber) async {
    try {
      _setLoading(true);
      clearError();

      final carData = await ApiService.getCarByPlateNumber(plateNumber);
      _carDetails = carData;
      _selectedCar = Car.fromJson(carData['car']);

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('查询车辆失败: ${e.toString()}');
      return false;
    }
  }

  // 更新车辆信息
  Future<bool> updateCar(Car car) async {
    try {
      _setLoading(true);
      clearError();

      final updatedCar = await ApiService.updateCar(car.id!, car);

      // 更新列表中的车辆信息
      final index = _cars.indexWhere((c) => c.id == car.id);
      if (index != -1) {
        _cars[index] = updatedCar;
      }

      // 更新选中的车辆
      if (_selectedCar?.id == car.id) {
        _selectedCar = updatedCar;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('更新车辆失败: ${e.toString()}');
      return false;
    }
  }

  // 搜索车辆
  Future<void> searchCars(String query) async {
    await fetchCars(search: query, refresh: true);
  }

  // 加载更多车辆
  Future<void> loadMoreCars({String? search}) async {
    if (!_hasMoreData || _isLoading) return;
    await fetchCars(search: search);
  }

  // 选择车辆
  void selectCar(Car car) {
    _selectedCar = car;
    notifyListeners();
  }

  // 清除选择的车辆
  void clearSelectedCar() {
    _selectedCar = null;
    _carDetails = null;
    notifyListeners();
  }

  // 刷新车辆列表
  Future<void> refreshCars() async {
    await fetchCars(refresh: true);
  }

  // 重置状态
  void reset() {
    _cars.clear();
    _selectedCar = null;
    _carDetails = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _hasMoreData = true;
    notifyListeners();
  }

  // 根据ID查找车辆
  Car? findCarById(int id) {
    try {
      return _cars.firstWhere((car) => car.id == id);
    } catch (e) {
      return null;
    }
  }

  // 检查车牌号是否已存在
  bool isPlateNumberExists(String plateNumber) {
    return _cars.any(
        (car) => car.plateNumber.toLowerCase() == plateNumber.toLowerCase());
  }

  // 检查车架号是否已存在
  bool isVinExists(String vin) {
    return _cars.any((car) => car.vin.toLowerCase() == vin.toLowerCase());
  }
}

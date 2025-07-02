import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/car.dart';

class ApiService {
  static const String _baseUrl = AppConfig.baseUrl;
  static const Duration _timeout = AppConfig.connectTimeout;

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 通用请求方法
  static Future<Map<String, dynamic>> request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint').replace(
        queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())),
      );

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: _headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: _headers,
                body: data != null ? json.encode(data) : null,
              )
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await http
              .put(
                uri,
                headers: _headers,
                body: data != null ? json.encode(data) : null,
              )
              .timeout(_timeout);
          break;
        case 'DELETE':
          response =
              await http.delete(uri, headers: _headers).timeout(_timeout);
          break;
        default:
          throw Exception('不支持的HTTP方法: $method');
      }

      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? '请求失败',
          statusCode: response.statusCode,
          code: responseData['code'],
        );
      }
    } on SocketException {
      throw ApiException(message: '网络连接失败，请检查网络设置');
    } on HttpException {
      throw ApiException(message: 'HTTP请求失败');
    } on FormatException {
      throw ApiException(message: '数据格式错误');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: '请求失败: ${e.toString()}');
    }
  }

  // 车辆相关API
  static Future<Car> createCar(Car car) async {
    final response = await request(
      method: 'POST',
      endpoint: '/cars',
      data: car.toJson(),
    );
    return Car.fromJson(response['data']);
  }

  static Future<Map<String, dynamic>> getCarByPlateNumber(
      String plateNumber) async {
    final response = await request(
      method: 'GET',
      endpoint: '/cars/$plateNumber',
    );
    return response['data'];
  }

  static Future<List<Car>> getCars({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await request(
      method: 'GET',
      endpoint: '/cars',
      queryParams: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
    );
    final cars = (response['data']['cars'] as List)
        .map((json) => Car.fromJson(json))
        .toList();
    return cars;
  }

  static Future<Car> updateCar(int id, Car car) async {
    final response = await request(
      method: 'PUT',
      endpoint: '/cars/$id',
      data: car.toJson(),
    );
    return Car.fromJson(response['data']);
  }

  // 维修记录相关API
  static Future<Repair> createRepair(Repair repair) async {
    final response = await request(
      method: 'POST',
      endpoint: '/repairs',
      data: repair.toJson(),
    );
    return Repair.fromJson(response['data']);
  }

  static Future<List<Repair>> getRepairs({
    int? carId,
    String? plateNumber,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await request(
      method: 'GET',
      endpoint: '/repairs',
      queryParams: {
        if (carId != null) 'car_id': carId,
        if (plateNumber != null && plateNumber.isNotEmpty)
          'plate_number': plateNumber,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
    );
    final repairs = (response['data']['repairs'] as List)
        .map((json) => Repair.fromJson(json))
        .toList();
    return repairs;
  }

  static Future<Repair> getRepair(int id) async {
    final response = await request(
      method: 'GET',
      endpoint: '/repairs/$id',
    );
    return Repair.fromJson(response['data']);
  }

  static Future<Repair> updateRepair(int id, Repair repair) async {
    final response = await request(
      method: 'PUT',
      endpoint: '/repairs/$id',
      data: repair.toJson(),
    );
    return Repair.fromJson(response['data']);
  }

  static Future<void> deleteRepair(int id) async {
    await request(
      method: 'DELETE',
      endpoint: '/repairs/$id',
    );
  }

  // 洗车记录相关API
  static Future<WashLog> createWashLog(WashLog washLog) async {
    final response = await request(
      method: 'POST',
      endpoint: '/wash',
      data: washLog.toJson(),
    );
    return WashLog.fromJson(response['data']);
  }

  static Future<List<WashLog>> getWashLogs({
    int? carId,
    String? plateNumber,
    String? startDate,
    String? endDate,
    String? washType,
    String? location,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await request(
      method: 'GET',
      endpoint: '/wash',
      queryParams: {
        if (carId != null) 'car_id': carId,
        if (plateNumber != null && plateNumber.isNotEmpty)
          'plate_number': plateNumber,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (washType != null) 'wash_type': washType,
        if (location != null && location.isNotEmpty) 'location': location,
        'page': page,
        'limit': limit,
      },
    );
    final washLogs = (response['data']['wash_logs'] as List)
        .map((json) => WashLog.fromJson(json))
        .toList();
    return washLogs;
  }

  static Future<WashLog> getWashLog(int id) async {
    final response = await request(
      method: 'GET',
      endpoint: '/wash/$id',
    );
    return WashLog.fromJson(response['data']);
  }

  static Future<WashLog> updateWashLog(int id, WashLog washLog) async {
    final response = await request(
      method: 'PUT',
      endpoint: '/wash/$id',
      data: washLog.toJson(),
    );
    return WashLog.fromJson(response['data']);
  }

  // 导出CSV文件
  static Future<String> _export(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await http.get(uri, headers: _headers).timeout(_timeout);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw ApiException(
        message: '导出失败',
        statusCode: response.statusCode,
      );
    }
  }

  static Future<String> exportCars() => _export('/cars/export');
  static Future<String> exportRepairs() => _export('/repairs/export');
  static Future<String> exportWashLogs() => _export('/wash/export');
  static Future<String> exportCustomers() => _export('/customers/export');

  static Future<void> deleteWashLog(int id) async {
    await request(
      method: 'DELETE',
      endpoint: '/wash/$id',
    );
  }

  // 统计相关API
  static Future<Map<String, dynamic>> getCarStats(int carId) async {
    final response = await request(
      method: 'GET',
      endpoint: '/cars/$carId/stats',
    );
    return response['data'];
  }

  static Future<Map<String, dynamic>> getRepairStats({
    int? carId,
    String? startDate,
    String? endDate,
  }) async {
    final response = await request(
      method: 'GET',
      endpoint: '/repairs/stats',
      queryParams: {
        if (carId != null) 'car_id': carId,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    return response['data'];
  }

  static Future<Map<String, dynamic>> getWashStats({
    int? carId,
    String? startDate,
    String? endDate,
  }) async {
    final response = await request(
      method: 'GET',
      endpoint: '/wash/stats',
      queryParams: {
        if (carId != null) 'car_id': carId,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    return response['data'];
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode, Code: $code)';
  }
}

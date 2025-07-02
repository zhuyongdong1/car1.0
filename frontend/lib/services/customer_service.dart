import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import '../models/api_exception.dart';

class CustomerService {
  static const String baseUrl = 'http://192.168.1.100:3000/api';

  // 获取客户列表
  static Future<Map<String, dynamic>> getCustomers({
    int page = 1,
    int limit = 10,
    String? search,
    String? customerType,
    String? vipLevel,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/customers').replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (customerType != null) 'customer_type': customerType,
        if (vipLevel != null) 'vip_level': vipLevel,
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'customers': (data['data']['customers'] as List)
              .map((json) => Customer.fromJson(json))
              .toList(),
          'pagination': data['data']['pagination'],
        };
      } else {
        throw ApiException(
          message: data['message'] ?? '获取客户列表失败',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: '网络请求失败: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 获取单个客户详情
  static Future<Map<String, dynamic>> getCustomerById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'customer': Customer.fromJson(data['data']['customer']),
          'stats': CustomerStatistics.fromJson(data['data']['stats']),
        };
      } else {
        throw ApiException(
          message: data['message'] ?? '获取客户详情失败',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: '网络请求失败: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 创建客户
  static Future<Customer> createCustomer(Customer customer) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/customers'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(customer.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return Customer.fromJson(data['data']);
      } else {
        throw ApiException(
          message: data['details'] ?? data['message'] ?? '创建客户失败',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: '网络请求失败: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 更新客户
  static Future<Customer> updateCustomer(int id, Customer customer) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/customers/$id'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(customer.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return Customer.fromJson(data['data']);
      } else {
        throw ApiException(
          message: data['details'] ?? data['message'] ?? '更新客户失败',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: '网络请求失败: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 删除客户
  static Future<void> deleteCustomer(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/customers/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw ApiException(
          message: data['message'] ?? '删除客户失败',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: '网络请求失败: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 搜索客户
  static Future<List<Customer>> searchCustomers(
    String keyword, {
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/customers/search/$keyword').replace(
        queryParameters: {
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return (data['data']['customers'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();
      } else {
        throw ApiException(
          message: data['message'] ?? '搜索客户失败',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: '网络请求失败: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 获取VIP客户列表
  static Future<List<Customer>> getVipCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/vip/list'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return (data['data'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();
      } else {
        throw ApiException(
          message: data['message'] ?? '获取VIP客户失败',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: '网络请求失败: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 更新客户到店信息
  static Future<Customer> updateCustomerVisit(int id, {double? amount}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/customers/$id/visit'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'amount': amount}),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return Customer.fromJson(data['data']);
      } else {
        throw ApiException(
          message: data['message'] ?? '更新到店信息失败',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: '网络请求失败: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 获取客户统计概览
  static Future<CustomerOverview> getCustomerOverview() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/stats/overview'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return CustomerOverview.fromJson(data['data']);
      } else {
        throw ApiException(
          message: data['message'] ?? '获取统计信息失败',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: '网络请求失败: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 验证手机号格式
  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  // 验证身份证号格式
  static bool isValidIdCard(String idCard) {
    if (idCard.isEmpty) return true; // 可选字段
    return RegExp(
            r'^[1-9]\d{5}(18|19|20)\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\d{3}[0-9Xx]$')
        .hasMatch(idCard);
  }

  // 验证邮箱格式
  static bool isValidEmail(String email) {
    if (email.isEmpty) return true; // 可选字段
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // 格式化手机号显示
  static String formatPhoneNumber(String phone) {
    if (phone.length == 11) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  // 获取VIP等级颜色
  static int getVipLevelColor(VipLevel level) {
    switch (level) {
      case VipLevel.normal:
        return 0xFF9E9E9E; // 灰色
      case VipLevel.silver:
        return 0xFFC0C0C0; // 银色
      case VipLevel.gold:
        return 0xFFFFD700; // 金色
      case VipLevel.diamond:
        return 0xFF00BFFF; // 钻石蓝
    }
  }

  // 获取客户类型图标
  static String getCustomerTypeIcon(CustomerType type) {
    switch (type) {
      case CustomerType.personal:
        return '👤';
      case CustomerType.company:
        return '🏢';
    }
  }
}

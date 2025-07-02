import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/car/add_car_page.dart';
import '../pages/car/car_detail_page.dart';
import '../pages/repair/add_repair_page.dart';
import '../pages/repair/repair_list_page.dart';
import '../pages/wash/wash_checkin_page.dart';
import '../pages/wash/wash_list_page.dart';
import '../pages/ocr/ocr_scan_page.dart';
import '../pages/customer/customer_list_page.dart';
import '../pages/customer/add_customer_page.dart';
import '../pages/customer/customer_detail_page.dart';

import '../main.dart';

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => ErrorPage(error: state.error.toString()),
    routes: [
      // 首页
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // 添加车辆
      GoRoute(
        path: '/add-car',
        name: 'add-car',
        builder: (context, state) => const AddCarPage(),
      ),

      // 车辆详情
      GoRoute(
        path: '/car-detail/:id',
        name: 'car-detail',
        builder: (context, state) {
          final carId = int.parse(state.pathParameters['id']!);
          return CarDetailPage(carId: carId);
        },
      ),

      // 添加维修记录
      GoRoute(
        path: '/add-repair',
        name: 'add-repair',
        builder: (context, state) {
          final plateNumber = state.uri.queryParameters['plateNumber'];
          return AddRepairPage(plateNumber: plateNumber);
        },
      ),

      // 维修记录列表
      GoRoute(
        path: '/repair-list',
        name: 'repair-list',
        builder: (context, state) => const RepairListPage(),
      ),

      // 洗车打卡
      GoRoute(
        path: '/wash-checkin',
        name: 'wash-checkin',
        builder: (context, state) {
          final plateNumber = state.uri.queryParameters['plateNumber'];
          return WashCheckinPage(plateNumber: plateNumber);
        },
      ),

      // 洗车记录列表
      GoRoute(
        path: '/wash-list',
        name: 'wash-list',
        builder: (context, state) => const WashListPage(),
      ),

      // OCR文字识别
      GoRoute(
        path: '/ocr-scan',
        name: 'ocr-scan',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OCRScanPage(
            initialType: extra?['type'],
            onResult: extra?['onResult'],
          );
        },
      ),

      // 客户管理
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) => const CustomerListPage(),
      ),

      // 添加客户
      GoRoute(
        path: '/add-customer',
        name: 'add-customer',
        builder: (context, state) => const AddCustomerPage(),
      ),

      // 客户详情
      GoRoute(
        path: '/customer-detail/:id',
        name: 'customer-detail',
        builder: (context, state) {
          final customerId = int.parse(state.pathParameters['id']!);
          return CustomerDetailPage(customerId: customerId);
        },
      ),
    ],
  );

  // 路由名称常量
  static const String home = 'home';
  static const String addCar = 'add-car';
  static const String carDetail = 'car-detail';
  static const String addRepair = 'add-repair';
  static const String repairList = 'repair-list';
  static const String washCheckin = 'wash-checkin';
  static const String washList = 'wash-list';
  static const String ocrScan = 'ocr-scan';
}

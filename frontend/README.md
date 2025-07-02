# 车辆维修记录管理系统 - Flutter前端

## 概述

基于 Flutter 构建的跨平台车辆维修记录管理应用，支持 Android、iOS 和 Web 平台。

## 功能特性

### 🚗 车辆管理
- 添加车辆信息（车牌号、车架号、品牌、型号等）
- 车辆信息查看和编辑
- 车辆列表和搜索功能
- 车辆统计信息展示

### 🔧 维修记录
- 添加维修记录（项目、费用、日期、维修店等）
- 维修记录列表和历史查询
- 维修类型分类管理
- 维修费用统计分析

### 🚿 洗车记录
- 快速洗车打卡功能
- 洗车记录管理
- 洗车类型分类（自助、自动、人工）
- 洗车频次和费用统计

### 📷 OCR识别功能
- 车牌号智能识别
- VIN码自动识别
- 维修发票信息提取
- 支持拍照和相册选择

### 📊 数据统计
- 费用统计图表
- 维修/洗车次数统计
- 时间范围数据分析
- 车辆维护历史分析

## 技术栈

- **Flutter** 3.24.5 - 跨平台开发框架
- **Provider** - 状态管理
- **HTTP/Dio** - 网络请求
- **Flutter Form Builder** - 表单构建
- **Go Router** - 路由导航
- **Image Picker** - 图片选择和拍照
- **Permission Handler** - 权限管理
- **Cached Network Image** - 图片缓存
- **Flutter ScreenUtil** - 响应式设计
- **Google Fonts** - 字体管理

## 项目结构

```
lib/
├── config/             # 配置文件
│   ├── app_config.dart    # 应用配置
│   └── theme_config.dart  # 主题配置
├── models/             # 数据模型
│   ├── car.dart           # 车辆模型
│   ├── customer.dart      # 客户模型
│   └── api_exception.dart # API异常模型
├── pages/              # 页面文件
│   ├── car/               # 车辆相关页面
│   ├── customer/          # 客户相关页面
│   ├── repair/            # 维修相关页面
│   ├── wash/              # 洗车相关页面
│   ├── ocr/               # OCR识别页面
│   └── home_page.dart     # 首页
├── providers/          # 状态管理
│   ├── car_provider.dart     # 车辆状态管理
│   ├── customer_provider.dart # 客户状态管理
│   ├── repair_provider.dart   # 维修状态管理
│   └── wash_provider.dart     # 洗车状态管理
├── services/           # 服务层
│   ├── api_service.dart       # API服务
│   ├── customer_service.dart  # 客户服务
│   └── ocr_service.dart       # OCR服务
├── routes/             # 路由配置
│   └── app_routes.dart
└── main.dart           # 应用入口
```

## 快速开始

### 环境要求
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode / VS Code
- 后端API服务运行在 http://localhost:3000

### 1. 安装依赖
```bash
flutter pub get
```

### 2. 运行应用

#### Web版本（推荐开发测试）
```bash
flutter run -d chrome --web-port=8080
```

#### Android版本
```bash
flutter run -d android
```

#### iOS版本
```bash
flutter run -d ios
```

### 3. 构建应用

#### 构建Android APK
```bash
flutter build apk --release
```

#### 构建iOS应用
```bash
flutter build ios --release
```

#### 构建Web应用
```bash
flutter build web --release
```

## 配置说明

### API配置
在 `lib/config/app_config.dart` 中配置后端API地址：

```dart
class AppConfig {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String ocrUrl = 'http://localhost:3000/api/ocr';
}
```

### 权限配置

#### Android权限 (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

#### iOS权限 (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机以拍摄车牌和发票</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择图片</string>
```

## 开发指南

### 状态管理
项目使用 Provider 进行状态管理：

```dart
// 在main.dart中注册Provider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CarProvider()),
    ChangeNotifierProvider(create: (_) => RepairProvider()),
    // ...
  ],
  child: MyApp(),
)

// 在页面中使用
Consumer<CarProvider>(
  builder: (context, carProvider, child) {
    return ListView.builder(
      itemCount: carProvider.cars.length,
      itemBuilder: (context, index) {
        return CarCard(car: carProvider.cars[index]);
      },
    );
  },
)
```

### API调用
```dart
// 获取车辆列表
final response = await ApiService.get('/cars');
if (response['success']) {
  final cars = (response['data']['cars'] as List)
      .map((json) => Car.fromJson(json))
      .toList();
}
```

### 路由导航
```dart
// 使用Go Router进行导航
context.go('/cars/add');
context.push('/cars/detail/${carId}');
```

## 测试

### 运行测试
```bash
flutter test
```

### 生成测试覆盖率报告
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 部署

### Web部署
1. 构建Web应用：`flutter build web --release`
2. 将 `build/web` 目录部署到Web服务器
3. 配置服务器支持单页应用路由

### 移动应用发布
1. 配置应用签名（Android）或证书（iOS）
2. 构建发布版本：`flutter build apk --release` 或 `flutter build ios --release`
3. 上传到应用商店

## 常见问题

### 1. 网络请求失败
- 检查后端API是否正常运行
- 确认API地址配置正确
- 检查网络权限是否添加

### 2. 图片选择失败
- 确认相机和存储权限已授权
- 检查设备是否支持相机功能

### 3. OCR识别不准确
- 确保图片清晰度足够
- 检查网络连接是否正常
- 验证百度OCR配置是否正确

## 贡献指南

1. Fork 项目
2. 创建特性分支：`git checkout -b feature/new-feature`
3. 提交更改：`git commit -am 'Add some feature'`
4. 推送分支：`git push origin feature/new-feature`
5. 提交Pull Request

## 许可证

MIT License

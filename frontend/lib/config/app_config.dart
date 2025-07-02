class AppConfig {
  static const String appName = '车辆维修记录管理';
  static const String version = '1.0.0';

  // API配置
  static const String baseUrl = 'http://localhost:3000/api';

  // 分页配置
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;

  // 缓存配置
  static const Duration cacheExpiration = Duration(minutes: 30);

  // 请求超时配置
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // 调试模式
  static const bool isDebug = true;

  // 颜色配置
  static const int primaryColorValue = 0xFF2196F3;
  static const int accentColorValue = 0xFF03DAC6;

  // 字体大小
  static const double titleFontSize = 18.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;
}

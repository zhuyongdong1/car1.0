import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'config/app_config.dart';
import 'config/theme_config.dart';
import 'providers/car_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/repair_provider.dart';
import 'providers/wash_provider.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 设置屏幕方向为竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const CarMaintenanceApp());
}

class CarMaintenanceApp extends StatelessWidget {
  const CarMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // 设计稿尺寸
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CarProvider()),
            ChangeNotifierProvider(create: (_) => CustomerProvider()),
            ChangeNotifierProvider(create: (_) => RepairProvider()),
            ChangeNotifierProvider(create: (_) => WashProvider()),
          ],
          child: MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,

            // 主题配置
            theme: ThemeConfig.lightTheme,
            darkTheme: ThemeConfig.darkTheme,
            themeMode: ThemeMode.system,

            // 路由配置
            routerConfig: AppRoutes.router,

            // 国际化支持
            locale: const Locale('zh', 'CN'),
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // 构建器
            builder: (context, widget) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0), // 固定字体大小
                ),
                child: widget!,
              );
            },
          ),
        );
      },
    );
  }
}

/// 全局错误处理页面
class ErrorPage extends StatelessWidget {
  final String? error;

  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('出错了'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100.r,
              color: Colors.red,
            ),
            SizedBox(height: 20.h),
            Text(
              '页面加载失败',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            if (error != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            SizedBox(height: 30.h),
            ElevatedButton(
              onPressed: () {
                context.go('/');
              },
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}

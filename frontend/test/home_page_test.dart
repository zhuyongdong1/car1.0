import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:car_maintenance_app/providers/car_provider.dart';
import 'package:car_maintenance_app/pages/home_page.dart';
import 'package:car_maintenance_app/config/app_config.dart';

void main() {
  testWidgets('HomePage shows app title and FAB', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => CarProvider(),
          child: const HomePage(),
        ),
      ),
    );

    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}

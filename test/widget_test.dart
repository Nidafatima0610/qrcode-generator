import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrcode_generator/main.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';

void main() {
  testWidgets('QR App smoke test with dashboard & tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    // Add an initial item
    await storageService.saveItem(
      QrItem(
        id: 'test_1',
        type: QrType.url,
        title: 'Initial Web QR',
        subtitle: 'https://flutter.dev',
        rawPayload: 'https://flutter.dev',
        createdAt: DateTime.now(),
        isFavorite: true,
      ),
    );

    await tester.pumpWidget(QrApp(storageService: storageService));
    await tester.pumpAndSettle();

    // Verify Dashboard Header & Stat Cards
    expect(find.text('QR Studio Pro'), findsOneWidget);
    expect(find.text('Generated'), findsOneWidget);
    expect(find.text('Total Scans'), findsOneWidget);
    expect(find.text('Favorites'), findsWidgets);
    expect(find.text('Ready-Made QR Templates'), findsOneWidget);
    expect(find.text('Quick Create Formats'), findsOneWidget);

    // Verify item is present in recent list
    expect(find.text('Initial Web QR'), findsOneWidget);

    // Verify Bottom Navigation Bar Destinations
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Scanner'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap on Create tab to test tab navigation
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Select QR Type'), findsOneWidget);
    expect(find.text('Advanced Customization'), findsOneWidget);

    // Tap on History tab to test tab navigation
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('QR Management'), findsOneWidget);
    expect(find.text('Generated (1)'), findsOneWidget);
    expect(find.text('Favorites (1)'), findsOneWidget);
    expect(find.text('Scans (0)'), findsOneWidget);

    // Tap on Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance & Theme'), findsOneWidget);
    expect(find.text('Data & Storage'), findsOneWidget);
  });
}

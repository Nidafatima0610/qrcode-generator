import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrcode_generator/main.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';

void main() {
  testWidgets('QR App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(QrApp(storageService: storageService));
    await tester.pumpAndSettle();

    expect(find.text('QR Studio Pro'), findsOneWidget);
    expect(find.text('Create QR'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
  });
}

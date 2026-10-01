import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/core/theme/theme_controller.dart';
import 'package:qr_code_generator/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:qr_code_generator/features/qr_generator/controllers/qr_generator_controller.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_config.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_payload_type.dart';
import 'package:qr_code_generator/features/qr_generator/utils/qr_payload_encoder.dart';
import 'package:qr_code_generator/features/qr_history/controllers/qr_history_controller.dart';
import 'package:qr_code_generator/features/qr_history/models/qr_item.dart';
import 'package:qr_code_generator/features/qr_history/presentation/screens/qr_detail_screen.dart';
import 'package:qr_code_generator/features/qr_history/presentation/screens/qr_history_screen.dart';
import 'package:qr_code_generator/features/qr_history/presentation/widgets/qr_history_tile.dart';
import 'package:qr_code_generator/features/qr_history/services/qr_storage_service.dart';
import 'package:qr_code_generator/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';
import 'package:qr_code_generator/features/settings/presentation/screens/settings_screen.dart';
import 'package:qr_code_generator/main.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void setScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.instance.init();
    await QrHistoryController.instance.init();
    await QrHistoryController.instance.clearHistory(preserveFavorites: false);
  });

  // =========================================================================
  // 1. QrPayloadEncoder Unit Tests
  // =========================================================================
  group('QrPayloadEncoder Unit Tests', () {
    test('encodeText returns trimmed text', () {
      expect(QrPayloadEncoder.encodeText('  Hello World  '), 'Hello World');
    });

    test('encodeUrl prefixes https:// when protocol is missing', () {
      expect(
        QrPayloadEncoder.encodeUrl('flutter.dev'),
        'https://flutter.dev',
      );
      expect(
        QrPayloadEncoder.encodeUrl('http://example.com'),
        'http://example.com',
      );
      expect(
        QrPayloadEncoder.encodeUrl('https://dart.dev'),
        'https://dart.dev',
      );
    });

    test('encodeWifi formats standard WIFI URI with escaping', () {
      final wifi = QrPayloadEncoder.encodeWifi(
        ssid: 'Home;Network:Special',
        password: 'pass;word:123',
        security: 'WPA/WPA2',
        isHidden: true,
      );
      expect(
        wifi,
        'WIFI:S:Home\\;Network\\:Special;T:WPA;P:pass\\;word\\:123;H:true;;',
      );

      final openWifi = QrPayloadEncoder.encodeWifi(
        ssid: 'CoffeeShop',
        password: '',
        security: 'None',
        isHidden: false,
      );
      expect(openWifi, 'WIFI:S:CoffeeShop;T:nopass;P:;H:false;;');
    });

    test('encodeEmail formats mailto: URI with URL encoded subject and body', () {
      final emailUri = QrPayloadEncoder.encodeEmail(
        email: 'user@example.com',
        subject: 'Meeting Notes & Agenda',
        body: 'Here are the notes: 1, 2, 3!',
      );
      expect(emailUri.startsWith('mailto:user@example.com?'), isTrue);
      expect(emailUri.contains('subject=Meeting%20Notes%20%26%20Agenda'), isTrue);
      expect(emailUri.contains('body=Here%20are%20the%20notes%3A%201%2C%202%2C%203!'), isTrue);

      final simpleEmail = QrPayloadEncoder.encodeEmail(
        email: 'hello@world.com',
        subject: '',
        body: '',
      );
      expect(simpleEmail, 'mailto:hello@world.com');
    });

    test('encodePhone formats tel: URI', () {
      expect(
        QrPayloadEncoder.encodePhone('+1 (555) 019-2834'),
        'tel:+1(555)019-2834',
      );
    });

    test('encodeSms formats smsto: URI', () {
      expect(
        QrPayloadEncoder.encodeSms(
          phone: '+15551234567',
          message: 'See you at 5pm!',
        ),
        'smsto:+15551234567:See you at 5pm!',
      );
    });

    test('encodeContact formats compliant vCard 3.0', () {
      final vcard = QrPayloadEncoder.encodeContact(
        name: 'Ada Lovelace',
        phone: '+15550001111',
        email: 'ada@computing.org',
        organization: 'Babbage Analytics',
      );
      expect(vcard.contains('BEGIN:VCARD'), isTrue);
      expect(vcard.contains('VERSION:3.0'), isTrue);
      expect(vcard.contains('FN:Ada Lovelace'), isTrue);
      expect(vcard.contains('TEL:+15550001111'), isTrue);
      expect(vcard.contains('EMAIL:ada@computing.org'), isTrue);
      expect(vcard.contains('ORG:Babbage Analytics'), isTrue);
      expect(vcard.endsWith('END:VCARD'), isTrue);
    });
  });

  // =========================================================================
  // 2. QrGeneratorController Multi-Type & Customization Unit Tests
  // =========================================================================
  group('QrGeneratorController Unit Tests', () {
    late QrGeneratorController controller;

    setUp(() {
      controller = QrGeneratorController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state is clean with default styling', () {
      expect(controller.currentQr, isNull);
      expect(controller.hasContent, isFalse);
      expect(controller.isQrGenerated, isFalse);
      expect(controller.validationError, isNull);
      expect(controller.payloadType, QrPayloadType.text);
      expect(controller.foregroundColor, AppTheme.qrForegroundColors.first);
      expect(controller.backgroundColor, Colors.white);
      expect(controller.qrSize, 220.0);
      expect(controller.errorCorrectionLevel, QrErrorCorrectLevel.M);
      expect(controller.eyeShape, QrEyeShape.square);
      expect(controller.dataModuleShape, QrDataModuleShape.square);
      expect(controller.hasSafeContrast, isTrue);
    });

    test('Text validation fails when empty, succeeds when populated', () {
      controller.setPayloadType(QrPayloadType.text);
      controller.textController.text = '';
      final failed = controller.generateQr();
      expect(failed, isFalse);
      expect(controller.validationError, isNotNull);

      controller.textController.text = 'Plain text note';
      final success = controller.generateQr();
      expect(success, isTrue);
      expect(controller.currentQr?.content, 'Plain text note');
      expect(controller.currentQr?.payloadType, QrPayloadType.text);
    });

    test('URL validation normalizes missing scheme and validates empty', () {
      controller.setPayloadType(QrPayloadType.url);
      controller.urlController.text = '';
      expect(controller.generateQr(), isFalse);
      expect(controller.validationError, isNotNull);

      controller.urlController.text = 'flutter.dev';
      expect(controller.generateQr(), isTrue);
      expect(controller.currentQr?.content, 'https://flutter.dev');
      expect(controller.urlController.text, 'https://flutter.dev');
    });

    test('Wi-Fi validation checks SSID and password for WPA', () {
      controller.setPayloadType(QrPayloadType.wifi);
      // Empty SSID
      controller.wifiSsidController.text = '';
      expect(controller.generateQr(), isFalse);

      // SSID present, but password missing for WPA
      controller.wifiSsidController.text = 'MyNetwork';
      controller.setWifiSecurity('WPA/WPA2');
      controller.wifiPasswordController.text = '';
      expect(controller.generateQr(), isFalse);

      // Password provided
      controller.wifiPasswordController.text = 'secret123';
      expect(controller.generateQr(), isTrue);
      expect(controller.currentQr?.content.startsWith('WIFI:S:MyNetwork;T:WPA;'), isTrue);

      // Open network needs no password
      controller.setWifiSecurity('None');
      controller.wifiPasswordController.text = '';
      expect(controller.generateQr(), isTrue);
      expect(controller.currentQr?.content.startsWith('WIFI:S:MyNetwork;T:nopass;'), isTrue);
    });

    test('Email validation checks format', () {
      controller.setPayloadType(QrPayloadType.email);
      controller.emailAddressController.text = 'not-an-email';
      expect(controller.generateQr(), isFalse);
      expect(controller.validationError, contains('valid email'));

      controller.emailAddressController.text = 'valid@example.com';
      controller.emailSubjectController.text = 'Subject Test';
      expect(controller.generateQr(), isTrue);
      expect(controller.currentQr?.content.startsWith('mailto:valid@example.com?'), isTrue);
    });

    test('Phone validation checks digit length', () {
      controller.setPayloadType(QrPayloadType.phone);
      controller.phoneController.text = '1';
      expect(controller.generateQr(), isFalse);

      controller.phoneController.text = '+1 234 567 8900';
      expect(controller.generateQr(), isTrue);
      expect(controller.currentQr?.content, 'tel:+12345678900');
    });

    test('SMS validation requires phone and message', () {
      controller.setPayloadType(QrPayloadType.sms);
      controller.smsPhoneController.text = '12345';
      controller.smsMessageController.text = '';
      expect(controller.generateQr(), isFalse);

      controller.smsMessageController.text = 'Test message';
      expect(controller.generateQr(), isTrue);
      expect(controller.currentQr?.content, 'smsto:12345:Test message');
    });

    test('Contact validation requires name and either phone or email', () {
      controller.setPayloadType(QrPayloadType.contact);
      controller.contactNameController.text = '';
      expect(controller.generateQr(), isFalse);

      controller.contactNameController.text = 'Jane Doe';
      // Missing both phone and email
      expect(controller.generateQr(), isFalse);

      controller.contactPhoneController.text = '555-1234';
      expect(controller.generateQr(), isTrue);
      expect(controller.currentQr?.content.contains('FN:Jane Doe'), isTrue);
    });

    test('Customization mutators update live QR code', () {
      controller.textController.text = 'Custom QR';
      controller.generateQr();

      // Color
      const testColor = Color(0xFF2563EB);
      controller.setForegroundColor(testColor);
      expect(controller.foregroundColor, testColor);
      expect(controller.currentQr?.foregroundColor, testColor);

      // Background
      const testBg = Color(0xFFF8FAFC);
      controller.setBackgroundColor(testBg);
      expect(controller.backgroundColor, testBg);
      expect(controller.currentQr?.backgroundColor, testBg);

      // Size
      controller.setQrSize(260.0);
      expect(controller.qrSize, 260.0);
      expect(controller.currentQr?.qrSize, 260.0);

      // Error correction
      controller.setErrorCorrectionLevel(QrErrorCorrectLevel.H);
      expect(controller.errorCorrectionLevel, QrErrorCorrectLevel.H);
      expect(controller.currentQr?.errorCorrectionLevel, QrErrorCorrectLevel.H);

      // Shapes
      controller.setEyeShape(QrEyeShape.circle);
      controller.setDataModuleShape(QrDataModuleShape.circle);
      expect(controller.eyeShape, QrEyeShape.circle);
      expect(controller.dataModuleShape, QrDataModuleShape.circle);
      expect(controller.currentQr?.eyeShape, QrEyeShape.circle);
      expect(controller.currentQr?.dataModuleShape, QrDataModuleShape.circle);
    });

    test('Contrast ratio calculation and safe contrast warning flag', () {
      // High contrast: Black on White
      controller.setForegroundColor(Colors.black);
      controller.setBackgroundColor(Colors.white);
      expect(controller.hasSafeContrast, isTrue);
      expect(controller.contrastRatio, greaterThan(15.0));

      // Low contrast: Light Amber on White
      controller.setForegroundColor(const Color(0xFFFEF3C7));
      controller.setBackgroundColor(Colors.white);
      expect(controller.hasSafeContrast, isFalse);
      expect(controller.contrastRatio, lessThan(3.0));
    });

    test('resetAll clears all input forms and restores default styling', () {
      controller.setPayloadType(QrPayloadType.wifi);
      controller.wifiSsidController.text = 'MyNetwork';
      controller.wifiPasswordController.text = 'secret';
      controller.setForegroundColor(const Color(0xFFEF4444));
      controller.setBackgroundColor(const Color(0xFFFEF2F2));
      controller.setQrSize(280.0);
      controller.setEyeShape(QrEyeShape.circle);
      controller.setDataModuleShape(QrDataModuleShape.circle);
      controller.generateQr();
      expect(controller.isQrGenerated, isTrue);

      controller.resetAll();

      expect(controller.isQrGenerated, isFalse);
      expect(controller.currentQr, isNull);
      expect(controller.payloadType, QrPayloadType.text);
      expect(controller.wifiSsidController.text, isEmpty);
      expect(controller.wifiPasswordController.text, isEmpty);
      expect(controller.foregroundColor, AppTheme.qrForegroundColors.first);
      expect(controller.backgroundColor, Colors.white);
      expect(controller.qrSize, 220.0);
      expect(controller.eyeShape, QrEyeShape.square);
      expect(controller.dataModuleShape, QrDataModuleShape.square);
    });

    test('loadFromItem restores styling and extracts form data', () {
      final item = QrItem(
        id: '123',
        content: 'https://docs.flutter.dev',
        createdAt: DateTime.now(),
        payloadType: QrPayloadType.url,
        foregroundColor: const Color(0xFF0D9488),
        backgroundColor: const Color(0xFFF0FDFA),
        qrSize: 250.0,
        errorCorrectionLevel: QrErrorCorrectLevel.Q,
        eyeShape: QrEyeShape.circle,
        dataModuleShape: QrDataModuleShape.circle,
      );

      controller.loadFromItem(item);

      expect(controller.payloadType, QrPayloadType.url);
      expect(controller.urlController.text, 'https://docs.flutter.dev');
      expect(controller.foregroundColor, const Color(0xFF0D9488));
      expect(controller.backgroundColor, const Color(0xFFF0FDFA));
      expect(controller.qrSize, 250.0);
      expect(controller.errorCorrectionLevel, QrErrorCorrectLevel.Q);
      expect(controller.eyeShape, QrEyeShape.circle);
      expect(controller.dataModuleShape, QrDataModuleShape.circle);
      expect(controller.isQrGenerated, isTrue);
    });
  });

  // =========================================================================
  // 3. QrHistoryController & Storage Compatibility Unit Tests
  // =========================================================================
  group('QrHistoryController & Storage Unit Tests', () {
    test('QrItem.fromJson parses legacy record without breaking', () {
      final legacyJson = {
        'id': 'legacy-1',
        'content': 'Plain old content',
        'createdAt': '2026-09-01T10:00:00.000',
        'isFavorite': true,
        'payloadType': 'text',
      };

      final item = QrItem.fromJson(legacyJson);
      expect(item.id, 'legacy-1');
      expect(item.content, 'Plain old content');
      expect(item.isFavorite, isTrue);
      expect(item.payloadType, QrPayloadType.text);
      expect(item.foregroundColor, const Color(0xFF0F172A));
      expect(item.backgroundColor, Colors.white);
      expect(item.qrSize, 220.0);
      expect(item.errorCorrectionLevel, QrErrorCorrectLevel.M);
      expect(item.eyeShape, QrEyeShape.square);
      expect(item.dataModuleShape, QrDataModuleShape.square);
    });

    test('addOrUpdate saves new item and deduplicates matching content', () async {
      final controller = QrHistoryController.instance;

      await controller.addOrUpdate(
        QrConfig(
          content: 'https://flutter.dev',
          payloadType: QrPayloadType.url,
        ),
      );
      expect(controller.allItems.length, 1);
      final firstId = controller.allItems.first.id;

      await controller.toggleFavorite(firstId);
      expect(controller.allItems.first.isFavorite, isTrue);

      // Re-adding same content preserves favorite flag and updates timestamp
      await controller.addOrUpdate(
        QrConfig(
          content: 'https://flutter.dev',
          payloadType: QrPayloadType.url,
        ),
      );
      expect(controller.allItems.length, 1);
      expect(controller.allItems.first.isFavorite, isTrue);
    });

    test('toggleFavorite updates favorite status and filtered lists', () async {
      final controller = QrHistoryController.instance;
      final item = await controller.addOrUpdate(
        QrConfig(
          content: 'Important Note',
          payloadType: QrPayloadType.text,
        ),
      );

      expect(controller.favoriteItems.length, 0);
      await controller.toggleFavorite(item.id);
      expect(controller.favoriteItems.length, 1);
      expect(controller.favoriteItems.first.content, 'Important Note');

      await controller.toggleFavorite(item.id);
      expect(controller.favoriteItems.length, 0);
    });

    test('deleteItem removes specific record from history', () async {
      final controller = QrHistoryController.instance;
      final item1 = await controller.addOrUpdate(
        QrConfig(content: 'Item 1', payloadType: QrPayloadType.text),
      );
      await controller.addOrUpdate(
        QrConfig(content: 'Item 2', payloadType: QrPayloadType.text),
      );
      expect(controller.allItems.length, 2);

      await controller.deleteItem(item1.id);
      expect(controller.allItems.length, 1);
      expect(controller.allItems.first.content, 'Item 2');
    });

    test('clearHistory with preserveFavorites preserves favorited items', () async {
      final controller = QrHistoryController.instance;
      await controller.addOrUpdate(
        QrConfig(content: 'Regular Item', payloadType: QrPayloadType.text),
      );
      final item2 = await controller.addOrUpdate(
        QrConfig(content: 'Favorite Item', payloadType: QrPayloadType.text),
      );

      await controller.toggleFavorite(item2.id);

      await controller.clearHistory(preserveFavorites: true);
      expect(controller.allItems.length, 1);
      expect(controller.allItems.first.content, 'Favorite Item');

      await controller.clearHistory(preserveFavorites: false);
      expect(controller.allItems.length, 0);
    });

    test('Search filters history items correctly', () async {
      final controller = QrHistoryController.instance;
      await controller.addOrUpdate(
        QrConfig(content: 'Apple pie recipe', payloadType: QrPayloadType.text),
      );
      await controller.addOrUpdate(
        QrConfig(content: 'Banana bread recipe', payloadType: QrPayloadType.text),
      );

      controller.setSearchQuery('apple');
      expect(controller.filteredHistoryItems.length, 1);
      expect(controller.filteredHistoryItems.first.content, 'Apple pie recipe');

      controller.clearSearch();
      expect(controller.filteredHistoryItems.length, 2);
    });

    test('Storage persistence preserves custom styling across instances', () async {
      final storage = QrStorageService();
      final originalController = QrHistoryController(storageService: storage);
      await originalController.addOrUpdate(
        QrConfig(
          content: 'Persistent Token',
          payloadType: QrPayloadType.text,
          foregroundColor: const Color(0xFF7C3AED),
          backgroundColor: const Color(0xFFFAF5FF),
          qrSize: 260.0,
          eyeShape: QrEyeShape.circle,
          dataModuleShape: QrDataModuleShape.circle,
        ),
      );

      final reloadedController = QrHistoryController(storageService: storage);
      await reloadedController.init();
      expect(reloadedController.allItems.length, 1);
      final loaded = reloadedController.allItems.first;
      expect(loaded.content, 'Persistent Token');
      expect(loaded.foregroundColor, const Color(0xFF7C3AED));
      expect(loaded.backgroundColor, const Color(0xFFFAF5FF));
      expect(loaded.qrSize, 260.0);
      expect(loaded.eyeShape, QrEyeShape.circle);
      expect(loaded.dataModuleShape, QrDataModuleShape.circle);
    });
  });

  // =========================================================================
  // 4. QR Code Generator, Navigation, Settings & Widget Tests
  // =========================================================================
  group('QR Code Generator & History Widget Tests', () {
    testWidgets('App renders QR Generator with type selector chips and quick templates',
        (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      expect(find.text('QR Generator'), findsOneWidget);
      expect(find.text('Ready to Generate'), findsOneWidget);

      // Verify presence of type selector & template chips
      expect(find.text('Plain Text'), findsOneWidget);
      expect(find.text('Website / URL'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsWidgets);
      expect(find.text('Quick Templates'), findsOneWidget);
    });

    testWidgets('Shows validation message when input is empty', (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      final generateButton = find.widgetWithText(ElevatedButton, 'Generate QR Code');
      expect(generateButton, findsOneWidget);
      await tester.ensureVisible(generateButton);
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter some text to generate a QR code.'),
        findsOneWidget,
      );
    });

    testWidgets('Switching type selector renders dedicated form fields', (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // 1. Switch to Website / URL
      final urlChip = find.text('Website / URL');
      expect(urlChip, findsOneWidget);
      await tester.tap(urlChip);
      await tester.pumpAndSettle();

      expect(find.text('https://example.com or website.com'), findsOneWidget);

      // 2. Switch to Wi-Fi via type selector
      final wifiChips = find.text('Wi-Fi');
      await tester.tap(wifiChips.last);
      await tester.pumpAndSettle();

      expect(find.text('Network Name (SSID) *'), findsOneWidget);
      expect(find.text('Wi-Fi Password *'), findsOneWidget);
      expect(find.text('Security:'), findsOneWidget);

      // 3. Switch back to Plain Text
      final textChip = find.text('Plain Text');
      expect(textChip, findsOneWidget);
      await tester.tap(textChip);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Generates QR code on valid input and displays customization panel',
        (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Hello Custom QR!');
      await tester.pumpAndSettle();

      final generateButton = find.widgetWithText(ElevatedButton, 'Generate QR Code');
      await tester.ensureVisible(generateButton);
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      expect(find.text('Generated QR Code'), findsOneWidget);
      expect(find.text('Hello Custom QR!'), findsWidgets);
      expect(find.byType(QrImageView), findsOneWidget);

      // Customization panel items should be visible
      expect(find.text('Live QR Customization'), findsOneWidget);
      expect(find.text('Dots & Eyes Color:'), findsOneWidget);
      expect(find.text('Canvas Background:'), findsOneWidget);
      expect(find.text('Recovery Level: '), findsOneWidget);
      expect(find.text('Dots Shape:'), findsOneWidget);
    });

    testWidgets('Tapping preset button generates QR code immediately', (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      final presetChip = find.text('https://flutter.dev');
      expect(presetChip, findsOneWidget);
      await tester.ensureVisible(presetChip);
      await tester.tap(presetChip);
      await tester.pumpAndSettle();

      expect(find.text('Generated QR Code'), findsOneWidget);
      expect(find.text('https://flutter.dev'), findsWidgets);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('Reset button clears form and restores empty state', (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // Generate a QR code first
      final presetChip = find.text('https://flutter.dev');
      await tester.ensureVisible(presetChip);
      await tester.tap(presetChip);
      await tester.pumpAndSettle();

      expect(find.text('Generated QR Code'), findsOneWidget);

      // Tap Reset button in AppBar
      final resetButton = find.widgetWithIcon(IconButton, Icons.refresh_rounded);
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // State is reset to initial empty state
      expect(find.text('Ready to Generate'), findsOneWidget);
      expect(find.text('Plain Text'), findsOneWidget);
    });

    testWidgets('Navigating to History screen displays saved record', (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // Generate a QR code
      final presetChip = find.text('https://flutter.dev');
      await tester.ensureVisible(presetChip);
      await tester.tap(presetChip);
      await tester.pumpAndSettle();

      // Tap History icon button in AppBar
      final historyButton = find.widgetWithIcon(IconButton, Icons.history_rounded);
      expect(historyButton, findsOneWidget);
      await tester.tap(historyButton);
      await tester.pumpAndSettle();

      // Verify on History screen
      expect(find.byType(QrHistoryScreen), findsOneWidget);
      expect(find.text('History & Favorites'), findsOneWidget);
      expect(find.byType(QrHistoryTile), findsOneWidget);
      expect(find.text('https://flutter.dev'), findsWidgets);
    });

    testWidgets('Favoriting in history moves item to Favorites tab', (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // Generate QR
      await tester.tap(find.text('https://flutter.dev'));
      await tester.pumpAndSettle();

      // Open History via AppBar
      await tester.tap(find.widgetWithIcon(IconButton, Icons.history_rounded));
      await tester.pumpAndSettle();

      // Tap favorite icon on history tile
      final favButton = find.byTooltip('Add to favorites');
      expect(favButton, findsOneWidget);
      await tester.tap(favButton);
      await tester.pumpAndSettle();

      // Switch to Favorites tab
      final favoritesTab = find.text('Favorites (1)');
      expect(favoritesTab, findsOneWidget);
      await tester.tap(favoritesTab);
      await tester.pumpAndSettle();

      // Verify item exists in favorites tab
      expect(find.byType(QrHistoryTile), findsOneWidget);
    });

    testWidgets('Tapping history item opens QR Detail screen with custom styling',
        (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // Generate QR
      await tester.tap(find.text('https://flutter.dev'));
      await tester.pumpAndSettle();

      // Open History
      await tester.tap(find.widgetWithIcon(IconButton, Icons.history_rounded));
      await tester.pumpAndSettle();

      // Tap tile
      await tester.tap(find.byType(QrHistoryTile));
      await tester.pumpAndSettle();

      // Verify Detail screen
      expect(find.byType(QrDetailScreen), findsOneWidget);
      expect(find.text('QR Details'), findsOneWidget);
      expect(find.text('Save Image'), findsOneWidget);
      expect(find.text('Share QR'), findsOneWidget);
      expect(find.text('Open in Generator'), findsOneWidget);
    });

    testWidgets('Open in Generator loads content and styling back to main screen',
        (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // Generate QR first
      await tester.tap(find.text('https://flutter.dev'));
      await tester.pumpAndSettle();

      // Reset generator to empty state
      await tester.tap(find.widgetWithIcon(IconButton, Icons.refresh_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Ready to Generate'), findsOneWidget);

      // Open History and Detail screen
      await tester.tap(find.widgetWithIcon(IconButton, Icons.history_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(QrHistoryTile));
      await tester.pumpAndSettle();

      // Tap "Open in Generator"
      final openInGenButton = find.text('Open in Generator');
      await tester.ensureVisible(openInGenButton);
      await tester.tap(openInGenButton);
      await tester.pumpAndSettle();

      // Should be back on main screen with QR generated!
      expect(find.text('QR Generator'), findsOneWidget);
      expect(find.text('Generated QR Code'), findsOneWidget);
      expect(find.text('https://flutter.dev'), findsWidgets);
    });

    testWidgets('NavigationBar switches to Scan, History, and Settings tabs',
        (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // 1. Switch to Scan tab
      final scanTab = find.byIcon(Icons.qr_code_scanner_outlined);
      expect(scanTab, findsOneWidget);
      await tester.tap(scanTab);
      await tester.pumpAndSettle();

      expect(find.byType(QrScannerScreen), findsOneWidget);
      expect(find.text('Scan QR Code'), findsOneWidget);

      // 2. Switch to Settings tab
      final settingsTab = find.byIcon(Icons.settings_outlined);
      expect(settingsTab, findsOneWidget);
      await tester.tap(settingsTab);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('OnboardingScreen navigates across pages and completes',
        (WidgetTester tester) async {
      setScreenSize(tester);
      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onFinish: () => finished = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create & Customize QR Codes'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Tap Next to go to Page 2
      final nextButton = find.widgetWithText(ElevatedButton, 'Next');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('Scan from Camera & Gallery'), findsOneWidget);

      // Tap Next to go to Page 3
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('Offline History & Favorites'), findsOneWidget);
      final getStartedButton = find.widgetWithText(ElevatedButton, 'Get Started');
      expect(getStartedButton, findsOneWidget);

      // Tap Get Started
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      expect(finished, isTrue);
    });
  });
}

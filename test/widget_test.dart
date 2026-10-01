import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_generator/features/qr_generator/controllers/qr_generator_controller.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_payload_type.dart';
import 'package:qr_code_generator/main.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  void setScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('QrGeneratorController Unit Tests', () {
    late QrGeneratorController controller;

    setUp(() {
      controller = QrGeneratorController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state is clean', () {
      expect(controller.currentQr, isNull);
      expect(controller.hasContent, isFalse);
      expect(controller.isQrGenerated, isFalse);
      expect(controller.validationError, isNull);
      expect(controller.payloadType, QrPayloadType.text);
    });

    test('generateQr fails on empty input and sets validationError', () {
      final success = controller.generateQr();
      expect(success, isFalse);
      expect(controller.isQrGenerated, isFalse);
      expect(controller.validationError, isNotNull);
    });

    test('generateQr succeeds on valid input', () {
      controller.textController.text = 'https://example.com';
      final success = controller.generateQr();
      expect(success, isTrue);
      expect(controller.isQrGenerated, isTrue);
      expect(controller.currentQr?.content, 'https://example.com');
      expect(controller.validationError, isNull);
    });

    test('Normalizes URL payload without http prefix', () {
      controller.setPayloadType(QrPayloadType.url);
      controller.textController.text = 'flutter.dev';
      controller.generateQr();
      expect(controller.currentQr?.content, 'https://flutter.dev');
    });

    test('resetAll clears controller state back to initial', () {
      controller.textController.text = 'sample';
      controller.generateQr();
      expect(controller.isQrGenerated, isTrue);

      controller.resetAll();
      expect(controller.isQrGenerated, isFalse);
      expect(controller.hasContent, isFalse);
      expect(controller.currentQr, isNull);
    });
  });

  group('QR Code Generator Widget Tests', () {
    testWidgets('App renders QR Generator with empty state and presets',
        (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // Verify AppBar title is present
      expect(find.text('QR Generator'), findsOneWidget);

      // Verify empty state is displayed initially
      expect(find.text('Ready to Generate'), findsOneWidget);
      expect(find.text('https://flutter.dev'), findsOneWidget);
    });

    testWidgets('Shows validation message when input is empty',
        (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // Tap generate button without entering text
      final generateButton =
          find.widgetWithText(ElevatedButton, 'Generate QR Code');
      expect(generateButton, findsOneWidget);
      await tester.ensureVisible(generateButton);
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      // Verify validation error text is displayed
      expect(
        find.text('Please enter some text, a URL, or contact details.'),
        findsOneWidget,
      );
    });

    testWidgets('Generates QR code on valid input', (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // Enter text in input field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Hello QR Code!');
      await tester.pumpAndSettle();

      // Tap generate button
      final generateButton =
          find.widgetWithText(ElevatedButton, 'Generate QR Code');
      await tester.ensureVisible(generateButton);
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      // Verify QR code display card is visible and displays encoded text
      expect(find.text('Generated QR Code'), findsOneWidget);
      expect(find.text('Hello QR Code!'), findsWidgets);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('Tapping preset button generates QR code immediately',
        (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // Tap preset chip
      final presetChip = find.text('https://flutter.dev');
      expect(presetChip, findsOneWidget);
      await tester.ensureVisible(presetChip);
      await tester.tap(presetChip);
      await tester.pumpAndSettle();

      // Verify QR code is generated for the preset
      expect(find.text('Generated QR Code'), findsOneWidget);
      expect(find.text('https://flutter.dev'), findsWidgets);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('Reset button clears generated QR and returns to empty state',
        (WidgetTester tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(const QrCodeGeneratorApp());
      await tester.pumpAndSettle();

      // Generate a QR code first via preset
      final presetChip = find.text('https://flutter.dev');
      await tester.ensureVisible(presetChip);
      await tester.tap(presetChip);
      await tester.pumpAndSettle();
      expect(find.text('Generated QR Code'), findsOneWidget);

      // Tap reset button in AppBar
      final resetButton = find.byTooltip('Reset all');
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Verify returned to empty state
      expect(find.text('Ready to Generate'), findsOneWidget);
    });
  });
}

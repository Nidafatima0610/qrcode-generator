import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrcode_generator/core/models/qr_customization.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/qr_template.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/models/scan_item.dart';
import 'package:qrcode_generator/core/services/qr_payload_builder.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QR Types & Payload Builders', () {
    test('Location QR payload generation and parsing', () {
      final payload = QrPayloadBuilder.buildLocation(
        latitude: 37.7749,
        longitude: -122.4194,
        name: 'San Francisco HQ',
      );
      expect(payload, contains('maps.google.com'));
      expect(payload, contains('37.7749'));
      expect(payload, contains('-122.4194'));

      final parsed = QrPayloadBuilder.parse(payload);
      expect(parsed.type, QrType.location);
      expect(parsed.displayTitle, 'San Francisco HQ');
    });

    test('Social Profile QR payload generation and parsing', () {
      final igPayload = QrPayloadBuilder.buildSocial(
        platform: 'Instagram',
        usernameOrUrl: 'qrstudiopro',
      );
      expect(igPayload, 'https://instagram.com/qrstudiopro');

      final igParsed = QrPayloadBuilder.parse(igPayload);
      expect(igParsed.type, QrType.social);
      expect(igParsed.displayTitle, 'Instagram Profile');

      final liPayload = QrPayloadBuilder.buildSocial(
        platform: 'LinkedIn',
        usernameOrUrl: 'john-doe',
      );
      expect(liPayload, 'https://linkedin.com/in/john-doe');
      final liParsed = QrPayloadBuilder.parse(liPayload);
      expect(liParsed.type, QrType.social);
      expect(liParsed.displayTitle, 'LinkedIn Profile');
    });

    test('Wi-Fi QR payload parsing', () {
      const wifi = 'WIFI:T:WPA;S:HomeNetwork;P:SecretPass123;H:false;;';
      final parsed = QrPayloadBuilder.parse(wifi);
      expect(parsed.type, QrType.wifi);
      expect(parsed.displayTitle, 'HomeNetwork');
      expect(parsed.details['Password'], 'SecretPass123');
    });

    test('Contact vCard payload parsing', () {
      final vcard = QrPayloadBuilder.buildContact(
        firstName: 'Alice',
        lastName: 'Wonder',
        phone: '+15551234567',
        email: 'alice@example.com',
        company: 'Wonderland Inc',
        address: '100 Rabbit Hole',
        website: 'https://wonderland.io',
      );
      final parsed = QrPayloadBuilder.parse(vcard);
      expect(parsed.type, QrType.contact);
      expect(parsed.displayTitle, 'Alice Wonder');
      expect(parsed.details['Phone'], '+15551234567');
      expect(parsed.details['Email'], 'alice@example.com');
    });
  });

  group('QR Customization Model', () {
    test('Default values and serialization with eyeShape and dataModuleShape', () {
      const custom = QrCustomization(
        foregroundColor: Color(0xFF1E1B4B),
        backgroundColor: Color(0xFFEEF2FF),
        size: 260.0,
        errorCorrectionLevel: 'H',
        eyeShape: 'circle',
        dataModuleShape: 'circle',
      );

      final map = custom.toMap();
      expect(map['eyeShape'], 'circle');
      expect(map['dataModuleShape'], 'circle');
      expect(map['errorCorrectionLevel'], 'H');

      final deserialized = QrCustomization.fromMap(map);
      expect(deserialized.eyeShape, 'circle');
      expect(deserialized.dataModuleShape, 'circle');
      expect(deserialized.size, 260.0);
    });

    test('Backward compatibility with legacy map missing new fields', () {
      final legacyMap = {
        'foregroundColor': const Color(0xFF000000).toARGB32(),
        'backgroundColor': const Color(0xFFFFFFFF).toARGB32(),
        'size': 240.0,
        'errorCorrectionLevel': 'M',
      };

      final deserialized = QrCustomization.fromMap(legacyMap);
      expect(deserialized.eyeShape, 'square');
      expect(deserialized.dataModuleShape, 'square');
      expect(deserialized.errorCorrectionLevel, 'M');
    });
  });

  group('Built-in Templates', () {
    test('All templates are valid and have initial values', () {
      final templates = QrTemplate.builtInTemplates;
      expect(templates, isNotEmpty);
      expect(templates.length, greaterThanOrEqualTo(8));

      for (final t in templates) {
        expect(t.id, isNotEmpty);
        expect(t.title, isNotEmpty);
        expect(t.category, isNotEmpty);
        expect(t.initialValues, isNotEmpty);
      }
    });
  });

  group('StorageService - Favorites & History & Scans', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Add item, mark favorite, and test favorites filtering', () async {
      final service = await StorageService.init();

      final item1 = QrItem(
        id: '1',
        type: QrType.url,
        title: 'Website',
        subtitle: 'https://example.com',
        rawPayload: 'https://example.com',
        createdAt: DateTime.now(),
        isFavorite: false,
      );

      final item2 = QrItem(
        id: '2',
        type: QrType.wifi,
        title: 'Office WiFi',
        subtitle: 'Security: WPA',
        rawPayload: 'WIFI:S:Office;P:pass;;',
        createdAt: DateTime.now(),
        isFavorite: true,
      );

      await service.saveItem(item1);
      await service.saveItem(item2);

      expect(service.history.length, 2);
      expect(service.favorites.length, 1);
      expect(service.favorites.first.id, '2');

      // Toggle item1 to favorite
      final status = await service.toggleFavorite('1');
      expect(status, true);
      expect(service.favorites.length, 2);

      // Toggle item2 off favorite
      final status2 = await service.toggleFavorite('2');
      expect(status2, false);
      expect(service.favorites.length, 1);
      expect(service.favorites.first.id, '1');
    });

    test('Clear history with preserveFavorites = true', () async {
      final service = await StorageService.init();

      final normalItem = QrItem(
        id: 'normal',
        type: QrType.text,
        title: 'Note',
        subtitle: 'Sub',
        rawPayload: 'Hello',
        createdAt: DateTime.now(),
        isFavorite: false,
      );

      final favItem = QrItem(
        id: 'fav',
        type: QrType.url,
        title: 'Favorite Web',
        subtitle: 'Sub',
        rawPayload: 'https://fav.com',
        createdAt: DateTime.now(),
        isFavorite: true,
      );

      await service.saveItem(normalItem);
      await service.saveItem(favItem);

      expect(service.history.length, 2);

      // Clear history with preserveFavorites = true (default)
      await service.clearHistory(preserveFavorites: true);

      expect(service.history.length, 1);
      expect(service.history.first.id, 'fav');
      expect(service.favorites.length, 1);

      // Clear with preserveFavorites = false
      await service.clearHistory(preserveFavorites: false);
      expect(service.history.length, 0);
      expect(service.favorites.length, 0);
    });

    test('Batch deletion of items', () async {
      final service = await StorageService.init();

      for (int i = 1; i <= 5; i++) {
        await service.saveItem(
          QrItem(
            id: 'item_$i',
            type: QrType.text,
            title: 'Item $i',
            subtitle: 'Sub $i',
            rawPayload: 'Content $i',
            createdAt: DateTime.now(),
          ),
        );
      }

      expect(service.history.length, 5);

      await service.deleteMultiple(['item_2', 'item_4']);
      expect(service.history.length, 3);
      expect(service.history.any((e) => e.id == 'item_2'), false);
      expect(service.history.any((e) => e.id == 'item_4'), false);
    });

    test('Scan history management', () async {
      final service = await StorageService.init();

      final scan1 = ScanItem(
        id: 'scan_1',
        rawContent: 'https://scanned.com',
        detectedType: QrType.url,
        title: 'scanned.com',
        subtitle: 'https://scanned.com',
        scannedAt: DateTime.now(),
      );

      final scan2 = ScanItem(
        id: 'scan_2',
        rawContent: 'tel:+15551234567',
        detectedType: QrType.phone,
        title: '+15551234567',
        subtitle: 'Phone Number',
        scannedAt: DateTime.now(),
      );

      await service.saveScanItem(scan1);
      await service.saveScanItem(scan2);

      expect(service.scanHistory.length, 2);
      expect(service.totalScans, 2);

      await service.deleteScanItem('scan_1');
      expect(service.scanHistory.length, 1);
      expect(service.scanHistory.first.id, 'scan_2');

      await service.clearScanHistory();
      expect(service.scanHistory.length, 0);
      expect(service.totalScans, 0);
    });

    test('Rapid scan duplicate suppression within 3 seconds', () async {
      final service = await StorageService.init();

      final scan1 = ScanItem(
        id: 'rapid_1',
        rawContent: 'https://fastscan.com',
        detectedType: QrType.url,
        title: 'fastscan.com',
        subtitle: 'https://fastscan.com',
        scannedAt: DateTime.now(),
      );

      final scanRapidDuplicate = ScanItem(
        id: 'rapid_2',
        rawContent: 'https://fastscan.com',
        detectedType: QrType.url,
        title: 'fastscan.com',
        subtitle: 'https://fastscan.com',
        scannedAt: DateTime.now(),
      );

      await service.saveScanItem(scan1);
      // Immediately second callback with same content
      await service.saveScanItem(scanRapidDuplicate);

      expect(service.scanHistory.length, 1);
      expect(service.scanHistory.first.id, 'rapid_1');
    });

    test('Collections management and safe deletion', () async {
      final service = await StorageService.init();

      await service.createCollection('Work');
      await service.createCollection('Personal');
      expect(service.collections.contains('Work'), true);
      expect(service.collections.contains('Personal'), true);

      final item = QrItem(
        id: 'col_item_1',
        type: QrType.url,
        title: 'Work Portal',
        subtitle: 'https://work.com',
        rawPayload: 'https://work.com',
        createdAt: DateTime.now(),
      );
      await service.saveItem(item);
      await service.assignCollection(item.id, 'Work');

      expect(service.history.first.collection, 'Work');

      // Rename collection
      await service.renameCollection('Work', 'Office');
      expect(service.collections.contains('Office'), true);
      expect(service.collections.contains('Work'), false);
      expect(service.history.first.collection, 'Office');

      // Delete collection must NOT delete the QR code itself
      await service.deleteCollection('Office');
      expect(service.collections.contains('Office'), false);
      expect(service.history.length, 1);
      expect(service.history.first.id, 'col_item_1');
      expect(service.history.first.collection, null);
    });

    test('Notes support on QR items', () async {
      final service = await StorageService.init();

      final item = QrItem(
        id: 'note_item_1',
        type: QrType.wifi,
        title: 'HQ Guest',
        subtitle: 'Wi-Fi Network',
        rawPayload: 'WIFI:S:HQGuest;T:WPA;P:Guest123;;',
        createdAt: DateTime.now(),
      );
      await service.saveItem(item);
      expect(service.history.first.note, null);

      await service.updateItemNote(item.id, 'For meeting room 3B');
      expect(service.history.first.note, 'For meeting room 3B');

      await service.updateItemNote(item.id, null);
      expect(service.history.first.note, null);
    });

    test('High Contrast Preset and Contrast Ratio Readability', () {
      final highContrastPreset = QrDesignPreset.builtInPresets
          .firstWhere((p) => p.id == 'high_contrast');
      expect(highContrastPreset.customization.foregroundColor, Colors.black);
      expect(highContrastPreset.customization.backgroundColor, Colors.white);
      expect(highContrastPreset.customization.errorCorrectionLevel, 'H');
      expect(highContrastPreset.customization.hasSufficientContrast, true);
      expect(highContrastPreset.customization.contrastRatio, greaterThan(15.0));

      // Test bad contrast (white on light yellow)
      const lowContrast = QrCustomization(
        foregroundColor: Color(0xFFFFFFFE),
        backgroundColor: Color(0xFFFFFBEB),
      );
      expect(lowContrast.hasSufficientContrast, false);
      expect(lowContrast.contrastRatio, lessThan(3.0));
    });

    test('Backup & Restore JSON Schema v2', () async {
      final service = await StorageService.init();

      await service.createCollection('TestCol');
      final item = QrItem(
        id: 'backup_qr_1',
        type: QrType.text,
        title: 'Backup Test',
        subtitle: 'Sub text',
        rawPayload: 'Payload 123',
        createdAt: DateTime.now(),
        note: 'Important note',
        collection: 'TestCol',
      );
      await service.saveItem(item);

      final scan = ScanItem(
        id: 'backup_scan_1',
        rawContent: 'https://scanned-backup.com',
        detectedType: QrType.url,
        title: 'scanned-backup.com',
        subtitle: 'https://scanned-backup.com',
        scannedAt: DateTime.now(),
      );
      await service.saveScanItem(scan);

      // Export
      final jsonBackup = service.exportBackupJson();
      expect(jsonBackup, contains('"schemaVersion": 2'));
      expect(jsonBackup, contains('backup_qr_1'));
      expect(jsonBackup, contains('Important note'));
      expect(jsonBackup, contains('TestCol'));
      expect(jsonBackup, contains('backup_scan_1'));

      // Test invalid restore
      final badResult = await service.importBackupJson('not a json');
      expect(badResult.success, false);

      // Clear all and test restore in replace mode
      await service.clearHistory(preserveFavorites: false);
      await service.clearScanHistory();
      expect(service.history.isEmpty, true);
      expect(service.scanHistory.isEmpty, true);

      final restoreResult = await service.importBackupJson(jsonBackup, replace: true);
      expect(restoreResult.success, true);
      expect(restoreResult.importedHistory, 1);
      expect(restoreResult.importedScans, 1);
      expect(service.history.length, 1);
      expect(service.history.first.title, 'Backup Test');
      expect(service.history.first.note, 'Important note');
      expect(service.history.first.collection, 'TestCol');
      expect(service.scanHistory.length, 1);
      expect(service.collections.contains('TestCol'), true);
    });
  });
}

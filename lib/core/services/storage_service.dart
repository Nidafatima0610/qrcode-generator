import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:qrcode_generator/core/models/qr_customization.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/qr_preset.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/models/scan_item.dart';

class StorageService extends ChangeNotifier {
  static const String _historyKey = 'qr_history_v1';
  static const String _scanHistoryKey = 'qr_scan_history_v1';
  static const String _presetsKey = 'qr_presets_v1';
  static const String _collectionsKey = 'qr_collections_v1';
  static const String _themeKey = 'app_theme_mode_v1';
  static const String _onboardingKey = 'qr_onboarding_completed_v1';
  static const String _defaultQrSizeKey = 'pref_default_qr_size';
  static const String _defaultEccKey = 'pref_default_ecc';
  static const String _defaultExportModeKey = 'pref_default_export_mode';
  static const String _confirmBeforeOpenKey = 'pref_confirm_before_open';
  static const String _scannerTorchKey = 'pref_scanner_torch_default';

  final SharedPreferences _prefs;
  List<QrItem> _history = [];
  List<ScanItem> _scanHistory = [];
  List<QrPreset> _presets = [];
  List<String> _collections = [];
  ThemeMode _themeMode = ThemeMode.system;
  bool _initialized = false;

  StorageService(this._prefs) {
    _loadAll();
  }

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool get isInitialized => _initialized;
  List<QrItem> get history => List.unmodifiable(_history);
  List<ScanItem> get scanHistory => List.unmodifiable(_scanHistory);
  List<QrPreset> get presets => List.unmodifiable(_presets);
  List<String> get collections => List.unmodifiable(_collections);
  List<QrItem> get favorites => _history.where((e) => e.isFavorite).toList();
  ThemeMode get themeMode => _themeMode;

  // Onboarding
  bool get hasCompletedOnboarding =>
      _prefs.getBool(_onboardingKey) ?? false;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  // Preferences
  double get defaultQrSize => _prefs.getDouble(_defaultQrSizeKey) ?? 240.0;
  String get defaultErrorCorrection =>
      _prefs.getString(_defaultEccKey) ?? 'M';
  String get defaultExportMode =>
      _prefs.getString(_defaultExportModeKey) ?? 'card';

  Future<void> setDefaultQrSize(double val) async {
    await _prefs.setDouble(_defaultQrSizeKey, val);
    notifyListeners();
  }

  Future<void> setDefaultErrorCorrection(String val) async {
    await _prefs.setString(_defaultEccKey, val);
    notifyListeners();
  }

  Future<void> setDefaultExportMode(String val) async {
    await _prefs.setString(_defaultExportModeKey, val);
    notifyListeners();
  }

  // Scanner preferences
  bool get confirmBeforeOpen => _prefs.getBool(_confirmBeforeOpenKey) ?? true;
  bool get scannerTorchDefault => _prefs.getBool(_scannerTorchKey) ?? false;

  Future<void> setConfirmBeforeOpen(bool val) async {
    await _prefs.setBool(_confirmBeforeOpenKey, val);
    notifyListeners();
  }

  Future<void> setScannerTorchDefault(bool val) async {
    await _prefs.setBool(_scannerTorchKey, val);
    notifyListeners();
  }

  // Real data statistics
  int get totalGenerated => _history.length;
  int get totalScans => _scanHistory.length;
  int get totalFavorites => _history.where((e) => e.isFavorite).length;

  void _loadAll() {
    // 1. Load QR Generation History
    final rawList = _prefs.getStringList(_historyKey);
    if (rawList != null) {
      _history = rawList
          .map((itemStr) {
            try {
              return QrItem.fromJson(itemStr);
            } catch (e) {
              return null;
            }
          })
          .whereType<QrItem>()
          .toList();
    } else {
      _history = [];
    }

    // 2. Load Scanned QR History
    final rawScanList = _prefs.getStringList(_scanHistoryKey);
    if (rawScanList != null) {
      _scanHistory = rawScanList
          .map((itemStr) {
            try {
              return ScanItem.fromJson(itemStr);
            } catch (e) {
              return null;
            }
          })
          .whereType<ScanItem>()
          .toList();
    } else {
      _scanHistory = [];
    }

    // 3. Load Presets
    final rawPresets = _prefs.getStringList(_presetsKey);
    if (rawPresets != null) {
      _presets = rawPresets
          .map((itemStr) {
            try {
              return QrPreset.fromJson(itemStr);
            } catch (e) {
              return null;
            }
          })
          .whereType<QrPreset>()
          .toList();
    } else {
      // Seed default presets if none exist yet
      _presets = [
        QrPreset(
          id: 'preset_biz_card_default',
          name: 'Business Card Style',
          type: QrType.businessCard,
          defaultTitle: 'My Business Card',
          customization: const QrCustomization(
            foregroundColor: Color(0xFF0F172A),
            backgroundColor: Color(0xFFF8FAFC),
            dataModuleShape: 'circle',
            eyeShape: 'rounded',
            errorCorrectionLevel: 'H',
          ),
          createdAt: DateTime.now(),
        ),
        QrPreset(
          id: 'preset_wifi_home_default',
          name: 'Wi-Fi Home',
          type: QrType.wifi,
          defaultTitle: 'Home Wi-Fi Network',
          customization: const QrCustomization(
            foregroundColor: Color(0xFF064E3B),
            backgroundColor: Color(0xFFECFDF5),
            errorCorrectionLevel: 'M',
          ),
          createdAt: DateTime.now(),
        ),
        QrPreset(
          id: 'preset_dark_website_default',
          name: 'Website Dark',
          type: QrType.url,
          defaultTitle: 'Company Site',
          customization: const QrCustomization(
            foregroundColor: Color(0xFFFFFFFF),
            backgroundColor: Color(0xFF0F172A),
            errorCorrectionLevel: 'Q',
          ),
          createdAt: DateTime.now(),
        ),
        QrPreset(
          id: 'preset_contact_qr_default',
          name: 'Contact QR',
          type: QrType.contact,
          defaultTitle: 'Personal Contact',
          customization: const QrCustomization(
            foregroundColor: Color(0xFF4C1D95),
            backgroundColor: Color(0xFFF5F3FF),
            eyeShape: 'rounded',
            errorCorrectionLevel: 'M',
          ),
          createdAt: DateTime.now(),
        ),
      ];
      _persistPresets();
    }

    // 4. Load Collections
    final rawCollections = _prefs.getStringList(_collectionsKey);
    if (rawCollections != null && rawCollections.isNotEmpty) {
      _collections = List<String>.from(rawCollections);
    } else {
      _collections = ['Work', 'Personal', 'Business', 'Marketing'];
      _persistCollections();
    }

    // 5. Load Theme
    final themeStr = _prefs.getString(_themeKey);
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    _initialized = true;
    notifyListeners();
  }

  /// Add or update an item in history
  Future<void> saveItem(QrItem item) async {
    final index = _history.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      _history[index] = item;
    } else {
      _history.insert(0, item);
    }

    // Keep up to 500 items
    if (_history.length > 500) {
      _history = _history.sublist(0, 500);
    }

    await _persistHistory();
    notifyListeners();
  }

  /// Save multiple items in bulk (for Bulk QR generation)
  Future<void> saveMultipleItems(List<QrItem> items) async {
    for (final item in items.reversed) {
      final index = _history.indexWhere((e) => e.id == item.id);
      if (index >= 0) {
        _history[index] = item;
      } else {
        _history.insert(0, item);
      }
    }

    if (_history.length > 500) {
      _history = _history.sublist(0, 500);
    }

    await _persistHistory();
    notifyListeners();
  }

  /// Toggle favorite status of a QR item
  Future<bool> toggleFavorite(String id) async {
    final index = _history.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final current = _history[index];
      final updated = current.copyWith(isFavorite: !current.isFavorite);
      _history[index] = updated;
      await _persistHistory();
      notifyListeners();
      return updated.isFavorite;
    }
    return false;
  }

  /// Bulk toggle favorites
  Future<void> toggleFavoritesBulk(List<String> ids, bool isFavorite) async {
    final idSet = ids.toSet();
    for (int i = 0; i < _history.length; i++) {
      if (idSet.contains(_history[i].id)) {
        _history[i] = _history[i].copyWith(isFavorite: isFavorite);
      }
    }
    await _persistHistory();
    notifyListeners();
  }

  /// Unfavorite all items (keeps items in history safely)
  Future<void> clearFavorites() async {
    for (int i = 0; i < _history.length; i++) {
      if (_history[i].isFavorite) {
        _history[i] = _history[i].copyWith(isFavorite: false);
      }
    }
    await _persistHistory();
    notifyListeners();
  }

  /// Delete an individual item from history
  Future<void> deleteItem(String id) async {
    _history.removeWhere((e) => e.id == id);
    await _persistHistory();
    notifyListeners();
  }

  /// Delete multiple items from history in batch
  Future<void> deleteMultiple(List<String> ids) async {
    final idSet = ids.toSet();
    _history.removeWhere((e) => idSet.contains(e.id));
    await _persistHistory();
    notifyListeners();
  }

  /// Clear history with option to preserve favorites
  Future<void> clearHistory({bool preserveFavorites = true}) async {
    if (preserveFavorites) {
      _history.removeWhere((e) => !e.isFavorite);
    } else {
      _history.clear();
    }
    await _persistHistory();
    notifyListeners();
  }

  // ================= PRESETS METHODS =================

  /// Save or update a preset
  Future<void> savePreset(QrPreset preset) async {
    final index = _presets.indexWhere((e) => e.id == preset.id);
    if (index >= 0) {
      _presets[index] = preset;
    } else {
      _presets.insert(0, preset);
    }
    await _persistPresets();
    notifyListeners();
  }

  /// Delete a preset
  Future<void> deletePreset(String id) async {
    _presets.removeWhere((e) => e.id == id);
    await _persistPresets();
    notifyListeners();
  }

  /// Rename a preset
  Future<void> renamePreset(String id, String newName) async {
    final index = _presets.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _presets[index] = _presets[index].copyWith(name: newName);
      await _persistPresets();
      notifyListeners();
    }
  }

  /// Duplicate an existing preset
  Future<QrPreset?> duplicatePreset(String id) async {
    final index = _presets.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final orig = _presets[index];
      final duplicated = orig.copyWith(
        id: const Uuid().v4(),
        name: '${orig.name} (Copy)',
        createdAt: DateTime.now(),
      );
      _presets.insert(index + 1, duplicated);
      await _persistPresets();
      notifyListeners();
      return duplicated;
    }
    return null;
  }

  // ================= COLLECTIONS METHODS =================

  /// Create a new custom collection
  Future<bool> createCollection(String name) async {
    final clean = name.trim();
    if (clean.isEmpty || _collections.contains(clean)) return false;
    _collections.add(clean);
    await _persistCollections();
    notifyListeners();
    return true;
  }

  /// Rename an existing collection and update items belonging to it
  Future<void> renameCollection(String oldName, String newName) async {
    final cleanOld = oldName.trim();
    final cleanNew = newName.trim();
    if (cleanNew.isEmpty || cleanOld == cleanNew) return;

    final index = _collections.indexOf(cleanOld);
    if (index >= 0) {
      _collections[index] = cleanNew;
      // Update any QR items tagged with oldName
      for (int i = 0; i < _history.length; i++) {
        if (_history[i].collection == cleanOld) {
          _history[i] = _history[i].copyWith(collection: cleanNew);
        }
      }
      await _persistCollections();
      await _persistHistory();
      notifyListeners();
    }
  }

  /// Delete a collection; by default keeps the QR items and just unassigns the tag
  Future<void> deleteCollection(String name, {bool deleteItems = false}) async {
    final clean = name.trim();
    _collections.remove(clean);

    if (deleteItems) {
      _history.removeWhere((item) => item.collection == clean);
    } else {
      for (int i = 0; i < _history.length; i++) {
        if (_history[i].collection == clean) {
          _history[i] = _history[i].copyWith(clearCollection: true);
        }
      }
    }

    await _persistCollections();
    await _persistHistory();
    notifyListeners();
  }

  /// Assign or remove collection on a QR item
  Future<void> assignCollection(String itemId, String? collectionName) async {
    final index = _history.indexWhere((e) => e.id == itemId);
    if (index >= 0) {
      final current = _history[index];
      _history[index] = current.copyWith(
        collection: collectionName,
        clearCollection: collectionName == null,
      );
      await _persistHistory();
      notifyListeners();
    }
  }

  /// Update or remove short note on a QR item
  Future<void> updateItemNote(String itemId, String? note) async {
    final index = _history.indexWhere((e) => e.id == itemId);
    if (index >= 0) {
      final current = _history[index];
      _history[index] = current.copyWith(
        note: note,
        clearNote: note == null || note.trim().isEmpty,
      );
      await _persistHistory();
      notifyListeners();
    }
  }

  // ================= SCAN HISTORY METHODS =================

  /// Save or update a scanned QR item with duplicate suppression for rapid repeat callbacks
  Future<void> saveScanItem(ScanItem item) async {
    // Suppress accidental duplicate callbacks within 3 seconds of the most recent scan
    if (_scanHistory.isNotEmpty &&
        _scanHistory.first.rawContent == item.rawContent &&
        DateTime.now().difference(_scanHistory.first.scannedAt).inSeconds < 3) {
      return;
    }

    _scanHistory.insert(0, item);

    if (_scanHistory.length > 500) {
      _scanHistory = _scanHistory.sublist(0, 500);
    }

    await _persistScanHistory();
    notifyListeners();
  }

  /// Delete individual scan item
  Future<void> deleteScanItem(String id) async {
    _scanHistory.removeWhere((e) => e.id == id);
    await _persistScanHistory();
    notifyListeners();
  }

  /// Delete multiple scan items in batch
  Future<void> deleteMultipleScanItems(List<String> ids) async {
    final idSet = ids.toSet();
    _scanHistory.removeWhere((e) => idSet.contains(e.id));
    await _persistScanHistory();
    notifyListeners();
  }

  /// Clear all scan history
  Future<void> clearScanHistory() async {
    _scanHistory.clear();
    await _prefs.remove(_scanHistoryKey);
    notifyListeners();
  }

  // ================= THEME METHODS =================

  /// Update app theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await _prefs.setString(_themeKey, modeStr);
    notifyListeners();
  }

  // ================= BACKUP & RESTORE =================

  /// Generate complete JSON backup export containing history, favorites, scans, presets, collections, and settings
  String exportBackupJson() {
    final Map<String, dynamic> data = {
      'schemaVersion': 2,
      'appName': 'QR Studio Pro',
      'exportedAt': DateTime.now().toIso8601String(),
      'history': _history.map((e) => e.toMap()).toList(),
      'scanHistory': _scanHistory.map((e) => e.toMap()).toList(),
      'presets': _presets.map((e) => e.toMap()).toList(),
      'collections': _collections,
      'settings': {
        'themeMode': _themeMode.name,
        'defaultQrSize': defaultQrSize,
        'defaultEcc': defaultErrorCorrection,
        'defaultExportMode': defaultExportMode,
        'confirmBeforeOpen': confirmBeforeOpen,
        'scannerTorchDefault': scannerTorchDefault,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Validate and import JSON backup data with option to Merge or Replace
  Future<BackupRestoreResult> importBackupJson(String jsonString, {bool replace = false}) async {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        return const BackupRestoreResult(
          success: false,
          errorMessage: 'Invalid JSON format. Expected root object.',
        );
      }

      // 1. History
      final List<QrItem> importedHistory = [];
      if (decoded['history'] is List) {
        for (final raw in decoded['history']) {
          if (raw is Map) {
            try {
              importedHistory.add(QrItem.fromMap(Map<String, dynamic>.from(raw)));
            } catch (_) {}
          }
        }
      }

      // 2. Scan History
      final List<ScanItem> importedScans = [];
      if (decoded['scanHistory'] is List) {
        for (final raw in decoded['scanHistory']) {
          if (raw is Map) {
            try {
              importedScans.add(ScanItem.fromMap(Map<String, dynamic>.from(raw)));
            } catch (_) {}
          }
        }
      }

      // 3. Presets
      final List<QrPreset> importedPresets = [];
      if (decoded['presets'] is List) {
        for (final raw in decoded['presets']) {
          if (raw is Map) {
            try {
              importedPresets.add(QrPreset.fromMap(Map<String, dynamic>.from(raw)));
            } catch (_) {}
          }
        }
      }

      // 4. Collections
      final List<String> importedCollections = [];
      if (decoded['collections'] is List) {
        for (final c in decoded['collections']) {
          if (c is String && c.trim().isNotEmpty) {
            importedCollections.add(c.trim());
          }
        }
      }

      if (replace) {
        _history = importedHistory;
        _scanHistory = importedScans;
        if (importedPresets.isNotEmpty) _presets = importedPresets;
        if (importedCollections.isNotEmpty) _collections = importedCollections;
      } else {
        // Merge mode: Add items if ID not already present
        final existingIds = _history.map((e) => e.id).toSet();
        for (final item in importedHistory) {
          if (!existingIds.contains(item.id)) {
            _history.add(item);
            existingIds.add(item.id);
          }
        }

        final existingScanIds = _scanHistory.map((e) => e.id).toSet();
        for (final s in importedScans) {
          if (!existingScanIds.contains(s.id)) {
            _scanHistory.add(s);
            existingScanIds.add(s.id);
          }
        }

        final existingPresetIds = _presets.map((e) => e.id).toSet();
        for (final p in importedPresets) {
          if (!existingPresetIds.contains(p.id)) {
            _presets.add(p);
            existingPresetIds.add(p.id);
          }
        }

        final colSet = _collections.toSet();
        for (final c in importedCollections) {
          if (!colSet.contains(c)) {
            _collections.add(c);
            colSet.add(c);
          }
        }
      }

      // 5. Restore settings if present
      if (decoded['settings'] is Map) {
        final s = decoded['settings'] as Map;
        if (s['defaultQrSize'] is num) {
          await setDefaultQrSize((s['defaultQrSize'] as num).toDouble());
        }
        if (s['defaultEcc'] is String) {
          await setDefaultErrorCorrection(s['defaultEcc'] as String);
        }
        if (s['defaultExportMode'] is String) {
          await setDefaultExportMode(s['defaultExportMode'] as String);
        }
        if (s['confirmBeforeOpen'] is bool) {
          await setConfirmBeforeOpen(s['confirmBeforeOpen'] as bool);
        }
        if (s['scannerTorchDefault'] is bool) {
          await setScannerTorchDefault(s['scannerTorchDefault'] as bool);
        }
        if (s['themeMode'] is String) {
          final tm = s['themeMode'] as String;
          if (tm == 'light') await setThemeMode(ThemeMode.light);
          if (tm == 'dark') await setThemeMode(ThemeMode.dark);
          if (tm == 'system') await setThemeMode(ThemeMode.system);
        }
      }

      await _persistHistory();
      await _persistScanHistory();
      await _persistPresets();
      await _persistCollections();
      notifyListeners();
      return BackupRestoreResult(
        success: true,
        importedHistory: importedHistory.length,
        importedScans: importedScans.length,
        importedPresets: importedPresets.length,
        importedCollections: importedCollections.length,
      );
    } catch (e) {
      return BackupRestoreResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  // ================= PERSISTENCE HELPERS =================

  Future<void> _persistHistory() async {
    final strList = _history.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_historyKey, strList);
  }

  Future<void> _persistScanHistory() async {
    final strList = _scanHistory.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_scanHistoryKey, strList);
  }

  Future<void> _persistPresets() async {
    final strList = _presets.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_presetsKey, strList);
  }

  Future<void> _persistCollections() async {
    await _prefs.setStringList(_collectionsKey, _collections);
  }
}

class BackupRestoreResult {
  final bool success;
  final int importedHistory;
  final int importedScans;
  final int importedPresets;
  final int importedCollections;
  final String? errorMessage;

  const BackupRestoreResult({
    required this.success,
    this.importedHistory = 0,
    this.importedScans = 0,
    this.importedPresets = 0,
    this.importedCollections = 0,
    this.errorMessage,
  });
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/scan_item.dart';

class StorageService extends ChangeNotifier {
  static const String _historyKey = 'qr_history_v1';
  static const String _scanHistoryKey = 'qr_scan_history_v1';
  static const String _themeKey = 'app_theme_mode_v1';

  final SharedPreferences _prefs;
  List<QrItem> _history = [];
  List<ScanItem> _scanHistory = [];
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
  List<QrItem> get favorites => _history.where((e) => e.isFavorite).toList();
  ThemeMode get themeMode => _themeMode;

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

    // 3. Load Theme
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

    // Keep up to 300 items
    if (_history.length > 300) {
      _history = _history.sublist(0, 300);
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

  // ================= SCAN HISTORY METHODS =================

  /// Save or update a scanned QR item
  Future<void> saveScanItem(ScanItem item) async {
    final index =
        _scanHistory.indexWhere((e) => e.rawContent == item.rawContent);
    if (index >= 0) {
      _scanHistory.removeAt(index);
    }
    _scanHistory.insert(0, item);

    if (_scanHistory.length > 300) {
      _scanHistory = _scanHistory.sublist(0, 300);
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

  // ================= PERSISTENCE HELPERS =================

  Future<void> _persistHistory() async {
    final strList = _history.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_historyKey, strList);
  }

  Future<void> _persistScanHistory() async {
    final strList = _scanHistory.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_scanHistoryKey, strList);
  }
}

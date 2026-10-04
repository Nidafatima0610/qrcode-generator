import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';

class StorageService extends ChangeNotifier {
  static const String _historyKey = 'qr_history_v1';
  static const String _themeKey = 'app_theme_mode_v1';

  final SharedPreferences _prefs;
  List<QrItem> _history = [];
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
  ThemeMode get themeMode => _themeMode;

  void _loadAll() {
    // 1. Load History
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

    // 2. Load Theme
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

    // Keep up to 200 items
    if (_history.length > 200) {
      _history = _history.sublist(0, 200);
    }

    await _persistHistory();
    notifyListeners();
  }

  /// Delete an item from history
  Future<void> deleteItem(String id) async {
    _history.removeWhere((e) => e.id == id);
    await _persistHistory();
    notifyListeners();
  }

  /// Clear all history
  Future<void> clearHistory() async {
    _history.clear();
    await _prefs.remove(_historyKey);
    notifyListeners();
  }

  /// Update app theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await _prefs.setString(_themeKey, modeStr);
    notifyListeners();
  }

  Future<void> _persistHistory() async {
    final strList = _history.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_historyKey, strList);
  }
}

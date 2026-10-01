import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/qr_item.dart';

/// Service responsible for persisting and retrieving QR history and favorites
/// using lightweight local storage (SharedPreferences).
class QrStorageService {
  static const String _storageKey = 'qr_history_records_v1';

  /// Loads all saved QR history items from local storage.
  /// Handles missing or corrupt entries gracefully without losing remaining data.
  Future<List<QrItem>> loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawData = prefs.getString(_storageKey);

      if (rawData == null || rawData.trim().isEmpty) {
        return [];
      }

      final dynamic decoded = jsonDecode(rawData);
      if (decoded is! List) {
        return [];
      }

      final List<QrItem> items = [];
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          try {
            items.add(QrItem.fromJson(entry));
          } catch (_) {
            // Skip single corrupt record safely
          }
        }
      }

      return items;
    } catch (_) {
      // In case of complete read/parse error, return empty list
      return [];
    }
  }

  /// Persists the list of QR history items to local storage.
  Future<bool> saveItems(List<QrItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => item.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      return await prefs.setString(_storageKey, encoded);
    } catch (_) {
      return false;
    }
  }

  /// Clears all stored items permanently.
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (_) {
      return false;
    }
  }
}

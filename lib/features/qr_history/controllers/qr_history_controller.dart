import 'package:flutter/material.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_config.dart';
import '../models/qr_item.dart';
import '../services/qr_storage_service.dart';

/// Controller managing QR generation history, favorites, searching, and persistence.
class QrHistoryController extends ChangeNotifier {
  static final QrHistoryController instance = QrHistoryController();

  final QrStorageService _storageService;

  List<QrItem> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';

  QrHistoryController({QrStorageService? storageService})
      : _storageService = storageService ?? QrStorageService() {
    init();
  }

  // State Getters
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.trim().isNotEmpty;
  List<QrItem> get allItems => List.unmodifiable(_items);
  List<QrItem> get favoriteItems =>
      List.unmodifiable(_items.where((item) => item.isFavorite));

  /// Filtered history items based on search query.
  List<QrItem> get filteredHistoryItems {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return allItems;
    return _items
        .where((item) => item.content.toLowerCase().contains(query))
        .toList();
  }

  /// Filtered favorite items based on search query.
  List<QrItem> get filteredFavoriteItems {
    final query = _searchQuery.trim().toLowerCase();
    final favs = _items.where((item) => item.isFavorite);
    if (query.isEmpty) return favs.toList();
    return favs
        .where((item) => item.content.toLowerCase().contains(query))
        .toList();
  }

  /// Checks if given content is marked as favorite.
  bool isContentFavorite(String content) {
    final trimmed = content.trim();
    return _items.any((item) => item.content.trim() == trimmed && item.isFavorite);
  }

  /// Loads history records from local storage.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _storageService.loadItems();
    } catch (_) {
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves or updates a generated QR code into history.
  /// Deduplicates identical content: updates timestamp, preserves favorite status,
  /// and moves the item to the top.
  Future<QrItem> addOrUpdate(QrConfig config) async {
    final cleanContent = config.content.trim();
    if (cleanContent.isEmpty) {
      throw ArgumentError('Content cannot be empty');
    }

    final existingIndex = _items.indexWhere(
      (item) => item.content.trim() == cleanContent,
    );

    QrItem targetItem;

    if (existingIndex != -1) {
      final existing = _items.removeAt(existingIndex);
      targetItem = existing.copyWith(
        createdAt: DateTime.now(),
        payloadType: config.payloadType,
        foregroundColor: config.foregroundColor,
        backgroundColor: config.backgroundColor,
        errorCorrectionLevel: config.errorCorrectionLevel,
        qrSize: config.qrSize,
        eyeShape: config.eyeShape,
        dataModuleShape: config.dataModuleShape,
      );
    } else {
      targetItem = QrItem(
        id: '${DateTime.now().microsecondsSinceEpoch}_${_items.length}',
        content: config.content,
        createdAt: DateTime.now(),
        isFavorite: false,
        payloadType: config.payloadType,
        foregroundColor: config.foregroundColor,
        backgroundColor: config.backgroundColor,
        errorCorrectionLevel: config.errorCorrectionLevel,
        qrSize: config.qrSize,
        eyeShape: config.eyeShape,
        dataModuleShape: config.dataModuleShape,
      );
    }

    _items.insert(0, targetItem);
    await _storageService.saveItems(_items);
    notifyListeners();
    return targetItem;
  }

  /// Toggles favorite status for a specific history item by ID.
  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final current = _items[index];
    _items[index] = current.copyWith(isFavorite: !current.isFavorite);
    await _storageService.saveItems(_items);
    notifyListeners();
  }

  /// Toggles favorite status for a given content string.
  Future<void> toggleFavoriteForContent(QrConfig config) async {
    final cleanContent = config.content.trim();
    final index = _items.indexWhere(
      (item) => item.content.trim() == cleanContent,
    );

    if (index != -1) {
      await toggleFavorite(_items[index].id);
    } else {
      // If not yet in history, add it as a favorite directly
      final item = await addOrUpdate(config);
      await toggleFavorite(item.id);
    }
  }

  /// Deletes a single history item by ID.
  Future<void> deleteItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _storageService.saveItems(_items);
    notifyListeners();
  }

  /// Clears history with explicit choice to preserve favorites.
  Future<void> clearHistory({required bool preserveFavorites}) async {
    if (preserveFavorites) {
      _items.removeWhere((item) => !item.isFavorite);
    } else {
      _items.clear();
    }
    await _storageService.saveItems(_items);
    notifyListeners();
  }

  /// Updates search filter query.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Clears the active search filter.
  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    notifyListeners();
  }
}

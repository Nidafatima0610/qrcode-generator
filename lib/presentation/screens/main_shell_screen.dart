import 'package:flutter/material.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/screens/home/home_screen.dart';
import 'package:qrcode_generator/presentation/screens/create/create_screen.dart';
import 'package:qrcode_generator/presentation/screens/history/history_screen.dart';
import 'package:qrcode_generator/presentation/screens/scanner/scanner_screen.dart';
import 'package:qrcode_generator/presentation/screens/settings/settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  final StorageService storageService;

  const MainShellScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  QrType _createInitialType = QrType.url;
  int _historySubTab = 0;
  String? _historyCollection;
  Map<String, dynamic>? _createInitialValues;
  int _createScreenKeySeed = 0;
  int _historyKeySeed = 0;

  void _onNavigateToTab(
    int index, [
    QrType? initialType,
    int? historySubTab,
    Map<String, dynamic>? initialValues,
    String? initialCollection,
  ]) {
    setState(() {
      _currentIndex = index;
      if (initialType != null) {
        _createInitialType = initialType;
      }
      if (historySubTab != null) {
        _historySubTab = historySubTab;
      }
      if (initialValues != null) {
        _createInitialValues = initialValues;
      }
      _historyCollection = initialCollection;
      _historyKeySeed++;
      _createScreenKeySeed++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        storageService: widget.storageService,
        onNavigateToTab: _onNavigateToTab,
      ),
      CreateScreen(
        key: ValueKey('create_${_createInitialType.name}_$_createScreenKeySeed'),
        storageService: widget.storageService,
        initialType: _createInitialType,
        initialValues: _createInitialValues,
      ),
      HistoryScreen(
        key: ValueKey('history_${_historySubTab}_${_historyCollection ?? ""}_$_historyKeySeed'),
        storageService: widget.storageService,
        onNavigateToTab: _onNavigateToTab,
        initialSubTab: _historySubTab,
        initialCollection: _historyCollection,
      ),
      ScannerScreen(
        storageService: widget.storageService,
      ),
      SettingsScreen(
        storageService: widget.storageService,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

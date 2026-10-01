import 'package:flutter/material.dart';
import 'package:qr_code_generator/features/qr_generator/presentation/screens/qr_generator_screen.dart';
import 'package:qr_code_generator/features/qr_history/presentation/screens/qr_history_screen.dart';
import 'package:qr_code_generator/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';
import 'package:qr_code_generator/features/settings/presentation/screens/settings_screen.dart';

/// Top-level navigation container hosting Create, Scan, History, and Settings.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  int _historyTab = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index, {int historyTab = 0}) {
    setState(() {
      _currentIndex = index;
      _historyTab = historyTab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Create
          QrGeneratorScreen(
            onNavigateTab: (targetIndex, {int historyTab = 0}) {
              switchTab(targetIndex, historyTab: historyTab);
            },
          ),
          // 1: Scan
          const QrScannerScreen(),
          // 2: History & Favorites
          QrHistoryScreen(initialTabIndex: _historyTab),
          // 3: Settings
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box_rounded),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
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

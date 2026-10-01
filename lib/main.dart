import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/navigation/presentation/screens/main_navigation_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/qr_history/controllers/qr_history_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for transparent navigation & clean status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  await ThemeController.instance.init();
  await QrHistoryController.instance.init();

  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool(OnboardingScreen.prefKey) ?? false;

  runApp(QrCodeGeneratorApp(showOnboarding: !hasCompletedOnboarding));
}

/// Root widget of the QR Code Generator application.
class QrCodeGeneratorApp extends StatefulWidget {
  final bool showOnboarding;

  const QrCodeGeneratorApp({
    super.key,
    this.showOnboarding = false,
  });

  @override
  State<QrCodeGeneratorApp> createState() => _QrCodeGeneratorAppState();
}

class _QrCodeGeneratorAppState extends State<QrCodeGeneratorApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'QR Code Generator',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: _showOnboarding
              ? OnboardingScreen(
                  onFinish: () {
                    setState(() => _showOnboarding = false);
                  },
                )
              : const MainNavigationScreen(),
        );
      },
    );
  }
}

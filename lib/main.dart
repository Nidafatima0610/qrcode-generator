import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qrcode_generator/core/constants/app_theme.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/screens/main_shell_screen.dart';
import 'package:qrcode_generator/presentation/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations & transparent system UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final storageService = await StorageService.init();

  runApp(QrApp(storageService: storageService));
}

class QrApp extends StatelessWidget {
  final StorageService storageService;

  const QrApp({
    super.key,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: storageService,
      builder: (context, _) {
        return MaterialApp(
          title: 'QR Studio Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: storageService.themeMode,
          home: storageService.hasCompletedOnboarding
              ? MainShellScreen(storageService: storageService)
              : OnboardingScreen(
                  storageService: storageService,
                  onFinish: () {},
                ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'splash_screen.dart'; // Import SplashScreen
import 'services/notification_service.dart'; // Import NotificationService

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this
  WebViewPlatform.instance; // Add this

  // Initialize notification service on app startup
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('✅ Notification service initialized in main()');
  } catch (e) {
    print('⚠️ Error initializing notification service in main(): $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waqafer',
      debugShowCheckedModeBanner: false, //remove debug banner
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale(
        'ms',
        'MY',
      ), // Set default to Bahasa Melayu (Malaysia)
      supportedLocales: const [
        Locale('ms', 'MY'), // Bahasa Melayu
        Locale('en', 'US'), // English
      ],
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.light(
          primary: Colors.teal,
          secondary: const Color(0xFFFBC02D), // Golden Yellow
          background: Colors.white,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.black,
          onSurface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.teal),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Direct to SplashScreen on app start
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'splash_screen.dart'; // Import SplashScreen
import 'services/notification_service.dart'; // Import NotificationService
import 'services/widget_service.dart'; // Import WidgetService
import 'pages/prayertimes/prayertimes.dart'; // Import PrayerTimesPage

// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global theme mode controller for light/dark toggle
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

// Save theme mode to SharedPreferences
Future<void> saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme_mode', mode.toString());
  debugPrint('💾 Theme mode saved: $mode');
}

// Load theme mode from SharedPreferences
Future<ThemeMode> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final savedMode = prefs.getString('theme_mode');

  if (savedMode == 'ThemeMode.dark') {
    debugPrint('🌙 Loaded dark mode from preferences');
    return ThemeMode.dark;
  } else if (savedMode == 'ThemeMode.system') {
    debugPrint('🔄 Loaded system mode from preferences');
    return ThemeMode.system;
  } else {
    debugPrint('☀️ Loaded light mode from preferences (default)');
    return ThemeMode.light;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this
  WebViewPlatform.instance; // Add this

  // Load saved theme mode
  final savedThemeMode = await loadThemeMode();
  appThemeMode.value = savedThemeMode;

  // Set up notification tap handler before initializing
  NotificationService.onNotificationTapped = () {
    debugPrint('🔔 Notification tapped - navigating to Prayer Times page');
    // Use a delay to ensure the app UI is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PrayerTimesPage()),
        );
      } else {
        debugPrint('⚠️ Navigator context not available yet');
      }
    });
  };

  // Initialize notification service on app startup
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    debugPrint('✅ Notification service initialized in main()');
  } catch (e) {
    debugPrint('⚠️ Error initializing notification service in main(): $e');
  }

  // Initialize widget service
  try {
    await WidgetService.initialize();
    debugPrint('✅ Widget service initialized in main()');
  } catch (e) {
    debugPrint('⚠️ Error initializing widget service in main(): $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey, // Add global navigator key
          title: 'Waqafer',
          themeMode: mode,
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
            fontFamily: 'Inter',
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F766E), // Darker Teal
              secondary: Color(0xFFF59E42), // Orange
              background: Color(0xFFF8FAFC), // Light Gray
              surface: Color(0xFFF1F5F9), // Soft Gray
              onPrimary: Color(0xFFFFFFFF),
              onSecondary: Color(0xFFFFFFFF),
              onBackground: Color(0xFF1E293B),
              onSurface: Color(0xFF1E293B),
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF8FAFC),
              foregroundColor: Color(0xFF14B8A6),
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF14B8A6)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            fontFamily: 'Inter',
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0F766E), // Darker Teal
              secondary: Color(0xFFF59E42), // Orange
              background: Color(0xFF1E293B), // Dark Gray
              surface: Color(0xFF334155), // Medium dark gray
              onPrimary: Color(0xFFFFFFFF),
              onSecondary: Color(0xFFFFFFFF),
              onBackground: Color(0xFFF8FAFC),
              onSurface: Color(0xFFF8FAFC),
            ),
            scaffoldBackgroundColor: const Color(0xFF1E293B),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              foregroundColor: Color(0xFFF59E42),
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFFF59E42)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(), // Direct to SplashScreen on app start
        );
      },
    );
  }
}

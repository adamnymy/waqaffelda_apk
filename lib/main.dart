import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  print('💾 Theme mode saved: $mode');
}

// Load theme mode from SharedPreferences
Future<ThemeMode> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final savedMode = prefs.getString('theme_mode');

  if (savedMode == 'ThemeMode.dark') {
    print('🌙 Loaded dark mode from preferences');
    return ThemeMode.dark;
  } else if (savedMode == 'ThemeMode.system') {
    print('🔄 Loaded system mode from preferences');
    return ThemeMode.system;
  } else {
    print('☀️ Loaded light mode from preferences (default)');
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
    print('🔔 Notification tapped - navigating to Prayer Times page');
    // Use a delay to ensure the app UI is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PrayerTimesPage()),
        );
      } else {
        print('⚠️ Navigator context not available yet');
      }
    });
  };

  // Initialize notification service on app startup
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('✅ Notification service initialized in main()');
  } catch (e) {
    print('⚠️ Error initializing notification service in main(): $e');
  }

  // Initialize widget service
  try {
    await WidgetService.initialize();
    await WidgetService.registerCallbacks();
    print('✅ Widget service initialized in main()');
  } catch (e) {
    print('⚠️ Error initializing widget service in main(): $e');
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
              primary: Color(0xFF0284C7), // Deep ocean blue
              secondary: Color(0xFF38BDF8), // Sky blue
              background: Color(0xFFFFFFFF), // White background
              surface: Color(0xFFF0F9FF), // Ice blue tint
              onPrimary: Color(0xFFFFFFFF), // White text on primary
              onSecondary: Color(0xFFFFFFFF), // White text on secondary
              onBackground: Color(0xFF0F172A), // Dark text
              onSurface: Color(0xFF0F172A), // Dark text
            ),
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFFFFFF),
              foregroundColor: Color(0xFF0284C7),
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF0284C7)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7), // Deep ocean CTAs
                foregroundColor: const Color(
                  0xFFFFFFFF,
                ), // White text on primary
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
              primary: Color(0xFF0EA5E9), // Electric blue
              secondary: Color(0xFF7DD3FC), // Soft sky blue
              background: Color(0xFF111827), // Dark gray
              surface: Color(0xFF1F2937), // Medium dark gray
              onPrimary: Color(0xFF111827),
              onSecondary: Color(0xFFFFFFFF),
              onBackground: Color(0xFFF9FAFB),
              onSurface: Color(0xFFF9FAFB),
            ),
            scaffoldBackgroundColor: const Color(0xFF111827),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF111827),
              foregroundColor: Color(0xFF0EA5E9),
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF0EA5E9)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
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

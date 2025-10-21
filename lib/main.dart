import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'splash_screen.dart'; // Import SplashScreen

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Add this
  WebViewPlatform.instance; // Add this
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waqaf FELDA',
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Direct to SplashScreen on app start
    );
  }
}



import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class WidgetService {
  static const String widgetName = 'PrayerTimesWidgetProvider';

  /// Initialize widget service
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('group.waqafer');
      print('✅ Widget service initialized');
    } catch (e) {
      print('❌ Error initializing widget: $e');
    }
  }

  /// Update widget with current prayer times
  static Future<void> updateWidget() async {
    try {
      print('🔄 Updating home screen widget...');

      // Get cached prayer times
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_prayer_times');
      final locationName =
          prefs.getString('current_location_name') ?? 'Malaysia';

      if (cachedData == null) {
        print('⚠️ No cached prayer times for widget');
        await _setEmptyWidget();
        return;
      }

      final List<dynamic> prayerTimes = jsonDecode(cachedData);
      if (prayerTimes.isEmpty) {
        await _setEmptyWidget();
        return;
      }

      // Find next prayer
      final now = DateTime.now();
      Map<String, dynamic>? nextPrayer;
      String? nextPrayerTime;
      DateTime? nextPrayerDateTime;

      for (var prayer in prayerTimes) {
        final prayerName = prayer['name'] as String;
        if (prayerName == 'Syuruk') continue; // Skip Syuruk

        final timeStr = prayer['time'] as String;
        final prayerTime = _parseTimeString(timeStr);

        if (prayerTime != null && prayerTime.isAfter(now)) {
          nextPrayer = prayer;
          nextPrayerTime = timeStr;
          nextPrayerDateTime = prayerTime;
          break;
        }
      }

      // If no next prayer today, use first prayer (Subuh) for tomorrow
      if (nextPrayer == null && prayerTimes.isNotEmpty) {
        nextPrayer = prayerTimes.first;
        nextPrayerTime = prayerTimes.first['time'] as String;
      }

      // Calculate countdown
      String countdown = '';
      if (nextPrayerDateTime != null) {
        final difference = nextPrayerDateTime.difference(now);
        final hours = difference.inHours;
        final minutes = difference.inMinutes % 60;
        countdown = 'dalam ${hours}j ${minutes}m';
      }

      // Prepare widget data with correct keys (using underscores)
      await HomeWidget.saveWidgetData('location', locationName);
      await HomeWidget.saveWidgetData(
        'next_prayer_name',
        nextPrayer?['name'] ?? 'Subuh',
      );
      await HomeWidget.saveWidgetData(
        'next_prayer_time',
        nextPrayerTime ?? '--:--',
      );
      await HomeWidget.saveWidgetData('countdown', countdown);

      print('📊 Widget data saved:');
      print('  - location: $locationName');
      print('  - next_prayer_name: ${nextPrayer?['name']}');
      print('  - next_prayer_time: $nextPrayerTime');
      print('  - countdown: $countdown');

      // Add individual prayer times by name
      for (var prayer in prayerTimes) {
        final prayerName = prayer['name'] as String;
        final prayerTime = prayer['time'] as String;

        // Save with lowercase key matching Android expectations
        await HomeWidget.saveWidgetData(
          '${prayerName.toLowerCase()}_time',
          prayerTime,
        );
        print('  - ${prayerName.toLowerCase()}_time: $prayerTime');
      }

      // Update widget
      await HomeWidget.updateWidget(
        androidName: widgetName,
        iOSName: widgetName,
      );

      print('✅ Widget updated successfully');
    } catch (e) {
      print('❌ Error updating widget: $e');
    }
  }

  /// Set empty/loading widget state
  static Future<void> _setEmptyWidget() async {
    await HomeWidget.saveWidgetData('location', 'Memuatkan...');
    await HomeWidget.saveWidgetData('next_prayer_name', 'Memuat');
    await HomeWidget.saveWidgetData('next_prayer_time', '--:--');
    await HomeWidget.saveWidgetData('countdown', '');
    await HomeWidget.updateWidget(androidName: widgetName, iOSName: widgetName);
  }

  /// Parse time string (HH:MM or HH:MM AM/PM)
  static DateTime? _parseTimeString(String timeStr) {
    try {
      final now = DateTime.now();
      timeStr = timeStr.trim();

      // Try 12-hour format first (HH:MM AM/PM)
      if (timeStr.contains('AM') || timeStr.contains('PM')) {
        final parts = timeStr.split(' ');
        if (parts.length == 2) {
          final timePart = parts[0];
          final period = parts[1].toUpperCase();
          final timeComponents = timePart.split(':');

          if (timeComponents.length == 2) {
            int hour = int.parse(timeComponents[0]);
            final minute = int.parse(timeComponents[1]);

            if (period == 'PM' && hour != 12) {
              hour += 12;
            } else if (period == 'AM' && hour == 12) {
              hour = 0;
            }

            return DateTime(now.year, now.month, now.day, hour, minute);
          }
        }
      } else {
        // 24-hour format (HH:MM)
        final timeComponents = timeStr.split(':');
        if (timeComponents.length == 2) {
          final hour = int.parse(timeComponents[0]);
          final minute = int.parse(timeComponents[1]);
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
      }

      return null;
    } catch (e) {
      print('❌ Error parsing time: $e');
      return null;
    }
  }

  /// Register widget update callback
  static Future<void> registerCallbacks() async {
    try {
      HomeWidget.widgetClicked.listen((Uri? uri) async {
        if (uri != null) {
          print('🔔 Widget clicked: $uri');
          // Handle widget click (open specific page)
        }
      });
    } catch (e) {
      print('❌ Error registering widget callbacks: $e');
    }
  }
}

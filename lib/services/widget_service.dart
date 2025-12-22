import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
class WidgetService {
  static const String widgetName = 'PrayerTimesWidgetProvider';

  /// Initialize widget service
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('group.waqafer');
      debugPrint('✅ Widget service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing widget: $e');
    }
  }

  /// Update widget with current prayer times
  static Future<void> updateWidget() async {
    try {
      debugPrint('🔄 Updating home screen widget...');

      // Get cached prayer times
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_prayer_times');
      final locationName =
          prefs.getString('current_location_name') ?? 'Malaysia';

      if (cachedData == null) {
        debugPrint('⚠️ No cached prayer times for widget');
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

        // Use time24 for accurate parsing, but display the 12-hour format
        final time24Str = prayer['time24'] as String?;
        final timeStr = prayer['time'] as String;

        // Parse using 24-hour format for accuracy
        final prayerTime =
            time24Str != null
                ? _parseTimeString(time24Str)
                : _parseTimeString(timeStr);

        if (prayerTime != null && prayerTime.isAfter(now)) {
          nextPrayer = prayer;
          nextPrayerTime = timeStr; // Display format
          nextPrayerDateTime = prayerTime;
          break;
        }
      }

      // If no next prayer today, use first prayer (Subuh) for tomorrow
      if (nextPrayer == null && prayerTimes.isNotEmpty) {
        final firstPrayer = prayerTimes.firstWhere(
          (p) => p['name'] != 'Syuruk',
          orElse: () => prayerTimes.first,
        );
        nextPrayer = firstPrayer;
        nextPrayerTime = firstPrayer['time'] as String;
        // Set datetime to tomorrow
        final time24Str = firstPrayer['time24'] as String?;
        final parsedTime =
            time24Str != null
                ? _parseTimeString(time24Str)
                : _parseTimeString(nextPrayerTime);
        if (parsedTime != null) {
          nextPrayerDateTime = parsedTime.add(const Duration(days: 1));
        }
      }

      // Calculate countdown
      String countdown = '';
      if (nextPrayerDateTime != null) {
        final difference = nextPrayerDateTime.difference(now);
        if (difference.inSeconds > 0) {
          final hours = difference.inHours;
          final minutes = difference.inMinutes % 60;
          countdown = 'dalam ${hours}j ${minutes}m';
        } else {
          countdown = 'sedang berlaku';
        }
      }

      // Prepare widget data with correct keys (using underscores)
      await HomeWidget.saveWidgetData('location', locationName);

      // Add today's date in Malay format (reuse existing 'now' variable)
      final malayMonths = [
        'Jan',
        'Feb',
        'Mac',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ogo',
        'Sep',
        'Okt',
        'Nov',
        'Dis',
      ];
      final dateString = '${now.day} ${malayMonths[now.month - 1]} ${now.year}';
      await HomeWidget.saveWidgetData('date', dateString);

      await HomeWidget.saveWidgetData(
        'next_prayer_name',
        nextPrayer?['name'] ?? 'Subuh',
      );
      await HomeWidget.saveWidgetData(
        'next_prayer_time',
        nextPrayerTime ?? '--:--',
      );
      await HomeWidget.saveWidgetData('countdown', countdown);

      debugPrint('📊 Widget data saved:');
      debugPrint('  - location: $locationName');
      debugPrint('  - next_prayer_name: ${nextPrayer?['name']}');
      debugPrint('  - next_prayer_time: $nextPrayerTime');
      debugPrint('  - countdown: $countdown');

      // Add individual prayer times by name
      for (var prayer in prayerTimes) {
        final prayerName = prayer['name'] as String;
        final prayerTime = prayer['time'] as String;

        // Save with lowercase key matching Android expectations
        await HomeWidget.saveWidgetData(
          '${prayerName.toLowerCase()}_time',
          prayerTime,
        );
        debugPrint('  - ${prayerName.toLowerCase()}_time: $prayerTime');
      }

      // Update widget
      await HomeWidget.updateWidget(
        androidName: widgetName,
        iOSName: widgetName,
      );

      debugPrint('✅ Widget updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating widget: $e');
    }
  }

  /// Set empty/loading widget state
  static Future<void> _setEmptyWidget() async {
    // Add today's date even in loading state
    final now = DateTime.now();
    final malayMonths = [
      'Jan',
      'Feb',
      'Mac',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ogo',
      'Sep',
      'Okt',
      'Nov',
      'Dis',
    ];
    final dateString = '${now.day} ${malayMonths[now.month - 1]} ${now.year}';

    await HomeWidget.saveWidgetData('location', 'Memuatkan...');
    await HomeWidget.saveWidgetData('date', dateString);
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
      debugPrint('❌ Error parsing time: $e');
      return null;
    }
  }

  /// Force refresh widget by updating data and then triggering widget update
  static Future<void> forceRefreshWidget() async {
    try {
      debugPrint('🔄 Force refreshing widget...');

      // Update the data first
      await updateWidget();

      // Add a small delay to ensure data is saved
      await Future.delayed(const Duration(milliseconds: 100));

      // Trigger widget update again to ensure it picks up the new data
      await HomeWidget.updateWidget(
        androidName: widgetName,
        iOSName: widgetName,
      );

      debugPrint('✅ Widget force refreshed');
    } catch (e) {
      debugPrint('❌ Error force refreshing widget: $e');
    }
  }
}

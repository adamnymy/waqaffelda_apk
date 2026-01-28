import 'package:flutter/material.dart';

class PrayerHelpers {
  /// Get prayer color based on prayer name
  static Color getPrayerColor(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
      case 'fajr':
        return const Color(0xFF9C27B0); // Purple
      case 'syuruk':
      case 'sunrise':
        return const Color(0xFFFF6F00); // Orange
      case 'zohor':
      case 'dhuhr':
        return const Color(0xFFFFC107); // Golden
      case 'asar':
      case 'asr':
        return const Color(0xFFFF9800); // Amber
      case 'maghrib':
        return const Color(0xFFE91E63); // Pink
      case 'isyak':
      case 'isha':
        return const Color(0xFF3F51B5); // Indigo
      default:
        return const Color(0xFF00897B);
    }
  }

  /// Get prayer icon based on prayer name
  static IconData getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
      case 'fajr':
        return Icons.wb_twilight;
      case 'syuruk':
      case 'sunrise':
        return Icons.wb_sunny;
      case 'zohor':
      case 'dhuhr':
        return Icons.wb_cloudy;
      case 'asar':
      case 'asr':
        return Icons.wb_sunny;
      case 'maghrib':
        return Icons.brightness_3;
      case 'isyak':
      case 'isha':
        return Icons.brightness_2;
      default:
        return Icons.access_time;
    }
  }

  /// Check if prayer time has passed
  static bool isPrayerPassed(Map<String, dynamic> prayer) {
    try {
      final timeStr = prayer['time24'] ?? prayer['time'] ?? '';
      if (timeStr.isEmpty) return false;

      final parts = timeStr.split(':');
      if (parts.length < 2) return false;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = DateTime.now();
      final prayerTime =
          DateTime(now.year, now.month, now.day, hour, minute);

      return now.isAfter(prayerTime);
    } catch (e) {
      return false;
    }
  }

  /// Format duration to HH:MM:SS format
  static String formatDuration(Duration d) {
    final hours = d.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours >= 24) {
      final days = d.inDays;
      return '${days}d ${hours}:${minutes}:${seconds}';
    }
    return '$hours:$minutes:$seconds';
  }

  /// Get card colors based on index
  static Map<String, Color> getCardColors(int index) {
    const colors = [
      {
        'primary': Color(0xFFFBC02D),
        'gradient1': Color(0xFFFDD835),
        'gradient2': Color(0xFFFBC02D),
      },
      {
        'primary': Color(0xFF9C27B0),
        'gradient1': Color(0xFFAB47BC),
        'gradient2': Color(0xFF8E24AA),
      },
      {
        'primary': Color(0xFF00897B),
        'gradient1': Color(0xFF00BCD4),
        'gradient2': Color(0xFF00897B),
      },
      {
        'primary': Color(0xFFFF5722),
        'gradient1': Color(0xFFFF6F00),
        'gradient2': Color(0xFFFF5722),
      },
      {
        'primary': Color(0xFF2196F3),
        'gradient1': Color(0xFF42A5F5),
        'gradient2': Color(0xFF1976D2),
      },
    ];

    if (index < 0 || index >= colors.length) {
      return {
        'primary': const Color(0xFFFBC02D),
        'gradient1': const Color(0xFFFDD835),
        'gradient2': const Color(0xFFFBC02D),
      };
    }

    return Map<String, Color>.from(colors[index]);
  }

  /// Get current Gregorian date string in Malay
  static String getCurrentDateString() {
    final now = DateTime.now();
    const months = [
      'Januari',
      'Februari',
      'Mac',
      'April',
      'Mei',
      'Jun',
      'Julai',
      'Ogos',
      'September',
      'Oktober',
      'November',
      'Disember',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  /// Parse prayer name and time from prayer text
  static Map<String, String> parsePrayerText(String prayerText) {
    String nextPrayerName = '';
    String nextPrayerTime = '';

    if (prayerText.contains(':') &&
        prayerText != 'Loading...' &&
        prayerText != 'Tidak dapat memuatkan waktu solat') {
      final cleaned = prayerText.replaceAll('Solat Seterusnya: ', '');
      final parts = cleaned.split(' - ');
      if (parts.length == 2) {
        nextPrayerName = parts[0].trim();
        nextPrayerTime = parts[1].trim();
      }
    }

    return {
      'name': nextPrayerName,
      'time': nextPrayerTime,
    };
  }
}

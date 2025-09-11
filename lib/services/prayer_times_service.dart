import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class PrayerTimesService {
  static const String _baseUrl = 'http://api.aladhan.com/v1';
  
  // Malaysia-specific prayer times with JAKIM method
  static Future<Map<String, dynamic>?> getPrayerTimesForMalaysia(
    double latitude, 
    double longitude
  ) async {
    try {
      final date = DateFormat('dd-MM-yyyy').format(DateTime.now());
      // Using method 11 (Majlis Ugama Islam Singapura, Brunei, Indonesia, Malaysia)
      // with Hanafi school and Malaysia-specific adjustments
      final url = '$_baseUrl/timings/$date?latitude=$latitude&longitude=$longitude&method=11&school=1&tune=0,0,0,0,0,0,0,0,0';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('Failed to load Malaysia prayer times: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching Malaysia prayer times: $e');
      return null;
    }
  }
  
  // Get prayer times by coordinates
  static Future<Map<String, dynamic>?> getPrayerTimesByCoordinates(
    double latitude, 
    double longitude
  ) async {
    try {
      final date = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final url = '$_baseUrl/timings/$date?latitude=$latitude&longitude=$longitude&method=11&school=1';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('Failed to load prayer times: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching prayer times: $e');
      return null;
    }
  }
  
  // Get prayer times by city
  static Future<Map<String, dynamic>?> getPrayerTimesByCity(String city) async {
    try {
      final date = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final url = '$_baseUrl/timingsByCity/$date?city=$city&country=Malaysia&method=11&school=1';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
    } catch (e) {
      print('Error fetching prayer times by city: $e');
    }
    return null;
  }
  
  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
  
  // Parse prayer times from API response
  static List<Map<String, dynamic>> parsePrayerTimes(Map<String, dynamic> apiData) {
    final timings = apiData['data']['timings'];
    
    return [
      {
        'name': 'Fajr',
        'arabic': 'الفجر',
        'time': _formatTime(timings['Fajr']),
        'icon': 'wb_twilight',
        'color': 0xFF4A90E2,
        'isPassed': _isPrayerPassed(timings['Fajr']),
      },
      {
        'name': 'Dhuhr',
        'arabic': 'الظهر',
        'time': _formatTime(timings['Dhuhr']),
        'icon': 'wb_sunny',
        'color': 0xFFF5A623,
        'isPassed': _isPrayerPassed(timings['Dhuhr']),
      },
      {
        'name': 'Asr',
        'arabic': 'العصر',
        'time': _formatTime(timings['Asr']),
        'icon': 'wb_cloudy',
        'color': 0xFFFF9500,
        'isPassed': _isPrayerPassed(timings['Asr']),
      },
      {
        'name': 'Maghrib',
        'arabic': 'المغرب',
        'time': _formatTime(timings['Maghrib']),
        'icon': 'brightness_3',
        'color': 0xFFE94B3C,
        'isPassed': _isPrayerPassed(timings['Maghrib']),
      },
      {
        'name': 'Isha',
        'arabic': 'العشاء',
        'time': _formatTime(timings['Isha']),
        'icon': 'brightness_2',
        'color': 0xFF7B68EE,
        'isPassed': _isPrayerPassed(timings['Isha']),
      },
    ];
  }
  
  // Format time from 24-hour to 12-hour format
  static String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      
      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      return time24;
    }
  }
  
  // Check if prayer time has passed
  static bool _isPrayerPassed(String prayerTime) {
    try {
      final now = DateTime.now();
      final parts = prayerTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final prayerDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      return now.isAfter(prayerDateTime);
    } catch (e) {
      return false;
    }
  }
  
  // Get next prayer info
  static Map<String, String>? getNextPrayer(List<Map<String, dynamic>> prayers) {
    for (var prayer in prayers) {
      if (!prayer['isPassed']) {
        return {
          'name': prayer['name'],
          'time': prayer['time'],
        };
      }
    }
    // If all prayers have passed, next prayer is Fajr of tomorrow
    return {
      'name': 'Fajr',
      'time': 'Tomorrow',
    };
  }
  
  // Get location name from coordinates (reverse geocoding)
  static Future<String> getLocationName(double latitude, double longitude) async {
    try {
      // Using a simple approach - you can enhance this with a proper geocoding service
      return 'Current Location';
    } catch (e) {
      return 'Unknown Location';
    }
  }
}

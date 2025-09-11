import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class PrayerTimesService {
  static const String _baseUrl = 'https://waktu-solat-api.herokuapp.com/api/v1';
  
  // Get prayer times using JAKIM official data
  static Future<Map<String, dynamic>?> getPrayerTimesForMalaysia(
    double latitude, 
    double longitude
  ) async {
    try {
      // Get the closest Malaysian zone for coordinates
      String zoneCode = _getZoneFromCoordinates(latitude, longitude);
      return await getPrayerTimesByZone(zoneCode);
    } catch (e) {
      print('Error fetching prayer times: $e');
      return null;
    }
  }
  
  // Get prayer times by Malaysian zone (JAKIM official data)
  static Future<Map<String, dynamic>?> getPrayerTimesByZone(String zoneName) async {
    try {
      final url = '$_baseUrl/prayer_times.json?zon=$zoneName';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _formatJakimResponse(data);
      } else {
        print('Failed to load JAKIM prayer times: ${response.statusCode}');
        print('URL attempted: $url');
        return null;
      }
    } catch (e) {
      print('Error fetching JAKIM prayer times: $e');
      return null;
    }
  }

  // Map coordinates to Malaysian prayer zone names (for JAKIM API)
  static String _getZoneFromCoordinates(double latitude, double longitude) {
    // Major Malaysian cities and their zone names (as used by JAKIM API)
    final zones = {
      // Kuala Lumpur & Selangor
      'kuala lumpur': {'lat': 3.1390, 'lng': 101.6869},
      'sepang': {'lat': 3.0738, 'lng': 101.5183},
      'shah alam': {'lat': 3.0738, 'lng': 101.5183},
      
      // Johor
      'johor bahru': {'lat': 1.4927, 'lng': 103.7414},
      'kluang': {'lat': 2.0581, 'lng': 102.5689},
      
      // Penang
      'pulau pinang': {'lat': 5.4164, 'lng': 100.3327},
      
      // Perak
      'ipoh': {'lat': 4.5975, 'lng': 101.0901},
      
      // Kedah
      'alor setar': {'lat': 6.1184, 'lng': 100.3685},
      
      // Kelantan
      'kota bharu': {'lat': 6.1254, 'lng': 102.2386},
      
      // Terengganu
      'kuala terengganu': {'lat': 5.3302, 'lng': 103.1408},
      
      // Pahang
      'kuantan': {'lat': 3.8077, 'lng': 103.3260},
      
      // Negeri Sembilan
      'seremban': {'lat': 2.7297, 'lng': 101.9381},
      
      // Melaka
      'melaka': {'lat': 2.1896, 'lng': 102.2501},
      
      // Sabah
      'kota kinabalu': {'lat': 5.9804, 'lng': 116.0735},
      
      // Sarawak
      'kuching': {'lat': 1.5533, 'lng': 110.3592},
    };

    String closestZone = 'kuala lumpur'; // Default to KL
    double minDistance = double.infinity;

    zones.forEach((zoneName, zoneData) {
      double distance = _calculateDistance(
        latitude, longitude,
        zoneData['lat'] as double, zoneData['lng'] as double
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestZone = zoneName;
      }
    });

    return closestZone;
  }

  // Calculate distance between two coordinates
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  // Format JAKIM API response to match expected format
  static Map<String, dynamic> _formatJakimResponse(Map<String, dynamic> data) {
    try {
      if (data['data'] != null && data['data'].isNotEmpty) {
        // Handle the nested structure from JAKIM API
        var prayerData;
        
        if (data['data'] is List) {
          // Format: {"data": [{"negeri": "...", "zon": "...", "waktu_solat": [...]}]}
          prayerData = data['data'][0];
          if (prayerData['waktu_solat'] != null) {
            final waktuSolat = prayerData['waktu_solat'] as List;
            final timings = <String, String>{};
            
            for (var prayer in waktuSolat) {
              final name = prayer['name'] as String;
              final time = prayer['time'] as String;
              
              switch (name.toLowerCase()) {
                case 'subuh':
                  timings['Fajr'] = time;
                  break;
                case 'syuruk':
                  timings['Sunrise'] = time;
                  break;
                case 'zohor':
                  timings['Dhuhr'] = time;
                  break;
                case 'asar':
                  timings['Asr'] = time;
                  break;
                case 'maghrib':
                  timings['Maghrib'] = time;
                  break;
                case 'isyak':
                  timings['Isha'] = time;
                  break;
              }
            }
            
            return {
              'code': 200,
              'status': 'OK',
              'data': {
                'timings': timings,
                'date': {
                  'readable': DateTime.now().toString().split(' ')[0],
                  'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                },
                'meta': {
                  'latitude': 0.0,
                  'longitude': 0.0,
                  'timezone': 'Asia/Kuala_Lumpur',
                  'method': {
                    'id': 11,
                    'name': 'JAKIM Malaysia',
                  },
                },
              },
            };
          }
        }
      }
    } catch (e) {
      print('Error formatting JAKIM response: $e');
    }
    return {'code': 400, 'status': 'No data available'};
  }

  // Get prayer times by coordinates (uses JAKIM zone mapping)
  static Future<Map<String, dynamic>?> getPrayerTimesByCoordinates(
    double latitude, 
    double longitude
  ) async {
    return await getPrayerTimesForMalaysia(latitude, longitude);
  }
  
  // Get prayer times by city (using JAKIM zone mapping)
  static Future<Map<String, dynamic>?> getPrayerTimesByCity(String city) async {
    try {
      // Map city names to coordinates for zone lookup
      final cityCoordinates = {
        'Kuala Lumpur': {'lat': 3.1390, 'lng': 101.6869},
        'Selangor': {'lat': 3.0738, 'lng': 101.5183},
        'Johor Bahru': {'lat': 1.4927, 'lng': 103.7414},
        'Penang': {'lat': 5.4164, 'lng': 100.3327},
        'Ipoh': {'lat': 4.5975, 'lng': 101.0901},
        'Alor Setar': {'lat': 6.1184, 'lng': 100.3685},
        'Kota Bharu': {'lat': 6.1254, 'lng': 102.2386},
        'Kuala Terengganu': {'lat': 5.3302, 'lng': 103.1408},
        'Kuantan': {'lat': 3.8077, 'lng': 103.3260},
        'Seremban': {'lat': 2.7297, 'lng': 101.9381},
        'Melaka': {'lat': 2.1896, 'lng': 102.2501},
        'Kota Kinabalu': {'lat': 5.9804, 'lng': 116.0735},
        'Kuching': {'lat': 1.5533, 'lng': 110.3592},
      };
      
      final coords = cityCoordinates[city];
      if (coords != null) {
        return await getPrayerTimesForMalaysia(coords['lat']!, coords['lng']!);
      }
      
      // Fallback to KL if city not found
      return await getPrayerTimesForMalaysia(3.1390, 101.6869);
    } catch (e) {
      print('Error fetching prayer times by city: $e');
      return null;
    }
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
        'color': 0xFFFFB74D,
        'isPassed': _isPrayerPassed(timings['Dhuhr']),
      },
      {
        'name': 'Asr',
        'arabic': 'العصر',
        'time': _formatTime(timings['Asr']),
        'icon': 'wb_cloudy',
        'color': 0xFFFF8A65,
        'isPassed': _isPrayerPassed(timings['Asr']),
      },
      {
        'name': 'Maghrib',
        'arabic': 'المغرب',
        'time': _formatTime(timings['Maghrib']),
        'icon': 'brightness_3',
        'color': 0xFF9575CD,
        'isPassed': _isPrayerPassed(timings['Maghrib']),
      },
      {
        'name': 'Isha',
        'arabic': 'العشاء',
        'time': _formatTime(timings['Isha']),
        'icon': 'brightness_2',
        'color': 0xFF7986CB,
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

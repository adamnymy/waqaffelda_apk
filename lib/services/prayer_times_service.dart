import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PrayerTimesService {
  // Get prayer times using e-solat.gov.my official data
  static Future<Map<String, dynamic>?> getPrayerTimesForMalaysia(
    double latitude,
    double longitude,
  ) async {
    try {
      // Get the closest Malaysian zone for coordinates
      String zoneCode = _getZoneFromCoordinates(latitude, longitude);
      final result = await getPrayerTimesByZone(zoneCode);

      // Add the location name based on the zone
      if (result != null &&
          result['data'] != null &&
          result['data']['meta'] != null) {
        result['data']['meta']['locationName'] = _getLocationNameFromZone(
          zoneCode,
        );
      }

      return result;
    } catch (e) {
      print('Error fetching prayer times: $e');
      return null;
    }
  }

  // Get prayer times by Malaysian zone (e-solat.gov.my official data)
  static Future<Map<String, dynamic>?> getPrayerTimesByZone(
    String zoneName,
  ) async {
    try {
      final url =
          'https://www.e-solat.gov.my/index.php?r=esolatApi/TakwimSolat&period=today&zone=$zoneName';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _formatEsolatResponse(data, zoneName);
      } else {
        print('Failed to load e-solat prayer times: ${response.statusCode}');
        print('URL attempted: $url');
        return null;
      }
    } catch (e) {
      print('Error fetching e-solat prayer times: $e');
      return null;
    }
  }

  // Map coordinates to Malaysian prayer zone codes (for e-solat.gov.my API)
  static String _getZoneFromCoordinates(double latitude, double longitude) {
    // Major Malaysian cities and their zone codes (as used by e-solat.gov.my API)
    final zones = {
      // Wilayah Persekutuan
      'WLY01': {'lat': 3.1390, 'lng': 101.6869},

      // Selangor
      'SGR01': {'lat': 3.0738, 'lng': 101.5183},

      // Johor
      'JHR01': {'lat': 1.4927, 'lng': 103.7414},
      'JHR02': {'lat': 2.0581, 'lng': 102.5689},

      // Penang
      'PNG01': {'lat': 5.4164, 'lng': 100.3327},

      // Perak
      'PRK01': {'lat': 4.5975, 'lng': 101.0901},

      // Kedah
      'KDH01': {'lat': 6.1184, 'lng': 100.3685},

      // Kelantan
      'KTN01': {'lat': 6.1254, 'lng': 102.2386},

      // Terengganu
      'TRG01': {'lat': 5.3302, 'lng': 103.1408},

      // Pahang
      'PHG01': {'lat': 3.8077, 'lng': 103.3260},

      // Negeri Sembilan
      'NSN01': {'lat': 2.7297, 'lng': 101.9381},

      // Melaka
      'MLK01': {'lat': 2.1896, 'lng': 102.2501},

      // Sabah
      'SBH01': {'lat': 5.9804, 'lng': 116.0735},

      // Sarawak
      'SWK01': {'lat': 1.5533, 'lng': 110.3592},
    };

    String closestZone = 'WLY01'; // Default to Kuala Lumpur
    double minDistance = double.infinity;

    zones.forEach((zoneCode, zoneData) {
      double distance = _calculateDistance(
        latitude,
        longitude,
        zoneData['lat'] as double,
        zoneData['lng'] as double,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestZone = zoneCode;
      }
    });

    return closestZone;
  }

  // Get display name from zone code
  static String _getLocationNameFromZone(String zoneCode) {
    final zoneDisplayNames = {
      'WLY01': 'Wilayah Persekutuan',
      'SGR01': 'Selangor',
      'JHR01': 'Johor',
      'JHR02': 'Johor',
      'PNG01': 'Pulau Pinang',
      'PRK01': 'Perak',
      'KDH01': 'Kedah',
      'KTN01': 'Kelantan',
      'TRG01': 'Terengganu',
      'PHG01': 'Pahang',
      'NSN01': 'Negeri Sembilan',
      'MLK01': 'Melaka',
      'SBH01': 'Sabah',
      'SWK01': 'Sarawak',
    };

    return zoneDisplayNames[zoneCode.toUpperCase()] ??
        zoneCode
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
  }

  // Calculate distance between two coordinates
  static double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  // Format e-solat.gov.my API response to match expected format
  static Map<String, dynamic> _formatEsolatResponse(
    Map<String, dynamic> data,
    String zoneCode,
  ) {
    try {
      if (data['prayerTime'] != null && data['prayerTime'].isNotEmpty) {
        final prayerData = data['prayerTime'][0] as Map<String, dynamic>;
        final timings = <String, String>{};

        timings['Fajr'] = prayerData['fajr'] ?? '';
        timings['Sunrise'] = prayerData['syuruk'] ?? '';
        timings['Dhuhr'] = prayerData['dhuhr'] ?? '';
        timings['Asr'] = prayerData['asr'] ?? '';
        timings['Maghrib'] = prayerData['maghrib'] ?? '';
        timings['Isha'] = prayerData['isha'] ?? '';

        // Extract date
        final dateStr =
            prayerData['date'] ?? DateTime.now().toString().split(' ')[0];

        // Get location name from zone code
        final locationName = _getLocationNameFromZone(zoneCode);

        return {
          'code': 200,
          'status': 'OK',
          'data': {
            'timings': timings,
            'date': {
              'readable': dateStr,
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            },
            'meta': {
              'latitude': 0.0,
              'longitude': 0.0,
              'timezone': 'Asia/Kuala_Lumpur',
              'method': {'id': 11, 'name': 'JAKIM Malaysia'},
              'locationName': locationName,
            },
          },
        };
      }
    } catch (e) {
      print('Error formatting e-solat response: $e');
    }
    return {'code': 400, 'status': 'No data available'};
  }

  // Get prayer times by coordinates (uses e-solat.gov.my zone mapping)
  static Future<Map<String, dynamic>?> getPrayerTimesByCoordinates(
    double latitude,
    double longitude,
  ) async {
    return await getPrayerTimesForMalaysia(latitude, longitude);
  }

  // Get prayer times by city (using e-solat.gov.my zone mapping)
  static Future<Map<String, dynamic>?> getPrayerTimesByCity(String city) async {
    try {
      // Map city names to zone codes for e-solat.gov.my API
      final cityCoordinates = {
        'Wilayah Persekutuan': 'WLY01',
        'Selangor': 'SGR01',
        'Johor': 'JHR01',
        'Pulau Pinang': 'PNG01',
        'Perak': 'PRK01',
        'Kedah': 'KDH01',
        'Kelantan': 'KTN01',
        'Terengganu': 'TRG01',
        'Pahang': 'PHG01',
        'Negeri Sembilan': 'NSN01',
        'Melaka': 'MLK01',
        'Sabah': 'SBH01',
        'Sarawak': 'SWK01',
      };

      final zoneCode = cityCoordinates[city];
      if (zoneCode != null) {
        return await getPrayerTimesByZone(zoneCode);
      }

      // Fallback to Kuala Lumpur if city not found
      return await getPrayerTimesByZone('WLY01');
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
  static List<Map<String, dynamic>> parsePrayerTimes(
    Map<String, dynamic> apiData,
  ) {
    final timings = apiData['data']['timings'];

    return [
      {
        'name': 'Subuh',
        'arabic': 'الفجر',
        'time': _formatTime(timings['Fajr']),
        'icon': 'wb_twilight',
        'color': 0xFF4A90E2,
        'isPassed': _isPrayerPassed(timings['Fajr']),
      },
      {
        'name': 'Syuruk',
        'arabic': 'الشروق',
        'time': _formatTime(timings['Sunrise'] ?? '06:00'),
        'icon': 'wb_sunny',
        'color': 0xFFFFA726,
        'isPassed': _isPrayerPassed(timings['Sunrise'] ?? '06:00'),
      },
      {
        'name': 'Zohor',
        'arabic': 'الظهر',
        'time': _formatTime(timings['Dhuhr']),
        'icon': 'wb_sunny',
        'color': 0xFFFFB74D,
        'isPassed': _isPrayerPassed(timings['Dhuhr']),
      },
      {
        'name': 'Asar',
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
        'name': 'Isyak',
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

      final prayerDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      return now.isAfter(prayerDateTime);
    } catch (e) {
      return false;
    }
  }

  // Get next prayer info
  static Map<String, String>? getNextPrayer(
    List<Map<String, dynamic>> prayers,
  ) {
    for (var prayer in prayers) {
      // Skip Syuruk as it's not a prayer time
      if (prayer['name'] == 'Syuruk') continue;

      if (!prayer['isPassed']) {
        return {'name': prayer['name'], 'time': prayer['time']};
      }
    }
    // If all prayers have passed, next prayer is Subuh of tomorrow
    // Return the actual Subuh time instead of 'Esok'
    final subuhPrayer = prayers.firstWhere(
      (prayer) => prayer['name'] == 'Subuh',
      orElse: () => {'name': 'Subuh', 'time': '--:--'},
    );
    return {'name': 'Subuh', 'time': subuhPrayer['time']};
  }

  // Get location name from coordinates (reverse geocoding)
  static Future<String> getLocationName(
    double latitude,
    double longitude,
  ) async {
    try {
      // Use reverse geocoding to get the actual location name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 5), onTimeout: () => []);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Use the same approach as Kiblat page - simple null-coalescing
        final locationName =
            place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            place.country ??
            'Lokasi Semasa';

        print('Location from geocoding: $locationName');
        return locationName;
      }

      return 'Lokasi Semasa';
    } catch (e) {
      print('Error getting location name: $e');
      return 'Lokasi Semasa';
    }
  }
}

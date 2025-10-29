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

      // Don't override location name here - let the UI handle it separately
      // This allows for more accurate location names from geocoding

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
    // JAKIM e-solat zones with their representative coordinates
    final zones = {
      // Wilayah Persekutuan
      'WLY01': {
        'lat': 3.1390,
        'lng': 101.6869,
        'name': 'Kuala Lumpur',
      }, // KL & surrounding
      // Selangor
      'SGR01': {
        'lat': 3.0738,
        'lng': 101.5183,
        'name': 'Shah Alam',
      }, // Shah Alam, Klang
      'SGR02': {
        'lat': 2.9264,
        'lng': 101.6550,
        'name': 'Putrajaya',
      }, // Putrajaya, Cyberjaya
      'SGR03': {
        'lat': 3.2169,
        'lng': 101.7285,
        'name': 'Petaling Jaya',
      }, // PJ, Subang
      // Johor
      'JHR01': {
        'lat': 1.4927,
        'lng': 103.7414,
        'name': 'Johor Bahru',
      }, // JB North
      'JHR02': {
        'lat': 2.0581,
        'lng': 102.5689,
        'name': 'Batu Pahat',
      }, // JB South, Batu Pahat
      'JHR03': {
        'lat': 2.2008,
        'lng': 102.2501,
        'name': 'Kluang',
      }, // Kluang, Mersing
      'JHR04': {
        'lat': 1.8633,
        'lng': 103.1408,
        'name': 'Pontian',
      }, // Pontian, Tangkak
      // Penang
      'PNG01': {
        'lat': 5.4164,
        'lng': 100.3327,
        'name': 'Pulau Pinang',
      }, // Georgetown
      // Perak
      'PRK01': {
        'lat': 4.5975,
        'lng': 101.0901,
        'name': 'Ipoh',
      }, // Ipoh, Taiping
      'PRK02': {
        'lat': 5.4164,
        'lng': 100.3327,
        'name': 'Taiping',
      }, // Taiping, Larut
      'PRK03': {
        'lat': 3.8077,
        'lng': 101.0901,
        'name': 'Teluk Intan',
      }, // Teluk Intan
      'PRK04': {
        'lat': 4.1842,
        'lng': 100.6328,
        'name': 'Kuala Kangsar',
      }, // Kuala Kangsar
      'PRK05': {
        'lat': 5.3294,
        'lng': 100.2737,
        'name': 'Pulau Pinang',
      }, // Seberang Perai
      'PRK06': {
        'lat': 3.4927,
        'lng': 101.7414,
        'name': 'Selama',
      }, // Selama, Taiping
      'PRK07': {
        'lat': 4.7698,
        'lng': 100.9381,
        'name': 'Bagan Datuk',
      }, // Bagan Datuk
      // Kedah
      'KDH01': {
        'lat': 6.1184,
        'lng': 100.3685,
        'name': 'Alor Setar',
      }, // Alor Setar
      'KDH02': {
        'lat': 5.6921,
        'lng': 100.4917,
        'name': 'Sungai Petani',
      }, // Sungai Petani
      'KDH03': {
        'lat': 6.4414,
        'lng': 100.1986,
        'name': 'Kuala Muda',
      }, // Kuala Muda
      'KDH04': {
        'lat': 5.8947,
        'lng': 100.3685,
        'name': 'Kubang Pasu',
      }, // Kubang Pasu
      'KDH05': {
        'lat': 6.1254,
        'lng': 100.3685,
        'name': 'Pokok Sena',
      }, // Pokok Sena
      'KDH06': {
        'lat': 5.8077,
        'lng': 100.5381,
        'name': 'Padang Terap',
      }, // Padang Terap
      'KDH07': {'lat': 6.4414, 'lng': 100.5381, 'name': 'Langkawi'}, // Langkawi
      // Kelantan
      'KTN01': {
        'lat': 6.1254,
        'lng': 102.2386,
        'name': 'Kota Bharu',
      }, // Kota Bharu
      'KTN02': {'lat': 5.8947, 'lng': 102.2386, 'name': 'Tumpat'}, // Tumpat
      'KTN03': {
        'lat': 6.4414,
        'lng': 101.9381,
        'name': 'Pasir Mas',
      }, // Pasir Mas
      // Terengganu
      'TRG01': {
        'lat': 5.3302,
        'lng': 103.1408,
        'name': 'Kuala Terengganu',
      }, // Kuala Terengganu
      'TRG02': {'lat': 4.7698, 'lng': 103.1408, 'name': 'Besut'}, // Besut
      'TRG03': {'lat': 5.8077, 'lng': 102.5689, 'name': 'Setiu'}, // Setiu
      'TRG04': {'lat': 4.4927, 'lng': 103.3260, 'name': 'Marang'}, // Marang
      // Pahang
      'PHG01': {'lat': 3.8077, 'lng': 103.3260, 'name': 'Kuantan'}, // Kuantan
      'PHG02': {
        'lat': 3.7927,
        'lng': 101.8574,
        'name': 'Raub',
      }, // Raub, Bentong
      'PHG03': {'lat': 3.9414, 'lng': 102.3685, 'name': 'Jerantut'}, // Jerantut
      'PHG04': {'lat': 3.4927, 'lng': 102.3685, 'name': 'Temerloh'}, // Temerloh
      'PHG05': {'lat': 4.1842, 'lng': 101.9381, 'name': 'Rompin'}, // Rompin
      'PHG06': {'lat': 3.2169, 'lng': 101.7285, 'name': 'Maran'}, // Maran
      // Negeri Sembilan
      'NSN01': {'lat': 2.7297, 'lng': 101.9381, 'name': 'Seremban'}, // Seremban
      'NSN02': {
        'lat': 2.4927,
        'lng': 102.2501,
        'name': 'Port Dickson',
      }, // Port Dickson
      'NSN03': {'lat': 2.2008, 'lng': 102.2501, 'name': 'Jempol'}, // Jempol
      // Melaka
      'MLK01': {'lat': 2.1896, 'lng': 102.2501, 'name': 'Melaka'}, // Melaka
      // Sabah
      'SBH01': {
        'lat': 5.9804,
        'lng': 116.0735,
        'name': 'Kota Kinabalu',
      }, // Kota Kinabalu
      'SBH02': {'lat': 5.3294, 'lng': 115.2386, 'name': 'Beaufort'}, // Beaufort
      'SBH03': {'lat': 4.4927, 'lng': 118.1408, 'name': 'Kudat'}, // Kudat
      'SBH04': {'lat': 5.8077, 'lng': 116.7381, 'name': 'Sandakan'}, // Sandakan
      'SBH05': {
        'lat': 4.7698,
        'lng': 115.2386,
        'name': 'Lahad Datu',
      }, // Lahad Datu
      'SBH06': {'lat': 5.6921, 'lng': 117.0735, 'name': 'Tawau'}, // Tawau
      // Sarawak
      'SWK01': {'lat': 1.5533, 'lng': 110.3592, 'name': 'Kuching'}, // Kuching
      'SWK02': {
        'lat': 2.2008,
        'lng': 111.9381,
        'name': 'Samarahan',
      }, // Samarahan
      'SWK03': {'lat': 3.2169, 'lng': 113.3260, 'name': 'Sri Aman'}, // Sri Aman
      'SWK04': {'lat': 2.4927, 'lng': 112.9381, 'name': 'Betong'}, // Betong
      'SWK05': {'lat': 1.8633, 'lng': 111.9381, 'name': 'Sarikei'}, // Sarikei
      'SWK06': {'lat': 3.8077, 'lng': 114.3685, 'name': 'Kapit'}, // Kapit
      'SWK07': {'lat': 3.4927, 'lng': 115.7381, 'name': 'Bintulu'}, // Bintulu
      'SWK08': {'lat': 4.1842, 'lng': 114.9381, 'name': 'Miri'}, // Miri
      'SWK09': {'lat': 3.9414, 'lng': 113.7381, 'name': 'Limbang'}, // Limbang
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

    print(
      'Selected zone $closestZone (${zones[closestZone]!['name']}) for coordinates ($latitude, $longitude)',
    );
    return closestZone;
  }

  // Get display name from zone code
  static String _getLocationNameFromZone(String zoneCode) {
    final zoneDisplayNames = {
      // Wilayah Persekutuan
      'WLY01': 'Kuala Lumpur',

      // Selangor
      'SGR01': 'Shah Alam',
      'SGR02': 'Putrajaya',
      'SGR03': 'Petaling Jaya',

      // Johor
      'JHR01': 'Johor Bahru',
      'JHR02': 'Batu Pahat',
      'JHR03': 'Kluang',
      'JHR04': 'Pontian',

      // Penang
      'PNG01': 'Pulau Pinang',

      // Perak
      'PRK01': 'Ipoh',
      'PRK02': 'Taiping',
      'PRK03': 'Teluk Intan',
      'PRK04': 'Kuala Kangsar',
      'PRK05': 'Seberang Perai',
      'PRK06': 'Selama',
      'PRK07': 'Bagan Datuk',

      // Kedah
      'KDH01': 'Alor Setar',
      'KDH02': 'Sungai Petani',
      'KDH03': 'Kuala Muda',
      'KDH04': 'Kubang Pasu',
      'KDH05': 'Pokok Sena',
      'KDH06': 'Padang Terap',
      'KDH07': 'Langkawi',

      // Kelantan
      'KTN01': 'Kota Bharu',
      'KTN02': 'Tumpat',
      'KTN03': 'Pasir Mas',

      // Terengganu
      'TRG01': 'Kuala Terengganu',
      'TRG02': 'Besut',
      'TRG03': 'Setiu',
      'TRG04': 'Marang',

      // Pahang
      'PHG01': 'Kuantan',
      'PHG02': 'Raub',
      'PHG03': 'Jerantut',
      'PHG04': 'Temerloh',
      'PHG05': 'Rompin',
      'PHG06': 'Maran',

      // Negeri Sembilan
      'NSN01': 'Seremban',
      'NSN02': 'Port Dickson',
      'NSN03': 'Jempol',

      // Melaka
      'MLK01': 'Melaka',

      // Sabah
      'SBH01': 'Kota Kinabalu',
      'SBH02': 'Beaufort',
      'SBH03': 'Kudat',
      'SBH04': 'Sandakan',
      'SBH05': 'Lahad Datu',
      'SBH06': 'Tawau',

      // Sarawak
      'SWK01': 'Kuching',
      'SWK02': 'Samarahan',
      'SWK03': 'Sri Aman',
      'SWK04': 'Betong',
      'SWK05': 'Sarikei',
      'SWK06': 'Kapit',
      'SWK07': 'Bintulu',
      'SWK08': 'Miri',
      'SWK09': 'Limbang',
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
        'Kuala Lumpur': 'WLY01',
        'Shah Alam': 'SGR01',
        'Putrajaya': 'SGR02',
        'Cyberjaya': 'SGR02',
        'Petaling Jaya': 'SGR03',
        'Johor Bahru': 'JHR01',
        'Batu Pahat': 'JHR02',
        'Kluang': 'JHR03',
        'Pontian': 'JHR04',
        'Pulau Pinang': 'PNG01',
        'Ipoh': 'PRK01',
        'Taiping': 'PRK02',
        'Teluk Intan': 'PRK03',
        'Kuala Kangsar': 'PRK04',
        'Seberang Perai': 'PRK05',
        'Selama': 'PRK06',
        'Bagan Datuk': 'PRK07',
        'Alor Setar': 'KDH01',
        'Sungai Petani': 'KDH02',
        'Kuala Muda': 'KDH03',
        'Kubang Pasu': 'KDH04',
        'Pokok Sena': 'KDH05',
        'Padang Terap': 'KDH06',
        'Langkawi': 'KDH07',
        'Kota Bharu': 'KTN01',
        'Tumpat': 'KTN02',
        'Pasir Mas': 'KTN03',
        'Kuala Terengganu': 'TRG01',
        'Besut': 'TRG02',
        'Setiu': 'TRG03',
        'Marang': 'TRG04',
        'Kuantan': 'PHG01',
        'Raub': 'PHG02',
        'Jerantut': 'PHG03',
        'Temerloh': 'PHG04',
        'Rompin': 'PHG05',
        'Maran': 'PHG06',
        'Seremban': 'NSN01',
        'Port Dickson': 'NSN02',
        'Jempol': 'NSN03',
        'Melaka': 'MLK01',
        'Kota Kinabalu': 'SBH01',
        'Beaufort': 'SBH02',
        'Kudat': 'SBH03',
        'Sandakan': 'SBH04',
        'Lahad Datu': 'SBH05',
        'Tawau': 'SBH06',
        'Kuching': 'SWK01',
        'Samarahan': 'SWK02',
        'Sri Aman': 'SWK03',
        'Betong': 'SWK04',
        'Sarikei': 'SWK05',
        'Kapit': 'SWK06',
        'Bintulu': 'SWK07',
        'Miri': 'SWK08',
        'Limbang': 'SWK09',
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
        'time24': timings['Fajr'], // Add raw 24-hour time
        'icon': 'wb_twilight',
        'color': 0xFF4A90E2,
        'isPassed': _isPrayerPassed(timings['Fajr']),
      },
      {
        'name': 'Syuruk',
        'arabic': 'الشروق',
        'time': _formatTime(timings['Sunrise'] ?? '06:00'),
        'time24': timings['Sunrise'] ?? '06:00', // Add raw 24-hour time
        'icon': 'wb_sunny',
        'color': 0xFFFFA726,
        'isPassed': _isPrayerPassed(timings['Sunrise'] ?? '06:00'),
      },
      {
        'name': 'Zohor',
        'arabic': 'الظهر',
        'time': _formatTime(timings['Dhuhr']),
        'time24': timings['Dhuhr'], // Add raw 24-hour time
        'icon': 'wb_sunny',
        'color': 0xFFFFB74D,
        'isPassed': _isPrayerPassed(timings['Dhuhr']),
      },
      {
        'name': 'Asar',
        'arabic': 'العصر',
        'time': _formatTime(timings['Asr']),
        'time24': timings['Asr'], // Add raw 24-hour time
        'icon': 'wb_cloudy',
        'color': 0xFFFF8A65,
        'isPassed': _isPrayerPassed(timings['Asr']),
      },
      {
        'name': 'Maghrib',
        'arabic': 'المغرب',
        'time': _formatTime(timings['Maghrib']),
        'time24': timings['Maghrib'], // Add raw 24-hour time
        'icon': 'brightness_3',
        'color': 0xFF9575CD,
        'isPassed': _isPrayerPassed(timings['Maghrib']),
      },
      {
        'name': 'Isyak',
        'arabic': 'العشاء',
        'time': _formatTime(timings['Isha']),
        'time24': timings['Isha'], // Add raw 24-hour time
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
        return {
          'name': prayer['name'],
          'time': prayer['time'],
          'time24': prayer['time24'] ?? prayer['time'], // Include 24-hour format
        };
      }
    }
    // If all prayers have passed, next prayer is Subuh of tomorrow
    // Return the actual Subuh time instead of 'Esok'
    final subuhPrayer = prayers.firstWhere(
      (prayer) => prayer['name'] == 'Subuh',
      orElse: () => {'name': 'Subuh', 'time': '--:--', 'time24': '--:--'},
    );
    return {
      'name': 'Subuh',
      'time': subuhPrayer['time'],
      'time24': subuhPrayer['time24'] ?? subuhPrayer['time'],
    };
  }

  // Get location name from coordinates (reverse geocoding) - enhanced for accuracy
  static Future<String> getLocationName(
    double latitude,
    double longitude,
  ) async {
    try {
      // Use reverse geocoding to get the actual location name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 10), onTimeout: () => []);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Try to get user-friendly location name (prefer area/neighborhood over street names)
        String? locationName;

        // Priority: locality (city/area) > subAdministrativeArea > administrativeArea > subLocality (only if short)
        if (place.locality != null && place.locality!.isNotEmpty) {
          locationName = place.locality;
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          locationName = place.subAdministrativeArea;
        } else if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          locationName = place.administrativeArea;
        } else if (place.subLocality != null &&
            place.subLocality!.isNotEmpty &&
            place.subLocality!.length <= 30) {
          // Only use subLocality if it's reasonably short
          locationName = place.subLocality;
        }

        // Filter out generic or unhelpful names and limit length
        if (locationName != null) {
          final genericNames = [
            'Malaysia',
            'Kuala Lumpur',
            'Wilayah Persekutuan',
            'Selangor',
            'Johor',
            'Pahang',
            'Perak',
            'Kedah',
            'Kelantan',
            'Terengganu',
            'Negeri Sembilan',
            'Melaka',
            'Sabah',
            'Sarawak',
          ];

          if (!genericNames.contains(locationName) && locationName.length > 2) {
            // Limit location name to 35 characters to prevent overly long names
            if (locationName.length > 35) {
              locationName = locationName.substring(0, 32) + '...';
            }
            print(
              'Location from geocoding: $locationName (lat: $latitude, lng: $longitude)',
            );
            return locationName;
          }
        }
      }

      // If geocoding didn't give us a good name, fall back to zone-based name
      final zoneCode = _getZoneFromCoordinates(latitude, longitude);
      final zoneLocation = _getLocationNameFromZone(zoneCode);
      print('Using zone-based location: $zoneLocation (zone: $zoneCode)');
      return zoneLocation;
    } catch (e) {
      print('Error getting location name: $e');
      // Final fallback to zone-based location
      try {
        final zoneCode = _getZoneFromCoordinates(latitude, longitude);
        final zoneLocation = _getLocationNameFromZone(zoneCode);
        return zoneLocation;
      } catch (zoneError) {
        print('Error getting zone location: $zoneError');
        return 'Lokasi Semasa';
      }
    }
  }
}

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

      print('🌐 Fetching from e-solat.gov.my for zone: $zoneName');

      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ e-solat.gov.my timed out after 10 seconds');
              throw Exception('Connection timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Successfully fetched from e-solat.gov.my');
        return _formatEsolatResponse(data, zoneName);
      } else {
        print('❌ e-solat.gov.my returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ e-solat.gov.my failed: $e');
      return null;
    }
  }

  // Map coordinates to Malaysian prayer zone codes (for e-solat.gov.my API)
  static String _getZoneFromCoordinates(double latitude, double longitude) {
    // Check for Putrajaya and Cyberjaya first - they should use WLY01
    // Putrajaya area: roughly 2.88-2.96 lat, 101.65-101.72 lng
    // Cyberjaya area: roughly 2.91-2.93 lat, 101.64-101.66 lng
    if (latitude >= 2.88 &&
        latitude <= 2.96 &&
        longitude >= 101.64 &&
        longitude <= 101.72) {
      print('Detected Putrajaya/Cyberjaya area - using WLY01 zone');
      return 'WLY01';
    }

    // JAKIM e-solat zones with their representative coordinates
    final zones = {
      // Wilayah Persekutuan
      'WLY01': {
        'lat': 3.1390,
        'lng': 101.6869,
        'name': 'Kuala Lumpur',
      }, // Kuala Lumpur, Putrajaya, Cyberjaya
      'WLY02': {'lat': 5.2831, 'lng': 115.2308, 'name': 'Labuan'}, // Labuan
      // Selangor
      'SGR01': {
        'lat': 3.0738,
        'lng': 101.5183,
        'name': 'Shah Alam',
      }, // Gombak, Petaling, Sepang, Hulu Langat, Hulu Selangor, Shah Alam
      'SGR02': {
        'lat': 3.3372,
        'lng': 101.2522,
        'name': 'Kuala Selangor',
      }, // Kuala Selangor, Sabak Bernam
      'SGR03': {
        'lat': 3.0319,
        'lng': 101.4445,
        'name': 'Klang',
      }, // Klang, Kuala Langat
      // Johor
      'JHR01': {
        'lat': 2.4494,
        'lng': 104.1958,
        'name': 'Pulau Aur',
      }, // Pulau Aur dan Pulau Pemanggil
      'JHR02': {
        'lat': 1.4927,
        'lng': 103.7414,
        'name': 'Johor Bahru',
      }, // Johor Bahru, Kota Tinggi, Mersing, Kulai
      'JHR03': {
        'lat': 2.0324,
        'lng': 103.3188,
        'name': 'Kluang',
      }, // Kluang, Pontian
      'JHR04': {
        'lat': 1.8549,
        'lng': 102.9328,
        'name': 'Batu Pahat',
      }, // Batu Pahat, Muar, Segamat, Gemas Johor, Tangkak
      // Perlis
      'PLS01': {
        'lat': 6.4414,
        'lng': 100.1986,
        'name': 'Kangar',
      }, // Kangar, Padang Besar, Arau
      // Penang
      'PNG01': {
        'lat': 5.4164,
        'lng': 100.3327,
        'name': 'Pulau Pinang',
      }, // Seluruh Negeri Pulau Pinang
      // Perak
      'PRK01': {
        'lat': 4.1842,
        'lng': 101.2500,
        'name': 'Tapah',
      }, // Tapah, Slim River, Tanjung Malim
      'PRK02': {
        'lat': 4.5975,
        'lng': 101.0901,
        'name': 'Ipoh',
      }, // Kuala Kangsar, Sg. Siput, Ipoh, Batu Gajah, Kampar
      'PRK03': {
        'lat': 5.0833,
        'lng': 100.9833,
        'name': 'Lenggong',
      }, // Lenggong, Pengkalan Hulu, Grik
      'PRK04': {
        'lat': 5.4500,
        'lng': 101.3667,
        'name': 'Temengor',
      }, // Temengor, Belum
      'PRK05': {
        'lat': 4.0167,
        'lng': 100.6167,
        'name': 'Teluk Intan',
      }, // Kg Gajah, Teluk Intan, Bagan Datuk, Seri Iskandar, Beruas, Parit, Lumut, Sitiawan, Pulau Pangkor
      'PRK06': {
        'lat': 5.0167,
        'lng': 100.7333,
        'name': 'Taiping',
      }, // Selama, Taiping, Bagan Serai, Parit Buntar
      'PRK07': {
        'lat': 4.8500,
        'lng': 100.7833,
        'name': 'Bukit Larut',
      }, // Bukit Larut
      // Kedah
      'KDH01': {
        'lat': 6.1184,
        'lng': 100.3685,
        'name': 'Kota Setar',
      }, // Kota Setar, Kubang Pasu, Pokok Sena (Daerah Kecil)
      'KDH02': {
        'lat': 5.6921,
        'lng': 100.4917,
        'name': 'Kuala Muda',
      }, // Kuala Muda, Yan, Pendang
      'KDH03': {
        'lat': 6.3167,
        'lng': 100.7833,
        'name': 'Padang Terap',
      }, // Padang Terap, Sik
      'KDH04': {'lat': 5.6667, 'lng': 100.9167, 'name': 'Baling'}, // Baling
      'KDH05': {
        'lat': 5.3667,
        'lng': 100.5667,
        'name': 'Kulim',
      }, // Bandar Baharu, Kulim
      'KDH06': {'lat': 6.3500, 'lng': 99.8500, 'name': 'Langkawi'}, // Langkawi
      'KDH07': {
        'lat': 5.8000,
        'lng': 100.4167,
        'name': 'Gunung Jerai',
      }, // Puncak Gunung Jerai
      // Kelantan
      'KTN01': {
        'lat': 6.1254,
        'lng': 102.2386,
        'name': 'Kota Bharu',
      }, // Bachok, Kota Bharu, Machang, Pasir Mas, Pasir Puteh, Tanah Merah, Tumpat, Kuala Krai, Mukim Chiku
      'KTN02': {
        'lat': 4.8833,
        'lng': 101.9667,
        'name': 'Gua Musang',
      }, // Gua Musang (Daerah Galas Dan Bertam), Jeli, Jajahan Kecil Lojing
      // Terengganu
      'TRG01': {
        'lat': 5.3302,
        'lng': 103.1408,
        'name': 'Kuala Terengganu',
      }, // Kuala Terengganu, Marang, Kuala Nerus
      'TRG02': {
        'lat': 5.6500,
        'lng': 102.7500,
        'name': 'Besut',
      }, // Besut, Setiu
      'TRG03': {
        'lat': 5.1500,
        'lng': 102.8500,
        'name': 'Hulu Terengganu',
      }, // Hulu Terengganu
      'TRG04': {
        'lat': 4.4500,
        'lng': 103.3000,
        'name': 'Dungun',
      }, // Dungun, Kemaman
      // Pahang
      'PHG01': {
        'lat': 2.8127,
        'lng': 104.1594,
        'name': 'Pulau Tioman',
      }, // Pulau Tioman
      'PHG02': {
        'lat': 3.8077,
        'lng': 103.3260,
        'name': 'Kuantan',
      }, // Kuantan, Pekan, Muadzam Shah
      'PHG03': {
        'lat': 3.4927,
        'lng': 102.3685,
        'name': 'Temerloh',
      }, // Jerantut, Temerloh, Maran, Bera, Chenor, Jengka
      'PHG04': {
        'lat': 3.7927,
        'lng': 101.8574,
        'name': 'Bentong',
      }, // Bentong, Lipis, Raub
      'PHG05': {
        'lat': 3.4000,
        'lng': 101.7833,
        'name': 'Genting Sempah',
      }, // Genting Sempah, Janda Baik, Bukit Tinggi
      'PHG06': {
        'lat': 4.4706,
        'lng': 101.3829,
        'name': 'Cameron Highlands',
      }, // Cameron Highlands, Genting Highlands, Bukit Fraser
      'PHG07': {
        'lat': 2.5667,
        'lng': 103.4833,
        'name': 'Rompin',
      }, // Zon Khas Daerah Rompin (Mukim Rompin, Mukim Endau, Mukim Pontian)
      // Negeri Sembilan
      'NSN01': {
        'lat': 2.6667,
        'lng': 102.4167,
        'name': 'Tampin',
      }, // Tampin, Jempol
      'NSN02': {
        'lat': 2.7258,
        'lng': 102.2533,
        'name': 'Kuala Pilah',
      }, // Jelebu, Kuala Pilah, Rembau
      'NSN03': {
        'lat': 2.7297,
        'lng': 101.9381,
        'name': 'Seremban',
      }, // Port Dickson, Seremban
      // Melaka
      'MLK01': {
        'lat': 2.1896,
        'lng': 102.2501,
        'name': 'Melaka',
      }, // SELURUH NEGERI MELAKA
      // Sabah
      'SBH01': {
        'lat': 5.8402,
        'lng': 118.1179,
        'name': 'Sandakan',
      }, // Bahagian Sandakan (Timur), Bukit Garam, Semawang, Temanggung, Tambisan, Bandar Sandakan, Sukau
      'SBH02': {
        'lat': 5.9667,
        'lng': 117.1667,
        'name': 'Beluran',
      }, // Beluran, Telupid, Pinangah, Terusan, Kuamat, Bahagian Sandakan (Barat)
      'SBH03': {
        'lat': 4.9803,
        'lng': 118.3402,
        'name': 'Lahad Datu',
      }, // Lahad Datu, Silabukan, Kunak, Sahabat, Semporna, Tungku, Bahagian Tawau (Timur)
      'SBH04': {
        'lat': 4.2481,
        'lng': 117.8934,
        'name': 'Tawau',
      }, // Bandar Tawau, Balong, Merotai, Kalabakan, Bahagian Tawau (Barat)
      'SBH05': {
        'lat': 6.8833,
        'lng': 116.8333,
        'name': 'Kudat',
      }, // Kudat, Kota Marudu, Pitas, Pulau Banggi, Bahagian Kudat
      'SBH06': {
        'lat': 6.0753,
        'lng': 116.5581,
        'name': 'Gunung Kinabalu',
      }, // Gunung Kinabalu
      'SBH07': {
        'lat': 5.9804,
        'lng': 116.0735,
        'name': 'Kota Kinabalu',
      }, // Kota Kinabalu, Ranau, Kota Belud, Tuaran, Penampang, Papar, Putatan, Bahagian Pantai Barat
      'SBH08': {
        'lat': 5.3372,
        'lng': 116.1622,
        'name': 'Keningau',
      }, // Pensiangan, Keningau, Tambunan, Nabawan, Bahagian Pendalaman (Atas)
      'SBH09': {
        'lat': 5.3476,
        'lng': 115.7469,
        'name': 'Beaufort',
      }, // Beaufort, Kuala Penyu, Sipitang, Tenom, Long Pasia, Membakut, Weston, Bahagian Pendalaman (Bawah)
      // Sarawak
      'SWK01': {
        'lat': 4.8500,
        'lng': 115.0500,
        'name': 'Limbang',
      }, // Limbang, Lawas, Sundar, Trusan
      'SWK02': {
        'lat': 4.3950,
        'lng': 113.9910,
        'name': 'Miri',
      }, // Miri, Niah, Bekenu, Sibuti, Marudi
      'SWK03': {
        'lat': 3.1667,
        'lng': 113.0333,
        'name': 'Bintulu',
      }, // Pandan, Belaga, Suai, Tatau, Sebauh, Bintulu
      'SWK04': {
        'lat': 2.3000,
        'lng': 111.8167,
        'name': 'Sibu',
      }, // Sibu, Mukah, Dalat, Song, Igan, Oya, Balingian, Kanowit, Kapit
      'SWK05': {
        'lat': 2.1333,
        'lng': 111.5167,
        'name': 'Sarikei',
      }, // Sarikei, Matu, Julau, Rajang, Daro, Bintangor, Belawai
      'SWK06': {
        'lat': 1.2333,
        'lng': 111.4667,
        'name': 'Sri Aman',
      }, // Lubok Antu, Sri Aman, Roban, Debak, Kabong, Lingga, Engkelili, Betong, Spaoh, Pusa, Saratok
      'SWK07': {
        'lat': 1.2000,
        'lng': 110.5500,
        'name': 'Samarahan',
      }, // Serian, Simunjan, Samarahan, Sebuyau, Meludam
      'SWK08': {
        'lat': 1.5533,
        'lng': 110.3592,
        'name': 'Kuching',
      }, // Kuching, Bau, Lundu, Sematan
      'SWK09': {
        'lat': 1.4167,
        'lng': 110.3500,
        'name': 'Kampung Patarikan',
      }, // Zon Khas (Kampung Patarikan)
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
      'WLY01': 'Kuala Lumpur, Putrajaya, Cyberjaya',
      'WLY02': 'Labuan',

      // Selangor
      'SGR01':
          'Gombak, Petaling, Sepang, Hulu Langat, Hulu Selangor, Shah Alam',
      'SGR02': 'Kuala Selangor, Sabak Bernam',
      'SGR03': 'Klang, Kuala Langat',

      // Johor
      'JHR01': 'Pulau Aur, Pulau Pemanggil',
      'JHR02': 'Johor Bahru, Kota Tinggi, Mersing, Kulai',
      'JHR03': 'Kluang, Pontian',
      'JHR04': 'Batu Pahat, Muar, Segamat, Gemas Johor, Tangkak',

      // Perlis
      'PLS01': 'Kangar, Padang Besar, Arau',

      // Penang
      'PNG01': 'Seluruh Negeri Pulau Pinang',

      // Perak
      'PRK01': 'Tapah, Slim River, Tanjung Malim',
      'PRK02': 'Kuala Kangsar, Sg. Siput, Ipoh, Batu Gajah, Kampar',
      'PRK03': 'Lenggong, Pengkalan Hulu, Grik',
      'PRK04': 'Temengor, Belum',
      'PRK05':
          'Kg Gajah, Teluk Intan, Bagan Datuk, Seri Iskandar, Beruas, Parit, Lumut, Sitiawan, Pulau Pangkor',
      'PRK06': 'Selama, Taiping, Bagan Serai, Parit Buntar',
      'PRK07': 'Bukit Larut',

      // Kedah
      'KDH01': 'Kota Setar, Kubang Pasu, Pokok Sena',
      'KDH02': 'Kuala Muda, Yan, Pendang',
      'KDH03': 'Padang Terap, Sik',
      'KDH04': 'Baling',
      'KDH05': 'Bandar Baharu, Kulim',
      'KDH06': 'Langkawi',
      'KDH07': 'Puncak Gunung Jerai',

      // Kelantan
      'KTN01':
          'Bachok, Kota Bharu, Machang, Pasir Mas, Pasir Puteh, Tanah Merah, Tumpat, Kuala Krai, Mukim Chiku',
      'KTN02': 'Gua Musang, Jeli, Lojing',

      // Terengganu
      'TRG01': 'Kuala Terengganu, Marang, Kuala Nerus',
      'TRG02': 'Besut, Setiu',
      'TRG03': 'Hulu Terengganu',
      'TRG04': 'Dungun, Kemaman',

      // Pahang
      'PHG01': 'Pulau Tioman',
      'PHG02': 'Kuantan, Pekan, Muadzam Shah',
      'PHG03': 'Jerantut, Temerloh, Maran, Bera, Chenor, Jengka',
      'PHG04': 'Bentong, Lipis, Raub',
      'PHG05': 'Genting Sempah, Janda Baik, Bukit Tinggi',
      'PHG06': 'Cameron Highlands, Genting Highlands, Bukit Fraser',
      'PHG07': 'Rompin (Mukim Rompin, Endau, Pontian)',

      // Negeri Sembilan
      'NSN01': 'Tampin, Jempol',
      'NSN02': 'Jelebu, Kuala Pilah, Rembau',
      'NSN03': 'Port Dickson, Seremban',

      // Melaka
      'MLK01': 'Seluruh Negeri Melaka',

      // Sabah
      'SBH01':
          'Sandakan (Timur), Bukit Garam, Semawang, Temanggung, Tambisan, Sukau',
      'SBH02': 'Beluran, Telupid, Pinangah, Terusan, Kuamat, Sandakan (Barat)',
      'SBH03':
          'Lahad Datu, Silabukan, Kunak, Sahabat, Semporna, Tungku, Tawau (Timur)',
      'SBH04': 'Tawau, Balong, Merotai, Kalabakan, Tawau (Barat)',
      'SBH05': 'Kudat, Kota Marudu, Pitas, Pulau Banggi',
      'SBH06': 'Gunung Kinabalu',
      'SBH07':
          'Kota Kinabalu, Ranau, Kota Belud, Tuaran, Penampang, Papar, Putatan',
      'SBH08': 'Pensiangan, Keningau, Tambunan, Nabawan',
      'SBH09':
          'Beaufort, Kuala Penyu, Sipitang, Tenom, Long Pasia, Membakut, Weston',

      // Sarawak
      'SWK01': 'Limbang, Lawas, Sundar, Trusan',
      'SWK02': 'Miri, Niah, Bekenu, Sibuti, Marudi',
      'SWK03': 'Pandan, Belaga, Suai, Tatau, Sebauh, Bintulu',
      'SWK04': 'Sibu, Mukah, Dalat, Song, Igan, Oya, Balingian, Kanowit, Kapit',
      'SWK05': 'Sarikei, Matu, Julau, Rajang, Daro, Bintangor, Belawai',
      'SWK06':
          'Lubok Antu, Sri Aman, Roban, Debak, Kabong, Lingga, Engkelili, Betong, Spaoh, Pusa, Saratok',
      'SWK07': 'Serian, Simunjan, Samarahan, Sebuyau, Meludam',
      'SWK08': 'Kuching, Bau, Lundu, Sematan',
      'SWK09': 'Zon Khas (Kampung Patarikan)',
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
        'Putrajaya': 'WLY01',
        'Cyberjaya': 'WLY01',
        'Labuan': 'WLY02',
        'Shah Alam': 'SGR01',
        'Gombak': 'SGR01',
        'Petaling Jaya': 'SGR01',
        'Sepang': 'SGR01',
        'Hulu Langat': 'SGR01',
        'Hulu Selangor': 'SGR01',
        'Kuala Selangor': 'SGR02',
        'Sabak Bernam': 'SGR02',
        'Klang': 'SGR03',
        'Kuala Langat': 'SGR03',
        'Pulau Aur': 'JHR01',
        'Pulau Pemanggil': 'JHR01',
        'Johor Bahru': 'JHR02',
        'Kota Tinggi': 'JHR02',
        'Mersing': 'JHR02',
        'Kulai': 'JHR02',
        'Kluang': 'JHR03',
        'Pontian': 'JHR03',
        'Batu Pahat': 'JHR04',
        'Muar': 'JHR04',
        'Segamat': 'JHR04',
        'Gemas': 'JHR04',
        'Tangkak': 'JHR04',
        'Pulau Pinang': 'PNG01',
        'Penang': 'PNG01',
        'Georgetown': 'PNG01',
        'Butterworth': 'PNG01',
        'Tapah': 'PRK01',
        'Slim River': 'PRK01',
        'Tanjung Malim': 'PRK01',
        'Kuala Kangsar': 'PRK02',
        'Sungai Siput': 'PRK02',
        'Ipoh': 'PRK02',
        'Batu Gajah': 'PRK02',
        'Kampar': 'PRK02',
        'Lenggong': 'PRK03',
        'Pengkalan Hulu': 'PRK03',
        'Grik': 'PRK03',
        'Temengor': 'PRK04',
        'Belum': 'PRK04',
        'Kampung Gajah': 'PRK05',
        'Teluk Intan': 'PRK05',
        'Bagan Datuk': 'PRK05',
        'Seri Iskandar': 'PRK05',
        'Beruas': 'PRK05',
        'Parit': 'PRK05',
        'Lumut': 'PRK05',
        'Sitiawan': 'PRK05',
        'Pulau Pangkor': 'PRK05',
        'Selama': 'PRK06',
        'Taiping': 'PRK06',
        'Bagan Serai': 'PRK06',
        'Parit Buntar': 'PRK06',
        'Bukit Larut': 'PRK07',
        'Kota Setar': 'KDH01',
        'Alor Setar': 'KDH01',
        'Kubang Pasu': 'KDH01',
        'Pokok Sena': 'KDH01',
        'Kuala Muda': 'KDH02',
        'Yan': 'KDH02',
        'Pendang': 'KDH02',
        'Sungai Petani': 'KDH02',
        'Padang Terap': 'KDH03',
        'Sik': 'KDH03',
        'Baling': 'KDH04',
        'Bandar Baharu': 'KDH05',
        'Kulim': 'KDH05',
        'Langkawi': 'KDH06',
        'Gunung Jerai': 'KDH07',
        'Bachok': 'KTN01',
        'Kota Bharu': 'KTN01',
        'Machang': 'KTN01',
        'Pasir Mas': 'KTN01',
        'Pasir Puteh': 'KTN01',
        'Tanah Merah': 'KTN01',
        'Tumpat': 'KTN01',
        'Kuala Krai': 'KTN01',
        'Mukim Chiku': 'KTN01',
        'Gua Musang': 'KTN02',
        'Jeli': 'KTN02',
        'Lojing': 'KTN02',
        'Kuala Terengganu': 'TRG01',
        'Marang': 'TRG01',
        'Kuala Nerus': 'TRG01',
        'Besut': 'TRG02',
        'Setiu': 'TRG02',
        'Hulu Terengganu': 'TRG03',
        'Dungun': 'TRG04',
        'Kemaman': 'TRG04',
        'Pulau Tioman': 'PHG01',
        'Tioman': 'PHG01',
        'Kuantan': 'PHG02',
        'Pekan': 'PHG02',
        'Muadzam Shah': 'PHG02',
        'Jerantut': 'PHG03',
        'Temerloh': 'PHG03',
        'Maran': 'PHG03',
        'Bera': 'PHG03',
        'Chenor': 'PHG03',
        'Jengka': 'PHG03',
        'Bentong': 'PHG04',
        'Lipis': 'PHG04',
        'Raub': 'PHG04',
        'Genting Sempah': 'PHG05',
        'Janda Baik': 'PHG05',
        'Bukit Tinggi': 'PHG05',
        'Cameron Highlands': 'PHG06',
        'Genting Highlands': 'PHG06',
        'Bukit Fraser': 'PHG06',
        'Rompin': 'PHG07',
        'Kangar': 'PLS01',
        'Padang Besar': 'PLS01',
        'Arau': 'PLS01',
        'Tampin': 'NSN01',
        'Jempol': 'NSN01',
        'Jelebu': 'NSN02',
        'Kuala Pilah': 'NSN02',
        'Rembau': 'NSN02',
        'Port Dickson': 'NSN03',
        'Seremban': 'NSN03',
        'Melaka': 'MLK01',
        'Alor Gajah': 'MLK01',
        'Jasin': 'MLK01',
        'Sandakan': 'SBH01',
        'Bukit Garam': 'SBH01',
        'Semawang': 'SBH01',
        'Temanggung': 'SBH01',
        'Tambisan': 'SBH01',
        'Sukau': 'SBH01',
        'Beluran': 'SBH02',
        'Telupid': 'SBH02',
        'Pinangah': 'SBH02',
        'Terusan': 'SBH02',
        'Kuamat': 'SBH02',
        'Lahad Datu': 'SBH03',
        'Silabukan': 'SBH03',
        'Kunak': 'SBH03',
        'Sahabat': 'SBH03',
        'Semporna': 'SBH03',
        'Tungku': 'SBH03',
        'Tawau': 'SBH04',
        'Balong': 'SBH04',
        'Merotai': 'SBH04',
        'Kalabakan': 'SBH04',
        'Kudat': 'SBH05',
        'Kota Marudu': 'SBH05',
        'Pitas': 'SBH05',
        'Pulau Banggi': 'SBH05',
        'Gunung Kinabalu': 'SBH06',
        'Kinabalu': 'SBH06',
        'Kota Kinabalu': 'SBH07',
        'Ranau': 'SBH07',
        'Kota Belud': 'SBH07',
        'Tuaran': 'SBH07',
        'Penampang': 'SBH07',
        'Papar': 'SBH07',
        'Putatan': 'SBH07',
        'Pensiangan': 'SBH08',
        'Keningau': 'SBH08',
        'Tambunan': 'SBH08',
        'Nabawan': 'SBH08',
        'Beaufort': 'SBH09',
        'Kuala Penyu': 'SBH09',
        'Sipitang': 'SBH09',
        'Tenom': 'SBH09',
        'Long Pasia': 'SBH09',
        'Membakut': 'SBH09',
        'Weston': 'SBH09',
        'Limbang': 'SWK01',
        'Lawas': 'SWK01',
        'Sundar': 'SWK01',
        'Trusan': 'SWK01',
        'Miri': 'SWK02',
        'Niah': 'SWK02',
        'Bekenu': 'SWK02',
        'Sibuti': 'SWK02',
        'Marudi': 'SWK02',
        'Pandan': 'SWK03',
        'Belaga': 'SWK03',
        'Suai': 'SWK03',
        'Tatau': 'SWK03',
        'Sebauh': 'SWK03',
        'Bintulu': 'SWK03',
        'Sibu': 'SWK04',
        'Mukah': 'SWK04',
        'Dalat': 'SWK04',
        'Song': 'SWK04',
        'Igan': 'SWK04',
        'Oya': 'SWK04',
        'Balingian': 'SWK04',
        'Kanowit': 'SWK04',
        'Kapit': 'SWK04',
        'Sarikei': 'SWK05',
        'Matu': 'SWK05',
        'Julau': 'SWK05',
        'Rajang': 'SWK05',
        'Daro': 'SWK05',
        'Bintangor': 'SWK05',
        'Belawai': 'SWK05',
        'Lubok Antu': 'SWK06',
        'Sri Aman': 'SWK06',
        'Roban': 'SWK06',
        'Debak': 'SWK06',
        'Kabong': 'SWK06',
        'Lingga': 'SWK06',
        'Engkelili': 'SWK06',
        'Betong': 'SWK06',
        'Spaoh': 'SWK06',
        'Pusa': 'SWK06',
        'Saratok': 'SWK06',
        'Serian': 'SWK07',
        'Simunjan': 'SWK07',
        'Samarahan': 'SWK07',
        'Sebuyau': 'SWK07',
        'Meludam': 'SWK07',
        'Kuching': 'SWK08',
        'Bau': 'SWK08',
        'Lundu': 'SWK08',
        'Sematan': 'SWK08',
        'Kampung Patarikan': 'SWK09',
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
          'time24':
              prayer['time24'] ?? prayer['time'], // Include 24-hour format
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

        // Try to get user-friendly location name
        // Priority: subLocality (kampung/kawasan) > locality (city) > subAdministrativeArea > administrativeArea
        String? locationName;

        // FIRST: Try subLocality (kampung, taman, kawasan)
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          locationName = place.subLocality;
        }
        // SECOND: Try locality (city/town name)
        else if (place.locality != null && place.locality!.isNotEmpty) {
          locationName = place.locality;
        }
        // THIRD: Try subAdministrativeArea (district)
        else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          locationName = place.subAdministrativeArea;
        }
        // FOURTH: Try administrativeArea (state)
        else if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          locationName = place.administrativeArea;
        }

        // Clean up and validate the location name
        if (locationName != null) {
          // Remove generic state/country names if they appear
          final genericNames = [
            'Malaysia',
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

          // Don't filter out if it's a subLocality (kampung/taman/kawasan)
          final isSubLocality =
              place.subLocality != null &&
              place.subLocality!.isNotEmpty &&
              locationName == place.subLocality;

          // Only use if it's specific (subLocality) OR not a generic name
          if (isSubLocality ||
              (!genericNames.contains(locationName) &&
                  locationName.length > 2)) {
            // Limit location name to 40 characters for better display
            if (locationName.length > 40) {
              locationName = locationName.substring(0, 37) + '...';
            }
            print(
              'Location from geocoding: $locationName (subLocality: ${place.subLocality}, locality: ${place.locality})',
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

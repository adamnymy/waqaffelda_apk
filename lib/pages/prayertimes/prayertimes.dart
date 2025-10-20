import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/prayer_times_service.dart';
import '../../widgets/google_maps_location_picker.dart';
import '../homepage/homepage.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({Key? key}) : super(key: key);

  @override
  _PrayerTimesPageState createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  String hijriDate = '';
  List<Map<String, dynamic>> prayerTimes = [];
  bool isLoading = true;
  String errorMessage = '';
  String locationName = 'Memuatkan...';
  String currentDate = '';
  Map<String, String>? nextPrayer;

  String? selectedLocationName;
  double? selectedLatitude;
  double? selectedLongitude;
  String? selectedCity;
  Map<String, dynamic>? selectedCoordinates;

  final List<Map<String, dynamic>> malaysianCities = [
    {'name': 'Kuala Lumpur', 'lat': 3.139, 'lng': 101.6869},
    {'name': 'Johor Bahru', 'lat': 1.4927, 'lng': 103.7414},
    {'name': 'Pulau Pinang', 'lat': 5.4164, 'lng': 100.3327},
    {'name': 'Kota Kinabalu', 'lat': 5.9804, 'lng': 116.0735},
    {'name': 'Kuching', 'lat': 1.5533, 'lng': 110.3592},
    {'name': 'Shah Alam', 'lat': 3.0733, 'lng': 101.5185},
    {'name': 'Melaka', 'lat': 2.2055, 'lng': 102.2502},
    {'name': 'Ipoh', 'lat': 4.5975, 'lng': 101.0901},
    {'name': 'Seremban', 'lat': 2.7297, 'lng': 101.9381},
    {'name': 'Petaling Jaya', 'lat': 3.1073, 'lng': 101.6067},
    {'name': 'Klang', 'lat': 3.0319, 'lng': 101.4443},
    {'name': 'Kajang', 'lat': 2.9929, 'lng': 101.7904},
    {'name': 'Ampang', 'lat': 3.1478, 'lng': 101.7596},
    {'name': 'Subang Jaya', 'lat': 3.1478, 'lng': 101.5867},
    {'name': 'Gunakan Lokasi Semasa', 'lat': null, 'lng': null},
  ];

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _setCurrentDate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setCurrentDate() {
    final now = DateTime.now();

    // Malay day names
    const malayDays = [
      'Isnin',
      'Selasa',
      'Rabu',
      'Khamis',
      'Jumaat',
      'Sabtu',
      'Ahad',
    ];

    // Malay month names
    const malayMonths = [
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

    final dayName = malayDays[now.weekday - 1];
    final monthName = malayMonths[now.month - 1];

    currentDate = '$dayName, ${now.day} $monthName ${now.year}';
    hijriDate = "24 Rabiulawal 1447";
  }

  Future<void> _loadPrayerTimes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      Map<String, dynamic>? apiData;

      if (selectedCoordinates != null &&
          selectedCoordinates!['lat'] != null &&
          selectedCoordinates!['lng'] != null) {
        final lat = selectedCoordinates!['lat'] as double?;
        final lng = selectedCoordinates!['lng'] as double?;
        if (lat != null && lng != null) {
          apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
            lat,
            lng,
          );
          locationName =
              selectedCity ?? selectedLocationName ?? 'Lokasi Terpilih';
        }
      } else if (selectedLatitude != null && selectedLongitude != null) {
        apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
          selectedLatitude!,
          selectedLongitude!,
        );
        locationName = selectedLocationName ?? 'Lokasi Terpilih';
      } else {
        Position? position = await PrayerTimesService.getCurrentLocation();

        if (position != null) {
          apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
            position.latitude,
            position.longitude,
          );
          locationName = await PrayerTimesService.getLocationName(
            position.latitude,
            position.longitude,
          );
        } else {
          apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
            3.139,
            101.6869,
          );
          locationName = 'Kuala Lumpur, Malaysia';
        }
      }

      if (apiData != null) {
        final parsedTimes = PrayerTimesService.parsePrayerTimes(apiData);
        nextPrayer = PrayerTimesService.getNextPrayer(parsedTimes);
        if (mounted) {
          setState(() {
            prayerTimes =
                parsedTimes.map((prayer) {
                  // defensive parsing for color field; allow int or hex string
                  Color parsedColor = Colors.black;
                  try {
                    final colorVal = prayer['color'];
                    if (colorVal is int) {
                      parsedColor = Color(colorVal);
                    } else if (colorVal is String) {
                      // try to parse hex like "0xFF123456" or "#123456"
                      final cleaned = colorVal.replaceAll('#', '');
                      parsedColor = Color(int.parse(cleaned, radix: 16));
                    }
                  } catch (_) {
                    parsedColor = Colors.black;
                  }

                  return {
                    ...prayer,
                    'icon': _getIconFromString(prayer['icon']),
                    'color': parsedColor,
                  };
                }).toList();
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage =
                'Gagal memuatkan waktu solat. Sila semak sambungan internet anda.';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Ralat memuatkan waktu solat: $e';
          isLoading = false;
        });
      }
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Pilih Lokasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.map,
                          color: Color(0xFF2E7D32),
                        ),
                        title: const Text(
                          'Pilih dari Peta',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Pilih mana-mana lokasi menggunakan Google Maps',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _openGoogleMapsPicker();
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.my_location,
                          color: Color(0xFF2E7D32),
                        ),
                        title: const Text(
                          'Gunakan Lokasi Semasa',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Dapatkan waktu solat untuk lokasi semasa anda',
                        ),
                        onTap: () {
                          setState(() {
                            selectedCity = null;
                            selectedCoordinates = null;
                          });
                          Navigator.pop(context);
                          _loadPrayerTimes();
                        },
                      ),
                      const Divider(),
                      ...malaysianCities
                          .map(
                            (city) => ListTile(
                              leading: const Icon(
                                Icons.location_city,
                                color: Color(0xFF2E7D32),
                              ),
                              title: Text(
                                city['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text('${city['lat']}, ${city['lng']}'),
                              onTap: () {
                                setState(() {
                                  selectedCity = city['name'];
                                  selectedCoordinates = {
                                    'lat': city['lat'],
                                    'lng': city['lng'],
                                  };
                                });
                                Navigator.pop(context);
                                _loadPrayerTimes();
                              },
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _openGoogleMapsPicker() {
    double? initialLat = selectedCoordinates?['lat'];
    double? initialLng = selectedCoordinates?['lng'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OpenStreetMapLocationPicker(
              initialLatitude: initialLat,
              initialLongitude: initialLng,
              onLocationSelected: (lat, lng, address) {
                setState(() {
                  selectedCity = address;
                  selectedCoordinates = {'lat': lat, 'lng': lng};
                });
                _loadPrayerTimes();
              },
            ),
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'wb_twilight':
        return Icons.wb_twilight;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'wb_cloudy':
        return Icons.wb_cloudy;
      case 'brightness_3':
        return Icons.brightness_3;
      case 'brightness_2':
        return Icons.brightness_2;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Homepage()),
              (route) => false, // Remove all previous routes
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_outlined, color: Colors.black),
            onPressed: _showLocationPicker,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: _loadPrayerTimes,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF36F21)),
                ),
              )
              : errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : Column(
                children: [
                  _buildHeaderCard(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            prayerTimes
                                .map((prayer) => _buildPrayerTimeCard(prayer))
                                .toList(),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/masjidnegara.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.7), // Adjusted opacity to 20%
              Colors.white.withOpacity(0.6), // Adjusted opacity to 30%
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hijriDate,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              currentDate,
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              locationName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (nextPrayer != null && nextPrayer!['time'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFDEDEDE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu solat seterusnya',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          nextPrayer!['name'] ?? 'Tidak diketahui',
                          style: const TextStyle(
                            color: Color(0xFFF36F21),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          nextPrayer!['time'] ?? '--:--',
                          style: const TextStyle(
                            color: Color(0xFFF36F21),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeCard(Map<String, dynamic> prayer) {
    final bool isNextPrayer =
        nextPrayer != null &&
        nextPrayer!['name'] == prayer['name'] &&
        !prayer['isPassed'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isNextPrayer ? const Color(0xFFF36F21) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              prayer['name'],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isNextPrayer ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Icon(
            prayer['isPassed']
                ? Icons.notifications_off_outlined
                : Icons.notifications_outlined,
            color:
                isNextPrayer
                    ? Colors.white
                    : (prayer['isPassed'] ? Colors.grey : Colors.black54),
            size: 24,
          ),
          const SizedBox(width: 16),
          Text(
            prayer['time'],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isNextPrayer ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPrayerTimes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Cuba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF36F21),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

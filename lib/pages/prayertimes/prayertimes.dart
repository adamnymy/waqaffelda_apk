import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../services/prayer_times_service.dart';
import '../../widgets/google_maps_location_picker.dart';
import '../homepage/homepage.dart';
import '../../utils/page_transitions.dart';

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

  // Track notification status for each prayer
  Map<String, bool> notificationStatus = {
    'Subuh': true,
    'Syuruk': true,
    'Zohor': true,
    'Asar': true,
    'Maghrib': true,
    'Isyak': true,
  };

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

    // Custom Hijri month names
    const customHijriMonths = [
      'Muharram',
      'Safar',
      "Rabi'ulawal",
      "Rabi'ulakhir",
      'Jamadilawwal',
      'Jamadilakhir',
      'Rejab',
      'Sha’ban',
      'Ramadan',
      'Shawwal',
      'Zulkaedah',
      'Zulhijjah',
    ];

    // Calculate Hijri date using the hijri package
    final hijriCalendar = HijriCalendar.now();
    final hijriMonthName = customHijriMonths[hijriCalendar.hMonth - 1];
    hijriDate = '${hijriCalendar.hDay} $hijriMonthName ${hijriCalendar.hYear}';
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
          // Get real location name from coordinates (either from city selection or map picker)
          if (selectedCity != null && selectedCity != 'Gunakan Lokasi Semasa') {
            // Use city name directly if selected from the list
            locationName = selectedCity!;
          } else {
            // Get location name from coordinates if selected from map
            locationName = await PrayerTimesService.getLocationName(lat, lng);
          }
        }
      } else if (selectedLatitude != null && selectedLongitude != null) {
        apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
          selectedLatitude!,
          selectedLongitude!,
        );
        // Get real location name for selected coordinates
        locationName = await PrayerTimesService.getLocationName(
          selectedLatitude!,
          selectedLongitude!,
        );
      } else {
        // Use current location
        Position? position = await PrayerTimesService.getCurrentLocation();

        if (position != null) {
          apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
            position.latitude,
            position.longitude,
          );
          // Get real location name from current position
          locationName = await PrayerTimesService.getLocationName(
            position.latitude,
            position.longitude,
          );
        } else {
          // Fallback to Kuala Lumpur if location permission denied
          apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
            3.139,
            101.6869,
          );
          locationName = await PrayerTimesService.getLocationName(
            3.139,
            101.6869,
          );
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
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF36F21),
                        const Color(0xFFFF8C42),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF36F21).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pilih Lokasi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Dapatkan waktu solat yang tepat',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick actions section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Akses Pantas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.my_location_rounded,
                              title: 'Lokasi Semasa',
                              subtitle: 'Gunakan GPS',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () {
                                setState(() {
                                  selectedCity = null;
                                  selectedCoordinates = null;
                                  selectedLatitude = null;
                                  selectedLongitude = null;
                                  selectedLocationName = null;
                                });
                                Navigator.pop(context);
                                _loadPrayerTimes();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.map_rounded,
                              title: 'Pilih dari Peta',
                              subtitle: 'Mana-mana lokasi',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _openGoogleMapsPicker();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Cities list section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Text(
                          'Bandar Popular',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          itemCount:
                              malaysianCities.length -
                              1, // Exclude "Gunakan Lokasi Semasa"
                          itemBuilder: (context, index) {
                            final city = malaysianCities[index];
                            final isSelected = selectedCity == city['name'];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
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
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(
                                                0xFFF36F21,
                                              ).withOpacity(0.1)
                                              : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? const Color(0xFFF36F21)
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? const Color(0xFFF36F21)
                                                    : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.location_city_rounded,
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : Colors.grey[600],
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                city['name'],
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      isSelected
                                                          ? const Color(
                                                            0xFFF36F21,
                                                          )
                                                          : Colors.black87,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${city['lat']}, ${city['lng']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF36F21),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          )
                                        else
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: Colors.grey[400],
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
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
              SmoothPageRoute(page: const Homepage()),
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
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      itemCount: prayerTimes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildPrayerTimeCard(prayerTimes[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      height: 285, // Increased height to prevent overflow
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/masjidnegara.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
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
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16, // Increased font size
                fontWeight: FontWeight.bold, // Made it bold for emphasis
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.black, size: 18),
                const SizedBox(width: 4),
                Text(
                  locationName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (nextPrayer != null && nextPrayer!['time'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
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
                      style: TextStyle(fontWeight: FontWeight.w400),
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

    final bool isPassed = prayer['isPassed'] ?? false;

    return Container(
      decoration: BoxDecoration(
        gradient:
            isNextPrayer
                ? LinearGradient(
                  colors: [const Color(0xFFF36F21), const Color(0xFFFF8C42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : null,
        color: isNextPrayer ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                isNextPrayer
                    ? const Color(0xFFF36F21).withOpacity(0.3)
                    : Colors.black.withOpacity(0.06),
            blurRadius: isNextPrayer ? 12 : 8,
            offset: Offset(0, isNextPrayer ? 4 : 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isNextPrayer
                        ? Colors.white.withOpacity(0.2)
                        : isPassed
                        ? Colors.grey[100]
                        : const Color(0xFFF36F21).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                prayer['icon'] ?? Icons.access_time,
                color:
                    isNextPrayer
                        ? Colors.white
                        : isPassed
                        ? Colors.grey[400]
                        : const Color(0xFFF36F21),
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            // Prayer Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer['name'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          isNextPrayer
                              ? Colors.white
                              : isPassed
                              ? Colors.grey[600]
                              : Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (isNextPrayer) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Seterusnya',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Notification Icon Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:
                    isNextPrayer
                        ? Colors.white.withOpacity(0.2)
                        : isPassed
                        ? Colors.grey[100]
                        : (notificationStatus[prayer['name']] ?? true)
                        ? const Color(0xFFF36F21).withOpacity(0.15)
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isNextPrayer
                          ? Colors.white.withOpacity(0.3)
                          : (notificationStatus[prayer['name']] ?? true) &&
                              !isPassed
                          ? const Color(0xFFF36F21).withOpacity(0.3)
                          : Colors.transparent,
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed:
                    isPassed
                        ? null
                        : () {
                          setState(() {
                            final prayerName = prayer['name'] as String?;
                            if (prayerName != null &&
                                notificationStatus.containsKey(prayerName)) {
                              notificationStatus[prayerName] =
                                  !notificationStatus[prayerName]!;

                              // Show feedback snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        notificationStatus[prayerName]!
                                            ? Icons.notifications_active
                                            : Icons.notifications_off,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          notificationStatus[prayerName]!
                                              ? 'Notifikasi $prayerName dihidupkan'
                                              : 'Notifikasi $prayerName dimatikan',
                                        ),
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(milliseconds: 1500),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor:
                                      notificationStatus[prayerName]!
                                          ? const Color(0xFF4CAF50)
                                          : Colors.grey[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          });
                        },
                icon: Icon(
                  (notificationStatus[prayer['name']] ?? true)
                      ? Icons.notifications
                      : Icons.notifications_off,
                  color:
                      isNextPrayer
                          ? Colors.white
                          : isPassed
                          ? Colors.grey[400]
                          : (notificationStatus[prayer['name']] ?? true)
                          ? const Color(0xFFF36F21)
                          : Colors.grey[500],
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                splashRadius: 20,
              ),
            ),

            const SizedBox(width: 10),

            // Time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isNextPrayer
                        ? Colors.white.withOpacity(0.2)
                        : isPassed
                        ? Colors.grey[50]
                        : const Color(0xFFFFF4E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                prayer['time'] ?? '--:--',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color:
                      isNextPrayer
                          ? Colors.white
                          : isPassed
                          ? Colors.grey[600]
                          : const Color(0xFFF36F21),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
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

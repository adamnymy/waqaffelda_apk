import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../services/prayer_times_service.dart';
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
    // Only show loading spinner on first load
    if (prayerTimes.isEmpty) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      Map<String, dynamic>? apiData;

      // Use current location (GPS only)
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              )
              : errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : Column(
                children: [
                  _buildHeaderCard(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildAllPrayerTimesCard(),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      height: 250, // Reduced height to prevent overflow
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
                            color: Colors.teal,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          nextPrayer!['time'] ?? '--:--',
                          style: const TextStyle(
                            color: Colors.teal,
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

  Widget _buildAllPrayerTimesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children:
            prayerTimes.map((prayer) {
              final bool isNextPrayer =
                  nextPrayer != null &&
                  nextPrayer!['name'] == prayer['name'] &&
                  !prayer['isPassed'];
              final bool isPassed = prayer['isPassed'] ?? false;
              final int index = prayerTimes.indexOf(prayer);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isNextPrayer
                                    ? Colors.teal.withOpacity(0.15)
                                    : isPassed
                                    ? Colors.grey.shade200
                                    : Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            prayer['icon'] ?? Icons.access_time,
                            color:
                                isNextPrayer
                                    ? Colors.teal
                                    : isPassed
                                    ? Colors.grey.shade400
                                    : Colors.teal,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            prayer['name'] ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  isNextPrayer
                                      ? Colors.teal
                                      : isPassed
                                      ? Colors.grey.shade500
                                      : Colors.black87,
                            ),
                          ),
                        ),
                        if (isNextPrayer)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Seterusnya',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(width: 16),
                        Text(
                          prayer['time'] ?? '--:--',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isNextPrayer ? Colors.teal : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < prayerTimes.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                      indent: 20,
                      endIndent: 20,
                    ),
                ],
              );
            }).toList(),
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
                backgroundColor: Colors.teal,
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

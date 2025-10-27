import 'dart:ui';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadPrayerTimes,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/nabawi(sulthan-auliya).jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.1),
            BlendMode.darken,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Blur effect
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.1)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Content
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Date Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        hijriDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              locationName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Next Prayer Card
                if (nextPrayer != null && nextPrayer!['time'] != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.9),
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waktu Solat Seterusnya',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                nextPrayer!['name'] ?? 'Tidak diketahui',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            nextPrayer!['time'] ?? '--:--',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPrayerTimesCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
                                    ? colorScheme.primary.withOpacity(0.15)
                                    : isPassed
                                    ? Colors.grey.shade200
                                    : colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            prayer['icon'] ?? Icons.access_time,
                            color:
                                isNextPrayer
                                    ? colorScheme.primary
                                    : isPassed
                                    ? Colors.grey.shade400
                                    : colorScheme.primary,
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
                                      ? colorScheme.primary
                                      : isPassed
                                      ? Colors.grey.shade500
                                      : colorScheme.onSurface,
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
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Seterusnya',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
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
                            color:
                                isNextPrayer
                                    ? colorScheme.primary
                                    : Colors.black54,
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
    final colorScheme = Theme.of(context).colorScheme;

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
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../services/prayer_times_service.dart';
import '../../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../homepage/homepage.dart';
import '../../utils/page_transitions.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({Key? key}) : super(key: key);

  @override
  _PrayerTimesPageState createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String hijriDate = '';
  List<Map<String, dynamic>> prayerTimes = [];
  bool isLoading = true;
  String errorMessage = '';
  String locationName = 'Memuatkan...';
  String currentDate = '';
  Map<String, String>? nextPrayer;

  // Animation controller for refresh button
  late AnimationController _refreshAnimationController;
  bool _isRefreshing = false;

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
    WidgetsBinding.instance.addObserver(this);
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _setCurrentDate();
    // Initialize notifications first, then load prayer times
    // Prayer times loading will trigger auto-schedule if needed
    _initializeNotifications();
    _loadPrayerTimes();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes, check if we need to reschedule
    if (state == AppLifecycleState.resumed) {
      print('📱 App resumed - checking if reschedule needed');
      _checkAndReschedule();
    }
  }

  /// Check and reschedule notifications if date changed
  Future<void> _checkAndReschedule() async {
    if (prayerTimes.isEmpty) return;

    try {
      final notificationService = NotificationService();
      final shouldReschedule = await notificationService.shouldReschedule();

      if (shouldReschedule) {
        print('🔄 Date changed, rescheduling...');
        await notificationService.schedulePrayerNotificationsWithTracking(
          prayerTimes,
          locationName: locationName,
        );
        // SnackBar removed per user request. Keep function but suppress UI toast.
        if (mounted) {
          // Optionally log or handle non-UI feedback here.
          print('Notifikasi dikemaskini untuk hari baru (snackbar suppressed)');
        }
      }
    } catch (e) {
      print('❌ Error checking reschedule: $e');
    }
  }

  /// Initialize notification service
  Future<void> _initializeNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequestedPermission =
          prefs.getBool('notification_permission_requested') ?? false;

      final notificationService = NotificationService();
      await notificationService.initialize();

      // Only request permission if it hasn't been requested before
      if (!hasRequestedPermission) {
        print('🔔 Requesting notification permission from prayer times page');
        final granted = await notificationService.requestPermission();

        if (granted) {
          print('✅ Notification permission granted');
        } else {
          print('⚠️ Notification permission denied');
          if (mounted) {
            // SnackBar removed per user request. Keep function but suppress UI toast.
            print(
              'Notifikasi diperlukan untuk menghantar peringatan waktu solat (snackbar suppressed)',
            );
          }
        }

        // Mark that we've requested permission
        await prefs.setBool('notification_permission_requested', true);
      } else {
        print('ℹ️ Notification permission already requested (skipping dialog)');
        // Schedule will be triggered after prayer times are loaded
      }
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshAnimationController.dispose();
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
    // Start rotation animation
    setState(() {
      _isRefreshing = true;
    });
    _refreshAnimationController.repeat();

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
        print(
          '📍 GPS coordinates: ${position.latitude}, ${position.longitude}',
        );
        apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
          position.latitude,
          position.longitude,
        );
        // Get real location name from current position
        locationName = await PrayerTimesService.getLocationName(
          position.latitude,
          position.longitude,
        );
        // Check previous location before saving new one
        final prefs = await SharedPreferences.getInstance();
        final previousLocation = prefs.getString('current_location_name');
        // Always save location to SharedPreferences so notifications use latest location
        await prefs.setString('current_location_name', locationName);
        print(
          '💾 Saved location name: $locationName${previousLocation != null && previousLocation != locationName ? " (changed from $previousLocation)" : ""}',
        );
      } else {
        // Fallback to Kuala Lumpur if location permission denied
        print(
          '⚠️ GPS not available, using fallback coordinates: 3.139, 101.6869',
        );
        apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
          3.139,
          101.6869,
        );
        locationName = 'Lokasi tidak dapat dikesan';
        // Check previous location before saving new one
        final prefs = await SharedPreferences.getInstance();
        final previousLocation = prefs.getString('current_location_name');
        // Always save location to SharedPreferences so notifications use latest location
        await prefs.setString('current_location_name', locationName);
        print(
          '💾 Saved location name: $locationName${previousLocation != null && previousLocation != locationName ? " (changed from $previousLocation)" : ""}',
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

          // Schedule notifications after prayer times loaded
          _scheduleNotifications();
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage =
                'Tidak dapat memuatkan waktu solat.\n\n'
                'Server JAKIM e-solat.gov.my tidak dapat dihubungi. '
                'Sila semak sambungan internet anda atau cuba lagi sebentar lagi.';
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
    } finally {
      // Stop rotation animation when GPS detected
      if (mounted) {
        _refreshAnimationController.stop();
        setState(() {
          _isRefreshing = false;
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

  /// Schedule prayer time notifications
  Future<void> _scheduleNotifications() async {
    try {
      if (prayerTimes.isEmpty) return;

      final notificationService = NotificationService();

      // Check if this is the first time (no last_scheduled_date)
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = !prefs.containsKey('last_scheduled_date');

      // Check if location has changed by comparing stored location with current
      // (Location was just saved in _loadPrayerTimes, so stored should match current)
      // But we need to detect if it changed from a previous session
      // We'll store a separate "last_scheduled_location" to track what location was used for scheduling
      final lastScheduledLocation = prefs.getString('last_scheduled_location');
      final locationChanged =
          lastScheduledLocation != null &&
          lastScheduledLocation != locationName;

      // Use enhanced method with date tracking
      final wasRescheduled = await notificationService.autoRescheduleIfNeeded(
        prayerTimes,
        locationName: locationName,
      );

      // If location changed but date hasn't, force reschedule to update location in notifications
      if (!wasRescheduled && locationChanged) {
        print(
          '📍 Location changed from "$lastScheduledLocation" to "$locationName" - forcing reschedule',
        );
        await notificationService.forceReschedule(
          prayerTimes,
          locationName: locationName,
        );
        // Save the location that was used for scheduling
        await prefs.setString('last_scheduled_location', locationName);
        // Cache minimal prayer times so background rescheduler can re-register
        try {
          await NotificationService().cachePrayerTimesMinimal(prayerTimes);
        } catch (e) {
          print('⚠️ Failed to cache prayer times: $e');
        }
        print('✅ Notifications rescheduled with new location: $locationName');
        return;
      }

      // If rescheduled (date changed), also save the location that was used
      if (wasRescheduled) {
        await prefs.setString('last_scheduled_location', locationName);
      }

      if (!wasRescheduled) {
        // Not rescheduled, means already scheduled for today and location hasn't changed
        print(
          'ℹ️ Notifications already scheduled for today with same location',
        );
        return;
      }

      // Cache minimal prayer times so background rescheduler can re-register
      try {
        await NotificationService().cachePrayerTimesMinimal(prayerTimes);
      } catch (e) {
        print('⚠️ Failed to cache prayer times: $e');
      }

      // Show confirmation snackbar (always show on first time, or when rescheduled)
      if (mounted && (isFirstTime || wasRescheduled)) {
        // Confirmation snackbar removed per user request.
        print(
          isFirstTime
              ? 'Notifikasi waktu solat telah diaktifkan! (snackbar suppressed)'
              : 'Notifikasi waktu solat telah dijadualkan (snackbar suppressed)',
        );
      }

      print('✅ Prayer notifications scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling notifications: $e');
      if (mounted) {
        // Error snackbar removed per user request. Keep function but suppress UI toast.
        print('Gagal menjadualkan notifikasi (snackbar suppressed) - $e');
      }
    }
  }

  // _showScheduleInfo removed as per user request (info button removed)

  // Removed exact-alarm/battery dialog, force reschedule, and execution log
  // These were only referenced from the info (ℹ️) button which the user asked to remove.
  // If you want them re-added later, we can restore them on request.

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Color(
        0xFFFFFFFF,
      ), // Light grey background to match cards
      // FloatingActionButton removed
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
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to settings page
            },
          ),
          _isRefreshing
              ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _refreshAnimationController,
                        builder: (context, child) {
                          final delay = index * 0.2;
                          final animValue = (_refreshAnimationController.value -
                                  delay)
                              .clamp(0.0, 1.0);
                          final scale =
                              0.5 + (0.5 * (1 - (animValue * 2 - 1).abs()));

                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              )
              : IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadPrayerTimes,
              ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body:
          isLoading
              ? _buildSkeletonLoading()
              : errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : Column(
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      child: _buildAllPrayerTimesCard(),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildHeaderCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // SVG background (use SvgPicture for vector assets)
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/widget-bg-wsolat-v2.svg',
              fit: BoxFit.cover,
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                children: [
                  // Date Section - Fixed height card with flexible content
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              hijriDate,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.003),
                            Container(
                              height: 1,
                              width: 30,
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
                            SizedBox(height: screenHeight * 0.003),
                            Text(
                              currentDate,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white.withOpacity(0.8),
                                  size: screenWidth * 0.04,
                                ),
                                SizedBox(width: screenWidth * 0.015),
                                Text(
                                  locationName,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: screenWidth * 0.048,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Next Prayer Card - Fixed height card with flexible content
                  if (nextPrayer != null && nextPrayer!['time'] != null)
                    Expanded(
                      flex: 4,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.008,
                        ),
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Waktu Solat Seterusnya',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: screenWidth * 0.03,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.003),
                                  Text(
                                    nextPrayer!['name'] ?? 'Tidak diketahui',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.058,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: screenWidth * 0.04),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.035,
                                  vertical: screenHeight * 0.008,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  nextPrayer!['time'] ?? '--:--',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.058,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPrayerTimesCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.02),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Column(
        children:
            prayerTimes.asMap().entries.map((entry) {
              final Map<String, dynamic> prayer = entry.value;

              final bool isNextPrayer =
                  nextPrayer != null &&
                  nextPrayer!['name'] == prayer['name'] &&
                  !prayer['isPassed'];
              final bool isPassed = prayer['isPassed'] ?? false;

              return Container(
                margin: EdgeInsets.only(bottom: screenHeight * 0.012),
                decoration: BoxDecoration(
                  gradient:
                      isNextPrayer
                          ? LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade500,
                            ],
                          )
                          : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isPassed
                                  ? Colors.grey.shade100
                                  : colorScheme.surface,
                              isPassed
                                  ? Colors.grey.shade50
                                  : colorScheme.surface,
                            ],
                          ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isNextPrayer
                              ? Colors.orange.withOpacity(0.3)
                              : Colors.black.withOpacity(0.06),
                      blurRadius: isNextPrayer ? 12 : 8,
                      offset: Offset(0, isNextPrayer ? 4 : 2),
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(
                    color:
                        isNextPrayer
                            ? Colors.orange.shade300.withOpacity(0.5)
                            : isPassed
                            ? Colors.grey.shade200
                            : colorScheme.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.045,
                    vertical: screenHeight * 0.018,
                  ),
                  child: Row(
                    children: [
                      // Icon Container
                      Container(
                        width: screenWidth * 0.13,
                        height: screenWidth * 0.13,
                        decoration: BoxDecoration(
                          color:
                              isNextPrayer
                                  ? Colors.white.withOpacity(0.25)
                                  : isPassed
                                  ? Colors.grey.shade200
                                  : colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isNextPrayer
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          prayer['icon'] ?? Icons.access_time,
                          color:
                              isNextPrayer
                                  ? Colors.white
                                  : isPassed
                                  ? Colors.grey.shade400
                                  : colorScheme.primary,
                          size: screenWidth * 0.065,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      // Prayer Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayer['name'] ?? '',
                              style: TextStyle(
                                fontSize: screenWidth * 0.048,
                                fontWeight: FontWeight.w700,
                                color:
                                    isNextPrayer
                                        ? Colors.white
                                        : isPassed
                                        ? Colors.grey.shade500
                                        : colorScheme.onSurface,
                                letterSpacing: 0.2,
                                height: 1.2,
                              ),
                            ),
                            if (isNextPrayer)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'SETERUSNYA',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.025,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Time Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.045,
                          vertical: screenHeight * 0.012,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isNextPrayer
                                  ? Colors.white
                                  : isPassed
                                  ? Colors.grey.shade200
                                  : colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow:
                              isNextPrayer
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: screenWidth * 0.04,
                              color:
                                  isNextPrayer
                                      ? Colors.orange.shade700
                                      : isPassed
                                      ? Colors.grey.shade500
                                      : colorScheme.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              prayer['time'] ?? '--:--',
                              style: TextStyle(
                                fontSize: screenWidth * 0.042,
                                fontWeight: FontWeight.w800,
                                color:
                                    isNextPrayer
                                        ? Colors.orange.shade700
                                        : isPassed
                                        ? Colors.grey.shade600
                                        : colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        // Header Skeleton
        Container(
          width: double.infinity,
          height: 350,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/images/widget-bg-wsolat-v2.svg',
                  fit: BoxFit.cover,
                ),
              ),
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
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.008,
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildShimmer(
                                Container(
                                  width: 150,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildShimmer(
                                Container(
                                  width: 200,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildShimmer(
                                Container(
                                  width: 180,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 4,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.008,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A7E6E).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildShimmer(
                                    Container(
                                      width: 140,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildShimmer(
                                    Container(
                                      width: 100,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              _buildShimmer(
                                Container(
                                  width: 80,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Prayer Cards Skeleton
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Column(
              children: List.generate(6, (index) => _buildSkeletonPrayerCard()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonPrayerCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.012),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.045,
          vertical: screenHeight * 0.018,
        ),
        child: Row(
          children: [
            _buildShimmer(
              Container(
                width: screenWidth * 0.13,
                height: screenWidth * 0.13,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmer(
                    Container(
                      width: 100,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildShimmer(
              Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(Widget child) {
    return AnimatedBuilder(
      animation: _refreshAnimationController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                _refreshAnimationController.value - 0.3,
                _refreshAnimationController.value,
                _refreshAnimationController.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
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

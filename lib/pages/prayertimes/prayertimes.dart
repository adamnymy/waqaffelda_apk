import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/prayer_times_service.dart';
import '../../services/notification_service.dart';
import '../../services/widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../homepage/homepage.dart';
import '../../utils/page_transitions.dart';

import 'package:flutter/foundation.dart';

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
  DateTime selectedDate = DateTime.now();

  // Monthly prayer times cache
  Map<String, List<Map<String, dynamic>>>? monthlyPrayerCache;
  String? cachedMonth; // Format: "YYYY-MM"
  String? cachedZone;

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
      duration: const Duration(milliseconds: 600),
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
      debugPrint('📱 App resumed - checking if reschedule needed');
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
        debugPrint(
          '🔄 Date changed, rescheduling with accurate 7-day times...',
        );

        // Build accurate 7-day prayer times. Prefer using the already-fetched
        // monthly cache (`monthlyPrayerCache`) when available to avoid extra
        // network requests. For days not present in the cache (month boundary),
        // fall back to fetching the day's data from the API.

        final now = DateTime.now();
        final List<Map<String, dynamic>> allPrayerTimes = [];

        // Try to obtain last known coordinates from saved prefs if needed
        final prefs = await SharedPreferences.getInstance();
        double? lastLat = prefs.getDouble('last_known_lat');
        double? lastLng = prefs.getDouble('last_known_lng');

        for (int day = 0; day < 7; day++) {
          final targetDate = now.add(Duration(days: day));
          final dayKey = targetDate.day.toString().padLeft(2, '0');

          List<Map<String, dynamic>>? dayPrayers;

          // Use monthly cache when it matches the target month
          if (monthlyPrayerCache != null && cachedMonth != null) {
            final cacheMonth = cachedMonth!; // format YYYY-MM
            final targetMonth =
                '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';
            if (cacheMonth == targetMonth &&
                monthlyPrayerCache!.containsKey(dayKey)) {
              dayPrayers = List<Map<String, dynamic>>.from(
                monthlyPrayerCache![dayKey]!,
              );
            }
          }

          // If not found in cache, fetch from API (needs coordinates)
          if (dayPrayers == null) {
            try {
              // If we don't have last known coords, attempt to get current location
              if (lastLat == null || lastLng == null) {
                final pos = await PrayerTimesService.getCurrentLocation();
                if (pos != null) {
                  lastLat = pos.latitude;
                  lastLng = pos.longitude;
                }
              }

              if (lastLat != null && lastLng != null) {
                final prayerData =
                    await PrayerTimesService.getPrayerTimesForMalaysia(
                      lastLat,
                      lastLng,
                      forDate: targetDate,
                    );

                if (prayerData != null) {
                  dayPrayers = PrayerTimesService.parsePrayerTimes(prayerData);
                }
              }
            } catch (e) {
              debugPrint(
                '⚠️ Failed to fetch prayer times for ${targetDate.toIso8601String()}: $e',
              );
            }
          }

          if (dayPrayers != null && dayPrayers.isNotEmpty) {
            for (var p in dayPrayers) {
              final entry = Map<String, dynamic>.from(p);
              entry['dayOffset'] = day;
              entry['date'] = DateFormat('yyyy-MM-dd').format(targetDate);
              allPrayerTimes.add(entry);
            }
            debugPrint(
              '  ✅ Fetched ${dayPrayers.length} prayers for ${targetDate.toIso8601String().split('T').first}',
            );
          } else {
            debugPrint(
              '  ⚠️ No prayer times available for ${targetDate.toIso8601String().split('T').first}',
            );
          }
        }

        if (allPrayerTimes.isNotEmpty) {
          await notificationService.schedule7DaysPrayerNotifications(
            allPrayerTimes,
            locationName: locationName,
          );
        } else {
          debugPrint(
            '❌ Failed to build 7-day prayer times - falling back to single-day scheduling',
          );
          await notificationService.schedulePrayerNotificationsWithTracking(
            prayerTimes,
            locationName: locationName,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking reschedule: $e');
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
        debugPrint(
          '🔔 Requesting notification permission from prayer times page',
        );
        final granted = await notificationService.requestPermission();

        if (granted) {
          debugPrint('✅ Notification permission granted');
        } else {
          debugPrint('⚠️ Notification permission denied');
          if (mounted) {
            // SnackBar removed per user request. Keep function but suppress UI toast.
            debugPrint(
              'Notifikasi diperlukan untuk menghantar peringatan waktu solat (snackbar suppressed)',
            );
          }
        }

        // Mark that we've requested permission
        await prefs.setBool('notification_permission_requested', true);
      } else {
        debugPrint(
          'ℹ️ Notification permission already requested (skipping dialog)',
        );
        // Schedule will be triggered after prayer times are loaded
      }
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshAnimationController.dispose();
    super.dispose();
  }

  void _setCurrentDate({DateTime? forDate}) {
    final now = forDate ?? DateTime.now();

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
    final hijriCalendar = HijriCalendar.fromDate(now);
    final hijriMonthName = customHijriMonths[hijriCalendar.hMonth - 1];
    hijriDate = '${hijriCalendar.hDay} $hijriMonthName ${hijriCalendar.hYear}';
  }

  // Navigate to previous day
  void _goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
      _setCurrentDate(forDate: selectedDate);
    });
    _loadPrayerTimesFromCache();
  }

  // Navigate to next day
  void _goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
      _setCurrentDate(forDate: selectedDate);
    });
    _loadPrayerTimesFromCache();
  }

  // Jump to today
  void _goToToday() {
    setState(() {
      selectedDate = DateTime.now();
      _setCurrentDate(forDate: selectedDate);
    });
    _loadPrayerTimesFromCache();
  }

  // Load prayer times from cache or fetch if needed
  void _loadPrayerTimesFromCache() {
    final monthKey =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}';
    final dayKey = selectedDate.day.toString().padLeft(2, '0');

    // Check if we have cached data for this month
    if (monthlyPrayerCache != null &&
        cachedMonth == monthKey &&
        monthlyPrayerCache!.containsKey(dayKey)) {
      // Use cached data - instant navigation!
      final cachedData = monthlyPrayerCache![dayKey]!;
      setState(() {
        prayerTimes =
            cachedData.map((prayer) {
              // Convert icon if it's still a string
              if (prayer['icon'] is String) {
                return {...prayer, 'icon': _getIconFromString(prayer['icon'])};
              }
              return prayer;
            }).toList();
        nextPrayer = PrayerTimesService.getNextPrayer(prayerTimes);
      });
    } else {
      // Need to fetch new data (different month or cache empty)
      _loadPrayerTimes();
    }
  }

  // Check if selected date is today
  bool _isToday() {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  // Get Malay month name
  String _getMonthName(int month) {
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
    return malayMonths[month - 1];
  }

  // Get Malay day name
  String _getDayName(int weekday) {
    const malayDays = [
      'Isnin',
      'Selasa',
      'Rabu',
      'Khamis',
      'Jumaat',
      'Sabtu',
      'Ahad',
    ];
    return malayDays[weekday - 1];
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
      // Use current location (GPS only)
      Position? position = await PrayerTimesService.getCurrentLocation();
      double lat = 3.139;
      double lng = 101.6869;

      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
        debugPrint('📍 GPS coordinates: $lat, $lng');

        // Get real location name from current position
        locationName = await PrayerTimesService.getLocationName(lat, lng);
      } else {
        debugPrint('⚠️ GPS not available, using fallback coordinates');
        locationName = 'Lokasi tidak dapat dikesan';
      }

      // Save location to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final previousLocation = prefs.getString('current_location_name');
      await prefs.setString('current_location_name', locationName);
      debugPrint(
        '💾 Saved location name: $locationName${previousLocation != null && previousLocation != locationName ? " (changed from $previousLocation)" : ""}',
      );

      // Fetch full monthly prayer times for caching
      final monthKey =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}';
      final monthlyData = await PrayerTimesService.getMonthlyPrayerTimes(
        lat,
        lng,
        selectedDate,
      );

      if (monthlyData != null && monthlyData.isNotEmpty) {
        // Cache the monthly data
        monthlyPrayerCache = monthlyData;
        cachedMonth = monthKey;

        // Get times for the selected day
        final dayKey = selectedDate.day.toString().padLeft(2, '0');
        final todayPrayerTimes =
            monthlyData[dayKey] ?? monthlyData[selectedDate.day.toString()];

        if (todayPrayerTimes != null) {
          nextPrayer = PrayerTimesService.getNextPrayer(todayPrayerTimes);
          if (mounted) {
            setState(() {
              prayerTimes =
                  todayPrayerTimes.map((prayer) {
                    // defensive parsing for color field
                    Color parsedColor = Colors.black;
                    try {
                      final colorVal = prayer['color'];
                      if (colorVal is int) {
                        parsedColor = Color(colorVal);
                      } else if (colorVal is String) {
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

            // Schedule notifications ONLY for today's prayer times (not past/future dates)
            if (_isToday()) {
              _scheduleNotifications();

              // Update widget with fresh prayer times
              WidgetService.updateWidget();
              debugPrint('🔄 Widget updated with fresh prayer times');
            }
          }
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
        debugPrint(
          '📍 Location changed from "$lastScheduledLocation" to "$locationName" - forcing reschedule',
        );
        debugPrint('🔎 [forceReschedule] Using location: $locationName');
        debugPrint(
          '🔎 [forceReschedule] Using prayerTimes: ' +
              (prayerTimes.isNotEmpty
                  ? prayerTimes.map((e) => e.toString()).join(', ')
                  : 'EMPTY'),
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
          debugPrint('⚠️ Failed to cache prayer times: $e');
        }
        // Update widget with new prayer times
        try {
          await WidgetService.forceRefreshWidget();
          debugPrint('🔄 Widget updated after location change');
        } catch (e) {
          debugPrint('⚠️ Failed to update widget: $e');
        }
        debugPrint(
          '✅ Notifications rescheduled with new location: $locationName',
        );
        return;
      }

      // If rescheduled (date changed), also save the location that was used
      if (wasRescheduled) {
        await prefs.setString('last_scheduled_location', locationName);
      }

      if (!wasRescheduled) {
        // Not rescheduled, means already scheduled for today and location hasn't changed
        debugPrint(
          'ℹ️ Notifications already scheduled for today with same location',
        );
        return;
      }

      // Cache minimal prayer times so background rescheduler can re-register
      try {
        await NotificationService().cachePrayerTimesMinimal(prayerTimes);
      } catch (e) {
        debugPrint('⚠️ Failed to cache prayer times: $e');
      }

      // Show confirmation snackbar (always show on first time, or when rescheduled)
      if (mounted && (isFirstTime || wasRescheduled)) {
        // Confirmation snackbar removed per user request.
        debugPrint(
          isFirstTime
              ? 'Notifikasi waktu solat telah diaktifkan! (snackbar suppressed)'
              : 'Notifikasi waktu solat telah dijadualkan (snackbar suppressed)',
        );
      }

      debugPrint('✅ Prayer notifications scheduled successfully');
    } catch (e) {
      debugPrint('❌ Error scheduling notifications: $e');
      if (mounted) {
        // Error snackbar removed per user request. Keep function but suppress UI toast.
        debugPrint('Gagal menjadualkan notifikasi (snackbar suppressed) - $e');
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
                  // Date Navigation Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Previous Day Button
                        IconButton(
                          onPressed: _goToPreviousDay,
                          icon: Icon(Icons.arrow_back_ios_rounded),
                          color: colorScheme.primary,
                          tooltip: 'Hari sebelumnya',
                        ),
                        // Date Display with Today button
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${_getDayName(selectedDate.weekday)}, ${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (!_isToday())
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: TextButton.icon(
                                    onPressed: _goToToday,
                                    icon: Icon(Icons.today_rounded, size: 14),
                                    label: Text(
                                      'Kembali ke Hari Ini',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: colorScheme.primary,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Next Day Button
                        IconButton(
                          onPressed: _goToNextDay,
                          icon: Icon(Icons.arrow_forward_ios_rounded),
                          color: colorScheme.primary,
                          tooltip: 'Hari berikutnya',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Column(
        children:
            prayerTimes.asMap().entries.map((entry) {
              final prayer = entry.value;
              final bool isNextPrayer =
                  nextPrayer != null &&
                  nextPrayer!['name'] == prayer['name'] &&
                  !prayer['isPassed'];
              final bool isPassed = prayer['isPassed'] ?? false;

              return Container(
                margin: EdgeInsets.only(bottom: 6),
                height:
                    (screenHeight - 500) /
                    6, // Divide available space by 6 cards
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
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isNextPrayer
                              ? Colors.orange.withOpacity(0.25)
                              : Colors.black.withOpacity(0.05),
                      blurRadius: isNextPrayer ? 8 : 4,
                      offset: Offset(0, isNextPrayer ? 2 : 1),
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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              isNextPrayer
                                  ? Colors.white.withOpacity(0.25)
                                  : isPassed
                                  ? Colors.grey.shade200
                                  : colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
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
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      // Prayer Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              prayer['name'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color:
                                    isNextPrayer
                                        ? Colors.white
                                        : isPassed
                                        ? Colors.grey.shade500
                                        : colorScheme.onSurface,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (isNextPrayer)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'SETERUSNYA',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Time
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isNextPrayer
                                  ? Colors.white
                                  : isPassed
                                  ? Colors.grey.shade200
                                  : colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          prayer['time'] ?? '--:--',
                          style: TextStyle(
                            fontSize: 15,
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
    final colorScheme = Theme.of(context).colorScheme;

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
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withOpacity(0.9),
                                colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
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
        // Date Navigation Skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmer(
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              _buildShimmer(
                Container(
                  width: 180,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              _buildShimmer(
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Prayer Cards Skeleton (1x6 compact layout)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: List.generate(
                  6,
                  (index) => _buildSkeletonPrayerCard(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonPrayerCard() {
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 6),
      height: (screenHeight - 500) / 6,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Icon skeleton
            _buildShimmer(
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(width: 12),
            // Prayer name skeleton
            Expanded(
              child: _buildShimmer(
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            // Time skeleton
            _buildShimmer(
              Container(
                width: 70,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
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

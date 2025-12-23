import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../../navbar.dart';
import '../prayertimes/prayertimes.dart';
import '../../services/prayer_times_service.dart';
import '../../services/notification_service.dart';
import '../../services/widget_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../zikircounter/zikircounter.dart';
import '../program/program_page.dart';
import '../waqaf/waqafpage.dart';
import '../inbox/inboxpage.dart';
import '../akaun/akaunpage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/page_transitions.dart';
import 'others_menu_page.dart';
import 'searchpage/search_page.dart';
import '../kiblat/kiblat.dart';
import '../quran/quranpage.dart';
import '../doaharian/doa_harian_page.dart';
import '../../services/quran_service.dart';
import '../../models/quran_models.dart';
import 'package:hijri/hijri_calendar.dart';

import 'package:flutter/foundation.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();

  /// Static method to save reading progress - call this from Quran page
  static Future<void> saveQuranProgress({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_read_surah', surahNumber);
      await prefs.setInt('last_read_ayah', ayahNumber);
      await prefs.setBool('has_read_quran', true);
      await prefs.setString(
        'last_read_timestamp',
        DateTime.now().toIso8601String(),
      );
      debugPrint(
        '📖 Saved Quran progress: Surah $surahNumber, Ayat $ayahNumber',
      );
    } catch (e) {
      debugPrint('❌ Error saving Quran progress: $e');
    }
  }
}

int _searchTextIndex = 0;
Timer? _searchTextTimer;
final List<String> _searchSuggestions = [
  'Kempen Potong Lima...',
  'Waqaf Quran...',
  'Set Persalinan Akhir...',
  'Infak Subuh...',
];

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _carouselIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final ScrollController _scrollController = ScrollController();
  final ScrollController _prayerTimesScrollController = ScrollController();
  // Carousel images moved to class-level so timers can access length
  final List<String> _carouselImages = [
    'assets/images/KP5R3.png', //Kempen Potong Lima
    'assets/images/IST2.png', //Infak Subuh
    'assets/images/SPAT1.png', //Ifak Set Persalihan Akhir
    'assets/images/WQT1.png', //Waqaf Quran
  ];
  Timer? _carouselTimer; // Auto-scroll timer for the carousel
  Timer? _prayerTimesScrollTimer; // Auto-scroll timer for prayer times
  String _nextPrayerText = 'Loading...';
  Timer? _timer;
  Timer? _countdownTimer;
  Duration _countdown = Duration.zero;
  List<Map<String, dynamic>> _prayerTimes = [];
  bool _isPrayerTimesLoading = true;
  Position? _lastKnownPosition; // Track last location
  String _currentLocationName = 'Malaysia'; // Track current location name

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialLocationName();
    // Initialize notifications first, then load prayer times
    // This ensures notification permission is requested before scheduling
    _initializeNotifications().then((_) {
      _loadPrayerTimes();
    });
    _startTimer();
    _startCarouselTimer();
    _startSearchTextAnimation(); // Tambah ini untuk mulakan animasi teks
    _startPrayerTimesAutoScroll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _carouselTimer?.cancel();
    _countdownTimer?.cancel();
    _searchTextTimer?.cancel(); // Tambah ini untuk batalkan timer teks
    _prayerTimesScrollTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    _prayerTimesScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App resumed, check if location has changed significantly
      _checkLocationChangeAndReload();
    }
  }

  Future<void> _checkLocationChangeAndReload() async {
    try {
      Position? currentPosition = await PrayerTimesService.getCurrentLocation();

      if (currentPosition == null) return;

      // If we have no previous position, just reload
      if (_lastKnownPosition == null) {
        await _loadPrayerTimes();
        // After loading, force reschedule notifications with latest data
        if (_prayerTimes.isNotEmpty) {
          final locationName = await PrayerTimesService.getLocationName(
            currentPosition.latitude,
            currentPosition.longitude,
          );
          debugPrint(
            '[Homepage] Forcing notification reschedule after initial location load.',
          );
          await NotificationService().forceReschedule(
            _prayerTimes,
            locationName: locationName,
          );
        }
        return;
      }

      // Calculate distance between last and current position
      double distanceInMeters = Geolocator.distanceBetween(
        _lastKnownPosition!.latitude,
        _lastKnownPosition!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      // If moved more than 5km, reload prayer times
      if (distanceInMeters > 5000) {
        debugPrint(
          '📍 Location changed by ${(distanceInMeters / 1000).toStringAsFixed(1)}km, reloading prayer times...',
        );
        await _loadPrayerTimes();
        // After loading, force reschedule notifications with latest data
        if (_prayerTimes.isNotEmpty) {
          final locationName = await PrayerTimesService.getLocationName(
            currentPosition.latitude,
            currentPosition.longitude,
          );
          debugPrint(
            '[Homepage] Forcing notification reschedule after location change.',
          );
          await NotificationService().forceReschedule(
            _prayerTimes,
            locationName: locationName,
          );
        }
        // Update widget with new location
        await WidgetService.updateWidget();
      }
    } catch (e) {
      debugPrint('Error checking location change: $e');
    }
  }

  void _startSearchTextAnimation() {
    _searchTextTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _searchTextIndex = (_searchTextIndex + 1) % _searchSuggestions.length;
        });
      }
    });
  }

  void _startPrayerTimesAutoScroll() {
    // Cancel any existing timer first
    _prayerTimesScrollTimer?.cancel();

    // Wait a bit before starting to ensure widget is built
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // Keep checking until scroll controller is ready (max 5 attempts)
      int attempts = 0;
      Timer.periodic(const Duration(milliseconds: 500), (checkTimer) {
        attempts++;

        if (!mounted) {
          checkTimer.cancel();
          return;
        }

        if (_prayerTimesScrollController.hasClients || attempts >= 5) {
          checkTimer.cancel();

          if (!_prayerTimesScrollController.hasClients) return;

          // Now start the actual auto-scroll timer
          _prayerTimesScrollTimer = Timer.periodic(const Duration(seconds: 3), (
            timer,
          ) async {
            if (!mounted || !_prayerTimesScrollController.hasClients) {
              timer.cancel();
              return;
            }

            final maxScroll =
                _prayerTimesScrollController.position.maxScrollExtent;
            final currentScroll = _prayerTimesScrollController.offset;

            // If at the end, scroll back to start
            if (currentScroll >= maxScroll - 10) {
              await _prayerTimesScrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
              );
            } else {
              // Scroll to next item (approximately 100 pixels)
              final nextScroll = (currentScroll + 100).clamp(0.0, maxScroll);
              await _prayerTimesScrollController.animateTo(
                nextScroll,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      });
    });
  }

  void _startCarouselTimer() {
    // Cancel existing timer if any
    _carouselTimer?.cancel();
    // Auto-advance every 4 seconds
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_pageController.hasClients && _carouselImages.isNotEmpty) {
        final nextPage = (_carouselIndex + 1) % _carouselImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _resetCarouselTimer() {
    // Reset the auto-scroll timer when user interacts
    _carouselTimer?.cancel();
    _startCarouselTimer();
  }

  void _startTimer() {
    // Check for next prayer update every minute (not every second to avoid recreating countdown)
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateNextPrayer();
    });
  }

  /// Load initial location name from SharedPreferences
  Future<void> _loadInitialLocationName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationName = prefs.getString('current_location_name');
      if (locationName != null && mounted) {
        setState(() {
          _currentLocationName = locationName;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading initial location name: $e');
    }
  }

  /// Initialize notification service and request permission on first install
  Future<void> _initializeNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequestedPermission =
          prefs.getBool('notification_permission_requested') ?? false;

      if (!hasRequestedPermission) {
        debugPrint(
          '🔔 First install detected - requesting notification permission',
        );
        final notificationService = NotificationService();
        await notificationService.initialize();
        final granted = await notificationService.requestPermission();

        if (granted) {
          debugPrint('✅ Notification permission granted on first install');
        } else {
          debugPrint('⚠️ Notification permission denied on first install');
        }

        // Mark that we've requested permission
        await prefs.setBool('notification_permission_requested', true);
      } else {
        debugPrint('ℹ️ Notification permission already requested previously');
      }
    } catch (e) {
      debugPrint('❌ Error initializing notifications on homepage: $e');
    }
  }

  Future<void> _loadPrayerTimes() async {
    _countdownTimer?.cancel(); // Cancel any existing timer
    if (mounted) {
      setState(() {
        _isPrayerTimesLoading = true;
      });
    }
    try {
      Position? position = await PrayerTimesService.getCurrentLocation();
      if (position != null) {
        // Store current position for location change detection
        _lastKnownPosition = position;

        final prayerData = await PrayerTimesService.getPrayerTimesForMalaysia(
          position.latitude,
          position.longitude,
        );

        if (prayerData != null && prayerData['code'] == 200) {
          if (mounted) {
            setState(() {
              _prayerTimes = PrayerTimesService.parsePrayerTimes(prayerData);
              _isPrayerTimesLoading = false;
            });
          }
          _updateNextPrayer();

          // Update location name in SharedPreferences and state
          final locationName = await PrayerTimesService.getLocationName(
            position.latitude,
            position.longitude,
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_location_name', locationName);
          if (mounted) {
            setState(() {
              _currentLocationName = locationName;
            });
          }
          debugPrint('📍 Location updated: $locationName');

          // Update widget with fresh prayer times
          await WidgetService.updateWidget();

          // Schedule notifications after prayer times are loaded
          _scheduleNotificationsIfNeeded(position);
        } else {
          // API failed, set default countdown
          if (mounted) {
            setState(() {
              _isPrayerTimesLoading = false;
            });
          }
          _setDefaultCountdown();
        }
      } else {
        // Location not available, set default countdown
        if (mounted) {
          setState(() {
            _isPrayerTimesLoading = false;
          });
        }
        _setDefaultCountdown();
      }
    } catch (e) {
      debugPrint('Error loading prayer times for homepage: $e');
      // Error occurred, set default countdown
      if (mounted) {
        setState(() {
          _isPrayerTimesLoading = false;
        });
      }
      _setDefaultCountdown();
    }
  }

  /// Schedule notifications if needed (on first install or if not scheduled for 7 days)
  /// Now fetches prayer times for 7 days and schedules accurate times
  Future<void> _scheduleNotificationsIfNeeded(Position position) async {
    try {
      if (_prayerTimes.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final hasRequestedPermission =
          prefs.getBool('notification_permission_requested') ?? false;

      if (!hasRequestedPermission) {
        // Permission not requested yet, skip scheduling
        return;
      }

      // Check if prayer zone changed since last schedule
      // This is more accurate than distance because nearby areas can have different zones
      // (e.g., Damansara/PJ is SGR01, KL is WLY01 even though they're close)
      final lastScheduledZone = prefs.getString('last_scheduled_zone');
      final currentZone = PrayerTimesService.getZoneFromCoordinates(
        position.latitude,
        position.longitude,
      );

      bool locationChanged = false;
      if (lastScheduledZone != null && lastScheduledZone != currentZone) {
        locationChanged = true;
        debugPrint(
          '🌍 Prayer zone changed: $lastScheduledZone → $currentZone - forcing notification reschedule',
        );
      }

      // Check if schedule is still valid (not expired or close to expiry)
      final notificationService = NotificationService();
      final needsReschedule = await notificationService.shouldReschedule();

      if (!needsReschedule && !locationChanged) {
        debugPrint('ℹ️ 7-day notification schedule still valid');
        return;
      }

      debugPrint('📅 Fetching prayer times for next 7 days...');

      // Get location name
      final locationName = await PrayerTimesService.getLocationName(
        position.latitude,
        position.longitude,
      );

      // Fetch prayer times for the next 7 days
      List<Map<String, dynamic>> allPrayerTimes = [];
      final now = DateTime.now();

      for (int day = 0; day < 7; day++) {
        final targetDate = now.add(Duration(days: day));
        final dateStr =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

        debugPrint('📆 Fetching prayer times for day +$day ($dateStr)...');

        final prayerData = await PrayerTimesService.getPrayerTimesForMalaysia(
          position.latitude,
          position.longitude,
          forDate: targetDate,
        );

        if (prayerData != null && prayerData['code'] == 200) {
          final dayPrayerTimes = PrayerTimesService.parsePrayerTimes(
            prayerData,
          );

          // Add day offset to each prayer time for identification
          for (var prayer in dayPrayerTimes) {
            final prayerWithDay = Map<String, dynamic>.from(prayer);
            prayerWithDay['dayOffset'] = day;
            prayerWithDay['date'] = dateStr;
            allPrayerTimes.add(prayerWithDay);
          }

          debugPrint(
            '  ✅ Fetched ${dayPrayerTimes.length} prayers for $dateStr',
          );
        } else {
          debugPrint('  ⚠️ Failed to fetch prayer times for day +$day');
        }
      }

      if (allPrayerTimes.isEmpty) {
        debugPrint('❌ No prayer times fetched for 7 days - cannot schedule');
        return;
      }

      debugPrint('🎯 Total prayers fetched: ${allPrayerTimes.length}');

      // Schedule notifications for all 7 days with accurate times
      await notificationService.schedule7DaysPrayerNotifications(
        allPrayerTimes,
        locationName: locationName,
      );

      // Cache today's prayer times for widget and background task
      await notificationService.cachePrayerTimesMinimal(_prayerTimes);

      // Save the location, coordinates, and prayer zone that were used for scheduling
      await prefs.setString('last_scheduled_location', locationName);
      await prefs.setString('last_scheduled_zone', currentZone);
      await prefs.setDouble('last_scheduled_lat', position.latitude);
      await prefs.setDouble('last_scheduled_lng', position.longitude);

      // Update widget with fresh prayer times
      await WidgetService.forceRefreshWidget();
      debugPrint('🔄 Widget force refreshed from homepage');

      debugPrint(
        '✅ 7-day notifications scheduled successfully for $locationName',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling 7-day notifications: $e');
    }
  }

  void _setDefaultCountdown() {
    if (mounted) {
      setState(() {
        _nextPrayerText = 'Tidak dapat memuatkan waktu solat';
        _countdown = Duration.zero;
      });
    }
    // Stop any existing countdown timer
    _countdownTimer?.cancel();
  }

  void _updateNextPrayer() {
    if (_prayerTimes.isEmpty) return;

    final nextPrayer = PrayerTimesService.getNextPrayer(_prayerTimes);
    if (nextPrayer != null && mounted) {
      // Expect nextPrayer contains 'name', 'time' (12-hour), and 'time24' (24-hour)
      final name = nextPrayer['name'] ?? '';
      final timeStr = nextPrayer['time'] ?? '';
      final time24 =
          nextPrayer['time24'] ?? timeStr; // Use 24-hour format for calculation

      debugPrint('Next prayer: $name at $timeStr (24h: $time24)'); // Debug log

      // Check if this is a new prayer (name or time changed)
      final newPrayerText = 'Solat Seterusnya: $name - $timeStr';
      final bool isPrayerChanged = _nextPrayerText != newPrayerText;

      setState(() {
        _nextPrayerText = newPrayerText;
      });

      // Update widget when prayer changes
      if (isPrayerChanged) {
        debugPrint('🔄 Prayer changed to $name, updating widget...');
        WidgetService.updateWidget();
      }

      // Only recreate countdown timer if prayer changed or timer doesn't exist
      if (isPrayerChanged ||
          _countdownTimer == null ||
          !_countdownTimer!.isActive) {
        // Parse time24 (24-hour format) and start countdown
        try {
          final parts = time24.split(':');
          if (parts.length >= 2) {
            final int hour = int.parse(parts[0]);
            final int minute = int.parse(parts[1]);
            DateTime now = DateTime.now();
            DateTime target = DateTime(
              now.year,
              now.month,
              now.day,
              hour,
              minute,
            );
            if (target.isBefore(now)) {
              target = target.add(const Duration(days: 1));
            }

            // initialize countdown and total duration for progress
            _countdownTimer?.cancel();
            final initialCountdown = target.difference(now);
            debugPrint(
              'Starting new countdown: ${initialCountdown.inSeconds} seconds (${_formatDuration(initialCountdown)})',
            ); // Debug log

            setState(() {
              _countdown = initialCountdown;
            });

            _countdownTimer = Timer.periodic(const Duration(seconds: 1), (
              timer,
            ) {
              if (!mounted) return;
              final remaining = target.difference(DateTime.now());
              if (remaining.inSeconds <= 0) {
                timer.cancel();
                // refresh prayer times for next prayer
                debugPrint(
                  '⏰ Prayer time reached, reloading prayer times and updating widget...',
                );
                _loadPrayerTimes(); // This will call updateWidget when complete
                return;
              }
              setState(() {
                _countdown = remaining;
              });
            });
          }
        } catch (e) {
          debugPrint('Error parsing prayer time: $e'); // Debug log
        }
      }
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours >= 24) {
      final days = d.inDays;
      return '${days}d ${hours}:${minutes}:${seconds}';
    }
    return '$hours:$minutes:$seconds';
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Already on Homepage
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const ProgramPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const WaqafPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const InboxPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const AkaunPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeaderSection(context),
            const SizedBox(height: 12),
            // Upcoming Prayer Card
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
              ),
              child:
                  _isPrayerTimesLoading
                      ? _buildUpcomingPrayerSkeletonLoading(context)
                      : _buildUpcomingPrayerCard(context),
            ),
            const SizedBox(height: 16),
            // Today's Prayer Times Card
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
              ),
              child:
                  _isPrayerTimesLoading
                      ? _buildTodayPrayerTimesSkeletonLoading(context)
                      : (_prayerTimes.isNotEmpty
                          ? _buildTodayPrayerTimesCard(context)
                          : const SizedBox.shrink()),
            ),
            SizedBox(height: screenHeight * 0.04),
            // Menu Section (includes Quran tracker)
            _buildIconMenu(context),
            SizedBox(height: screenHeight * 0.04),

            // Programs Section
            _buildMainCarousel(context),
            SizedBox(height: screenHeight * 0.06),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        scrollController: _scrollController,
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double headerHeight =
        (screenHeight * 0.28)
            .clamp(240.0, 320.0)
            .toDouble(); //waveclipper length

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Header Background with U-shaped curve
        Container(
          height: headerHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.95),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        // Decorative elements
        IgnorePointer(
          child: SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned(
                  top: -60,
                  right: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withOpacity(0.04),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content container with SafeArea
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.05,
              16,
              screenWidth * 0.05,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar: Greeting & Notification
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assalamualaikum,',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.85),
                              fontSize: screenWidth * 0.037,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Selamat Datang',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: screenWidth * 0.062,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.search_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quran Tracker under greeting
                _buildQuranTrackerHeader(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colorScheme.primary, size: 18),
            const SizedBox(width: 14),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _searchSuggestions[_searchTextIndex],
                    key: ValueKey<int>(_searchTextIndex),
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingPrayerCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Parse prayer info
    String nextPrayerName = '';
    String nextPrayerTime = '';
    if (_nextPrayerText.contains(':') &&
        _nextPrayerText != 'Loading...' &&
        _nextPrayerText != 'Prayer times unavailable') {
      final cleaned = _nextPrayerText.replaceAll('Solat Seterusnya: ', '');
      final parts = cleaned.split(' - ');
      if (parts.length == 2) {
        nextPrayerName = parts[0].trim();
        nextPrayerTime = parts[1].trim();
      }
    }

    // Get current date
    final now = DateTime.now();
    final months = [
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
    final currentDate = '${now.day} ${months[now.month - 1]} ${now.year}';

    // Get Hijri date
    const hijriMonths = [
      'Muharram',
      'Safar',
      "Rabi'ulawal",
      "Rabi'ulakhir",
      'Jamadilawwal',
      'Jamadilakhir',
      'Rejab',
      "Sha'ban",
      'Ramadan',
      'Shawwal',
      'Zulkaedah',
      'Zulhijjah',
    ];
    final hijriCalendar = HijriCalendar.fromDate(now);
    final hijriMonthName = hijriMonths[hijriCalendar.hMonth - 1];
    final hijriDate =
        '${hijriCalendar.hDay} $hijriMonthName ${hijriCalendar.hYear}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row with both Gregorian and Hijri
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$currentDate / $hijriDate',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Main prayer info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SOLAT SETERUSNYA',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nextPrayerName.isNotEmpty ? nextPrayerName : 'MEMUAT...',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextPrayerTime.isNotEmpty ? nextPrayerTime : '--:--',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Baki Masa',
                      style: TextStyle(
                        color: colorScheme.onPrimary.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _countdown.inSeconds > 0
                          ? _formatDuration(_countdown)
                          : '--:--',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Location row
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 13,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                _currentLocationName,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPrayerColor(String prayerName) {
    // Return colors based on real-life time of day
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        return const Color(0xFF9C27B0); // Purple for pre-dawn
      case 'syuruk':
        return const Color(0xFFFF6F00); // Orange for sunrise
      case 'zohor':
        return const Color(0xFFFFC107); // Golden yellow for noon
      case 'asar':
        return const Color(0xFFFF9800); // Amber for afternoon
      case 'maghrib':
        return const Color(0xFFE91E63); // Pink/red for sunset
      case 'isyak':
        return const Color(0xFF3F51B5); // Indigo for night
      default:
        return const Color(0xFF0284C7); // Default blue
    }
  }

  Widget _buildLastReadQuranCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getLastReadQuran(),
      builder: (context, snapshot) {
        final lastRead = snapshot.data ?? {};
        final surahName = lastRead['surahName'] ?? 'Al-Fatihah';
        final ayahNumber = lastRead['ayahNumber'] ?? 1;
        final progress = lastRead['progress'] ?? 0.0;
        final hasRead = lastRead['hasRead'] ?? false;

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              SmoothPageRoute(page: const QuranPage()),
            );
            // Refresh the card when returning from Quran page
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00897B).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00897B).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: const Color(0xFF00897B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surahName,
                            style: TextStyle(
                              color: const Color(0xFF00897B),
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ayat $ayahNumber',
                            style: TextStyle(
                              color: const Color(0xFF00897B).withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00897B).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Color(0xFF00897B),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF00897B).withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00897B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Action button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00897B).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasRead
                            ? Icons.play_arrow_rounded
                            : Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasRead ? 'Teruskan' : 'Mula Baca',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getLastReadQuran() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSurahNumber = prefs.getInt('last_read_surah') ?? 1;
      final lastAyahNumber = prefs.getInt('last_read_ayah') ?? 1;
      final hasRead = prefs.getBool('has_read_quran') ?? false;

      // Load actual Surah from API (same source as quranpage)
      final allSurahs = await QuranService.getAllSurahs();
      Surah? lastSurah;
      if (allSurahs.isNotEmpty) {
        try {
          lastSurah = allSurahs.firstWhere(
            (surah) => surah.number == lastSurahNumber,
          );
        } catch (e) {
          lastSurah = allSurahs.first;
        }
      }

      // Calculate progress (simple: surah number / 114)
      final progress = lastSurahNumber / 114.0;

      return {
        'surahName': lastSurah?.englishName ?? 'Al-Fatihah',
        'surahNumber': lastSurahNumber,
        'ayahNumber': lastAyahNumber,
        'progress': progress,
        'hasRead': hasRead,
      };
    } catch (e) {
      debugPrint('Error getting last read Quran: $e');
      return {
        'surahName': 'Al-Fatihah',
        'surahNumber': 1,
        'ayahNumber': 1,
        'progress': 0.0,
        'hasRead': false,
      };
    }
  }

  Widget _buildIconMenu(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu Utama',
                    style: TextStyle(
                      fontSize: screenWidth * 0.052,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onBackground,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pilih perkhidmatan',
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => OthersMenuPage.show(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: screenWidth * 0.034,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.05),

          // New Layout: 2 boxes top (Waktu Solat + Quran), 3 boxes bottom (Kiblat + Tasbih + Hadis 40)
          Column(
            children: [
              // Top Row: Waktu Solat (50%) + Quran (50%)
              Row(
                children: [
                  Expanded(
                    child: _buildMediumMenuCard(
                      context,
                      title: 'Waktu Solat',
                      iconPath: 'assets/icons/menu/waktu_solat.svg',
                      backgroundColor: const Color(
                        0xFF6750A4,
                      ), // M3 Primary Purple
                      iconColor: const Color(0xFF6750A4),
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const PrayerTimesPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMediumMenuCard(
                      context,
                      title: 'Al-Quran',
                      iconPath: 'assets/icons/menu/quran_new.svg',
                      backgroundColor: const Color(0xFF00897B), // M3 Teal
                      iconColor: const Color(0xFF00695C),
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const QuranPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom Row: Arah Kiblat (33%) + Tasbih (33%) + Hadis 40 (33%)
              Row(
                children: [
                  Expanded(
                    child: _buildSmallMenuCard(
                      context,
                      title: 'Arah Kiblat',
                      iconPath: 'assets/icons/menu/kiblat.svg',
                      backgroundColor: const Color(0xFF6A7BA2), // Slate Blue
                      iconColor: const Color(0xFF5A6B92),
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const KiblatPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallMenuCard(
                      context,
                      title: 'Tasbih',
                      iconPath: 'assets/icons/menu/tasbih.svg',
                      backgroundColor: const Color(0xFFC2185B), // M3 Pink
                      iconColor: const Color(0xFFAD1457),
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const ZikirCounterPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallMenuCard(
                      context,
                      title: 'Doa Harian',
                      iconPath: 'assets/icons/menu/doa.svg',
                      backgroundColor: const Color(
                        0xFFFF6B6B,
                      ), // Vibrant Coral Red
                      iconColor: const Color(0xFFE53935),
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const DoaHarianPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeMenuCard(
    BuildContext context, {
    required String title,
    required String iconPath,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Material 3 approach: use surface colors with tonal variations
    final surfaceColor =
        isDark
            ? colorScheme.surfaceContainerHighest
            : backgroundColor.withOpacity(0.15);

    final onSurfaceColor =
        isDark ? colorScheme.onSurface : const Color(0xFF1C1B1F);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isDark
                  ? colorScheme.outline.withOpacity(0.2)
                  : iconColor.withOpacity(0.12),
          width: 1,
        ),
      ),
      color: surfaceColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon with filled tonal container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? iconColor.withOpacity(0.2)
                          : iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onSurfaceColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jadual solat harian',
                      style: TextStyle(
                        color:
                            isDark
                                ? colorScheme.onSurfaceVariant
                                : const Color(0xFF49454F),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color:
                    isDark
                        ? colorScheme.onSurfaceVariant
                        : const Color(0xFF79747E),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Extra Large Card - Full width with prominent display
  Widget _buildExtraLargeMenuCard(
    BuildContext context, {
    required String title,
    required String iconPath,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
        isDark
            ? colorScheme.surfaceContainerHighest
            : backgroundColor.withOpacity(0.15);

    final onSurfaceColor =
        isDark ? colorScheme.onSurface : const Color(0xFF1C1B1F);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color:
              isDark
                  ? colorScheme.outline.withOpacity(0.2)
                  : iconColor.withOpacity(0.12),
          width: 1,
        ),
      ),
      color: surfaceColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? iconColor.withOpacity(0.2)
                          : iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onSurfaceColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lihat jadual waktu solat lengkap',
                      style: TextStyle(
                        color:
                            isDark
                                ? colorScheme.onSurfaceVariant
                                : const Color(0xFF49454F),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: iconColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Compact Square Card - Small vertical card
  Widget _buildCompactMenuCard(
    BuildContext context, {
    required String title,
    required String iconPath,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
        isDark
            ? colorScheme.surfaceContainerHighest
            : backgroundColor.withOpacity(0.15);

    final onSurfaceColor =
        isDark ? colorScheme.onSurface : const Color(0xFF1C1B1F);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isDark
                  ? colorScheme.outline.withOpacity(0.2)
                  : iconColor.withOpacity(0.12),
          width: 1,
        ),
      ),
      color: surfaceColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? iconColor.withOpacity(0.2)
                          : iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 20,
                    height: 20,
                    color: iconColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: onSurfaceColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Cari arah',
                style: TextStyle(
                  color:
                      isDark
                          ? colorScheme.onSurfaceVariant
                          : const Color(0xFF49454F),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Wide Card - Horizontal card with more width
  Widget _buildWideMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String iconPath,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
        isDark
            ? colorScheme.surfaceContainerHighest
            : backgroundColor.withOpacity(0.15);

    final onSurfaceColor =
        isDark ? colorScheme.onSurface : const Color(0xFF1C1B1F);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isDark
                  ? colorScheme.outline.withOpacity(0.2)
                  : iconColor.withOpacity(0.12),
          width: 1,
        ),
      ),
      color: surfaceColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? iconColor.withOpacity(0.2)
                              : iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        iconPath,
                        width: 21,
                        height: 21,
                        color: iconColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color:
                        isDark
                            ? colorScheme.onSurfaceVariant
                            : const Color(0xFF79747E),
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: onSurfaceColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                      isDark
                          ? colorScheme.onSurfaceVariant
                          : const Color(0xFF49454F),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Horizontal Full Width Card - Compact horizontal layout
  Widget _buildHorizontalMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String iconPath,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
        isDark
            ? colorScheme.surfaceContainerHighest
            : backgroundColor.withOpacity(0.15);

    final onSurfaceColor =
        isDark ? colorScheme.onSurface : const Color(0xFF1C1B1F);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isDark
                  ? colorScheme.outline.withOpacity(0.2)
                  : iconColor.withOpacity(0.12),
          width: 1,
        ),
      ),
      color: surfaceColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? iconColor.withOpacity(0.2)
                          : iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 20,
                    height: 20,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onSurfaceColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            isDark
                                ? colorScheme.onSurfaceVariant
                                : const Color(0xFF49454F),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color:
                    isDark
                        ? colorScheme.onSurfaceVariant
                        : const Color(0xFF79747E),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediumMenuCard(
    BuildContext context, {
    required String title,
    required String iconPath,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Solid color background
    final surfaceColor =
        isDark ? colorScheme.surfaceContainerHighest : backgroundColor;

    final onSurfaceColor = isDark ? colorScheme.onSurface : Colors.white;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isDark
                  ? colorScheme.outline.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    // Text at top-left
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: onSurfaceColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.15,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Icon at bottom-right
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: SvgPicture.asset(iconPath, width: 64, height: 64),
                    ),
                    // Spacer to maintain card height
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallMenuCard(
    BuildContext context, {
    required String title,
    required String iconPath,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Solid color background
    final surfaceColor =
        isDark ? colorScheme.surfaceContainerHighest : backgroundColor;

    final onSurfaceColor = isDark ? colorScheme.onSurface : Colors.white;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isDark
                  ? colorScheme.outline.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: [
                    // Text at top-left
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Text(
                        title,
                        style: TextStyle(
                          color: onSurfaceColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Icon at bottom-right
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: SvgPicture.asset(iconPath, width: 52, height: 52),
                    ),
                    // Spacer to maintain card height
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCarousel(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    // Use class-level _carouselImages so timers and other methods can access
    final List<String> carouselImages = _carouselImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peluang Beramal',
                    style: TextStyle(
                      fontSize: screenWidth * 0.052,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onBackground,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Program & kempen terkini',
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _onTabTapped(1),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lihat Program',
                  style: TextStyle(
                    fontSize: screenWidth * 0.034,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: screenWidth * 0.05),
        SizedBox(
          height: screenHeight * 0.22,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _carouselIndex = index;
              });
              // reset timer when user swipes manually
              _resetCarouselTimer();
            },
            itemCount: carouselImages.length,
            itemBuilder: (context, index) {
              return _buildCarouselCard(carouselImages[index], context);
            },
          ),
        ),
        SizedBox(height: screenHeight * 0.015),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(carouselImages.length, (index) {
              // fixed pixel sizes avoid tiny overflow on small widths
              const double activeWidth = 24.0;
              const double inactiveWidth = 8.0;
              const double dotHeight = 8.0;
              const double horizontalGap = 6.0;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(
                  horizontal: horizontalGap / 2,
                ),
                width: _carouselIndex == index ? activeWidth : inactiveWidth,
                height: dotHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color:
                      _carouselIndex == index
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.2),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(String imagePath, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayPrayerTimesCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Waktu Solat Hari Ini',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate if we need compact mode
              final availableWidth = constraints.maxWidth;
              final isCompact = availableWidth < 350;

              // Determine next prayer
              final nextPrayer = PrayerTimesService.getNextPrayer(_prayerTimes);
              final nextPrayerName = nextPrayer?['name'] ?? '';

              return Row(
                children:
                    _prayerTimes.map((prayer) {
                      final prayerName = prayer['name'] ?? '';
                      final prayerTime = prayer['time'] ?? '';
                      final prayerTime24 = prayer['time24'] ?? '';

                      // Check if this prayer time has passed
                      bool hasPassed = false;
                      try {
                        final parts = prayerTime24.split(':');
                        if (parts.length >= 2) {
                          final hour = int.parse(parts[0]);
                          final minute = int.parse(parts[1]);
                          final prayerDateTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            hour,
                            minute,
                          );
                          hasPassed = now.isAfter(prayerDateTime);
                        }
                      } catch (e) {
                        // Ignore parsing errors
                      }

                      // Check if this is the next prayer
                      final isNextPrayer = prayerName == nextPrayerName;

                      // Get icon for prayer
                      IconData prayerIcon = _getPrayerIcon(prayerName);

                      return Expanded(
                        child: Transform.translate(
                          offset:
                              isNextPrayer ? const Offset(0, -4) : Offset.zero,
                          child: Transform.scale(
                            scale: isNextPrayer ? 1.08 : 1.0,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: isCompact ? 1.5 : 2.5,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 3 : 5,
                                vertical: isCompact ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getPrayerColor(prayerName).withOpacity(
                                  isNextPrayer
                                      ? 0.18
                                      : (hasPassed ? 0.08 : 0.12),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _getPrayerColor(
                                    prayerName,
                                  ).withOpacity(
                                    isNextPrayer
                                        ? 0.6
                                        : (hasPassed ? 0.2 : 0.3),
                                  ),
                                  width: isNextPrayer ? 1.5 : 0.8,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    prayerIcon,
                                    size: isCompact ? 14 : 16,
                                    color:
                                        hasPassed
                                            ? colorScheme.onSurface.withOpacity(
                                              0.35,
                                            )
                                            : _getPrayerColor(
                                              prayerName,
                                            ).withOpacity(
                                              isNextPrayer ? 1.0 : 0.9,
                                            ),
                                  ),
                                  SizedBox(height: isCompact ? 2 : 3),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      prayerName,
                                      style: TextStyle(
                                        fontSize: isCompact ? 8 : 9,
                                        fontWeight:
                                            isNextPrayer
                                                ? FontWeight.w900
                                                : FontWeight.bold,
                                        color:
                                            hasPassed
                                                ? colorScheme.onSurface
                                                    .withOpacity(0.4)
                                                : _getPrayerColor(prayerName),
                                        letterSpacing: -0.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 1 : 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      prayerTime,
                                      style: TextStyle(
                                        fontSize: isCompact ? 9 : 10,
                                        fontWeight:
                                            isNextPrayer
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                        color:
                                            hasPassed
                                                ? colorScheme.onSurface
                                                    .withOpacity(0.35)
                                                : colorScheme.onSurface
                                                    .withOpacity(0.85),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        return Icons.wb_twilight;
      case 'syuruk':
        return Icons.wb_sunny;
      case 'zohor':
        return Icons.wb_cloudy;
      case 'asar':
        return Icons.wb_sunny;
      case 'maghrib':
        return Icons.brightness_3;
      case 'isyak':
        return Icons.brightness_2;
      default:
        return Icons.access_time;
    }
  }

  Widget _buildUpcomingPrayerSkeletonLoading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and location row
          Row(
            children: [
              _buildShimmerBox(
                width: 100,
                height: 12,
                colorScheme: colorScheme,
                borderRadius: 6,
              ),
              const Spacer(),
              _buildShimmerBox(
                width: 80,
                height: 12,
                colorScheme: colorScheme,
                borderRadius: 6,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Main prayer info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(
                      width: 120,
                      height: 24,
                      colorScheme: colorScheme,
                      borderRadius: 8,
                    ),
                    const SizedBox(height: 12),
                    _buildShimmerBox(
                      width: 100,
                      height: 28,
                      colorScheme: colorScheme,
                      borderRadius: 8,
                    ),
                    const SizedBox(height: 8),
                    _buildShimmerBox(
                      width: 60,
                      height: 18,
                      colorScheme: colorScheme,
                      borderRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildShimmerBox(
                width: 90,
                height: 70,
                colorScheme: colorScheme,
                borderRadius: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesSkeletonLoading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.today_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              _buildShimmerBox(
                width: 150,
                height: 16,
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                6,
                (index) => Padding(
                  padding: EdgeInsets.only(right: index == 5 ? 0 : 10),
                  child: _buildShimmerBox(
                    width: 100,
                    height: 36,
                    colorScheme: colorScheme,
                    borderRadius: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPrayerTimesSkeletonLoading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBox(
                width: 16,
                height: 16,
                colorScheme: colorScheme,
                borderRadius: 4,
              ),
              const SizedBox(width: 8),
              _buildShimmerBox(
                width: 150,
                height: 14,
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              6,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: _buildShimmerBox(
                    width: double.infinity,
                    height: 70,
                    colorScheme: colorScheme,
                    borderRadius: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required ColorScheme colorScheme,
    double borderRadius = 8,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted && _isPrayerTimesLoading) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildQuranTrackerHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getLastReadQuran(),
      builder: (context, snapshot) {
        final lastRead = snapshot.data ?? {};
        final surahName = lastRead['surahName'] ?? 'Al-Fatihah';
        final ayahNumber = lastRead['ayahNumber'] ?? 1;
        final hasRead = lastRead['hasRead'] ?? false;

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              SmoothPageRoute(page: const QuranPage()),
            );
            // Refresh when returning from Quran page
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surahName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ayat $ayahNumber',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withOpacity(0.85),
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasRead
                            ? Icons.play_arrow_rounded
                            : Icons.auto_stories_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasRead ? 'Teruskan' : 'Mula',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

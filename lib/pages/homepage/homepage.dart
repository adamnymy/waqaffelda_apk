import 'package:flutter/material.dart';
import 'dart:async';
import '../../navbar.dart';
import '../prayertimes/prayertimes.dart';
import '../../services/prayer_times_service.dart';
import '../../services/notification_service.dart';
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

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

int _searchTextIndex = 0;
Timer? _searchTextTimer;
final List<String> _searchSuggestions = [
  'Kempen Potong Lima...',
  'Waqaf Quran...',
  'Set Persalinan Akhir...',
  'Infak Subuh...',
];

class _HomepageState extends State<Homepage> {
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

  @override
  void initState() {
    super.initState();
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

  /// Initialize notification service and request permission on first install
  Future<void> _initializeNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequestedPermission =
          prefs.getBool('notification_permission_requested') ?? false;

      if (!hasRequestedPermission) {
        print('🔔 First install detected - requesting notification permission');
        final notificationService = NotificationService();
        await notificationService.initialize();
        final granted = await notificationService.requestPermission();

        if (granted) {
          print('✅ Notification permission granted on first install');
        } else {
          print('⚠️ Notification permission denied on first install');
        }

        // Mark that we've requested permission
        await prefs.setBool('notification_permission_requested', true);
      } else {
        print('ℹ️ Notification permission already requested previously');
      }
    } catch (e) {
      print('❌ Error initializing notifications on homepage: $e');
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
      print('Error loading prayer times for homepage: $e');
      // Error occurred, set default countdown
      if (mounted) {
        setState(() {
          _isPrayerTimesLoading = false;
        });
      }
      _setDefaultCountdown();
    }
  }

  /// Schedule notifications if needed (on first install or if not scheduled today)
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

      // Check if already scheduled for today
      final lastScheduledDate = prefs.getString('last_scheduled_date');
      final today = DateTime.now().toIso8601String().split('T')[0];

      if (lastScheduledDate == today) {
        print('ℹ️ Notifications already scheduled for today');
        return;
      }

      print('📅 Scheduling notifications with user location...');

      // Get location name
      final locationName = await PrayerTimesService.getLocationName(
        position.latitude,
        position.longitude,
      );

      // Save location to SharedPreferences
      await prefs.setString('current_location_name', locationName);

      // Schedule notifications
      final notificationService = NotificationService();
      await notificationService.schedulePrayerNotificationsWithTracking(
        _prayerTimes,
        locationName: locationName,
      );

      // Cache prayer times for background rescheduler
      await notificationService.cachePrayerTimesMinimal(_prayerTimes);

      // Save the location that was used for scheduling
      await prefs.setString('last_scheduled_location', locationName);

      print('✅ Notifications scheduled successfully for $locationName');
    } catch (e) {
      print('❌ Error scheduling notifications: $e');
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

      print('Next prayer: $name at $timeStr (24h: $time24)'); // Debug log

      // Check if this is a new prayer (name or time changed)
      final newPrayerText = 'Solat Seterusnya: $name - $timeStr';
      final bool isPrayerChanged = _nextPrayerText != newPrayerText;

      setState(() {
        _nextPrayerText = newPrayerText;
      });

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
            print(
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
                _loadPrayerTimes();
                return;
              }
              setState(() {
                _countdown = remaining;
              });
            });
          }
        } catch (e) {
          print('Error parsing prayer time: $e'); // Debug log
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
            const SizedBox(height: 20),
            // Today's Prayer Times Card
            _buildTodayPrayerTimesCard(context),
            SizedBox(height: screenHeight * 0.04),
            // Menu Section
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
        (screenHeight * 0.38)
            .clamp(280.0, 420.0)
            .toDouble(); //waveclipper length

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Header Background with gradient
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
          child: Stack(
            children: [
              // Decorative circles
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
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontSize: screenWidth * 0.062,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                      SizedBox(height: screenHeight * 0.024),
                      // Ayat Hari Ini
                      _buildAyatHariIniHeader(context),
                      SizedBox(height: screenHeight * 0.024),
                      // Search Bar
                      _buildSearchBar(context),
                    ],
                  ),
                ),
              ),
            ],
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
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                currentDate,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              FutureBuilder<String>(
                future: SharedPreferences.getInstance().then(
                  (prefs) =>
                      prefs.getString('current_location_name') ?? 'Malaysia',
                ),
                builder: (context, snapshot) {
                  return Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        snapshot.data ?? 'Malaysia',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
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

  Widget _buildTodayPrayerTimesCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isPrayerTimesLoading) {
      return _buildPrayerTimesSkeletonLoading(context);
    }

    if (_prayerTimes.isEmpty) {
      return const SizedBox.shrink();
    }

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
              Text(
                'Waktu Solat Hari Ini',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            controller: _prayerTimesScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _prayerTimes.asMap().entries.map((entry) {
                    final prayer = entry.value;
                    final isLast = entry.key == _prayerTimes.length - 1;
                    final prayerName = prayer['name'] ?? '';
                    final prayerColor = _getPrayerColor(prayerName);

                    return Padding(
                      padding: EdgeInsets.only(right: isLast ? 0 : 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: prayerColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: prayerColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              prayerName,
                              style: TextStyle(
                                color: prayerColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              prayer['time'] ?? '',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
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

          // 2x2 Grid Layout
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMenuGridCard(
                      context,
                      title: 'Waktu Solat',
                      iconPath: 'assets/icons/menu/waktu_solat.svg',
                      backgroundColor: const Color(0xFFF3E5F5),
                      iconColor: const Color(0xFF8E24AA),
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
                    child: _buildMenuGridCard(
                      context,
                      title: 'Arah Kiblat',
                      iconPath: 'assets/icons/menu/kiblat.svg',
                      backgroundColor: const Color(0xFFFFE0B2),
                      iconColor: const Color(0xFFFF6D00),
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const KiblatPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMenuGridCard(
                      context,
                      title: 'Al Qur\'an',
                      iconPath: 'assets/icons/menu/quran_new.svg',
                      backgroundColor: const Color(0xFFE0F2F1),
                      iconColor: const Color(0xFF00C853),
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const QuranPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMenuGridCard(
                      context,
                      title: 'Tasbih',
                      iconPath: 'assets/icons/menu/tasbih.svg',
                      backgroundColor: const Color(0xFFFCE4EC),
                      iconColor: const Color(0xFFFF4081),
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const ZikirCounterPage()),
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

  Widget _buildMenuGridCard(
    BuildContext context, {
    required String title,
    required String iconPath,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adjust colors for dark mode
    final adjustedBackgroundColor =
        isDark ? backgroundColor.withOpacity(0.25) : backgroundColor;
    final adjustedIconColor = isDark ? iconColor : iconColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: adjustedBackgroundColor,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: adjustedIconColor.withOpacity(isDark ? 0.3 : 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: adjustedIconColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                iconPath,
                width: 28,
                height: 28,
                color: adjustedIconColor,
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color:
                      isDark ? colorScheme.onSurface : colorScheme.onBackground,
                  fontSize: screenWidth * 0.034,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
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

  Widget _buildAyatHariIniHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.format_quote_rounded,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Maka sesungguhnya bersama kesulitan ada kemudahan."',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: screenWidth * 0.035,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '- QS. Al-Insyirah: 5',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

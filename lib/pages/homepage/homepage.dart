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
  // Carousel images moved to class-level so timers can access length
  final List<String> _carouselImages = [
    'assets/images/KP5R3.png', //Kempen Potong Lima
    'assets/images/IST2.png', //Infak Subuh
    'assets/images/SPAT1.png', //Ifak Set Persalihan Akhir
    'assets/images/WQT1.png', //Waqaf Quran
  ];
  Timer? _carouselTimer; // Auto-scroll timer for the carousel
  String _nextPrayerText = 'Loading...';
  Timer? _timer;
  Timer? _countdownTimer;
  Duration _countdown = Duration.zero;
  List<Map<String, dynamic>> _prayerTimes = [];

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _carouselTimer?.cancel();
    _countdownTimer?.cancel();
    _searchTextTimer?.cancel(); // Tambah ini untuk batalkan timer teks
    _pageController.dispose();
    _scrollController.dispose();
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
            });
          }
          _updateNextPrayer();

          // Schedule notifications after prayer times are loaded
          _scheduleNotificationsIfNeeded(position);
        } else {
          // API failed, set default countdown
          _setDefaultCountdown();
        }
      } else {
        // Location not available, set default countdown
        _setDefaultCountdown();
      }
    } catch (e) {
      print('Error loading prayer times for homepage: $e');
      // Error occurred, set default countdown
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
            const SizedBox(height: 72), // Space for overlapping card
            // Menu Section
            _buildIconMenu(context),
            SizedBox(height: screenHeight * 0.04),

            // Programs Section
            _buildMainCarousel(context),
            SizedBox(height: screenHeight * 0.04),

            // Daily Verse Section
            _buildAyatHariIni(context),
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
        (screenHeight * 0.35).clamp(240.0, 360.0).toDouble();

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
                    16,
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
                      SizedBox(height: screenHeight * 0.032),
                      // Search Bar
                      _buildSearchBar(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Overlapping Prayer Card
        Positioned(
          bottom: -56,
          left: screenWidth * 0.05,
          right: screenWidth * 0.05,
          child: _buildPrayerTimesCard(context),
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
          color: colorScheme.onPrimary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.onPrimary.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.search_rounded,
                color: colorScheme.onPrimary,
                size: 18,
              ),
            ),
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
                      color: colorScheme.onPrimary,
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

  Widget _buildPrayerTimesCard(BuildContext context) {
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
      child: Row(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              GestureDetector(
                onTap: () {
                  OthersMenuPage.show(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Semua',
                        style: TextStyle(
                          fontSize: screenWidth * 0.034,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ],
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
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      iconColor: colorScheme.primary,
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
                      backgroundColor: colorScheme.primary.withOpacity(0.08),
                      iconColor: colorScheme.primary,
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
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      iconColor: colorScheme.primary,
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
                      backgroundColor: colorScheme.primary.withOpacity(0.08),
                      iconColor: colorScheme.primary,
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: iconColor.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.08),
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
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: colorScheme.onBackground,
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
              GestureDetector(
                onTap: () {
                  _onTabTapped(1);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Semua',
                        style: TextStyle(
                          fontSize: screenWidth * 0.034,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ],
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

  Widget _buildAyatHariIni(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.08),
            colorScheme.primary.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
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
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ayat Hari Ini',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),

          // Verse Content
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Dan dirikanlah solat, tunaikanlah zakat, dan ruku\'lah beserta orang-orang yang ruku\'."',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: screenWidth * 0.042,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Surah Al-Baqarah, Ayat 43',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: screenWidth * 0.034,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
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

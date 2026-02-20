import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../../navbar.dart';
import '../../services/prayer_times_service.dart';
import '../../services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../program/program_page.dart';
import '../waqaf/waqafpage.dart';
import '../kedai/kedai.dart';
import '../akaun/akaunpage.dart';
import 'package:flutter/services.dart';

// Widgets
import 'widgets/homepage_appbar.dart';
import 'widgets/prayer_card_widget.dart';
import 'widgets/prayer_times_row.dart';
import 'widgets/quran_tracker_widget.dart';
import 'widgets/menu_grid_widget.dart';
import 'widgets/peluang_bersama_widget.dart';
import 'widgets/agihan_manfaat_widget.dart';
import 'widgets/ayat_hari_ini_widget.dart';

// Utils
import 'utils/prayer_helpers.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();

  static Future<void> saveQuranProgress({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_read_surah', surahNumber);
      await prefs.setInt('last_read_ayah', ayahNumber);
      await prefs.setBool('has_read_quran', true);
      await prefs.setString('last_read_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Error saving Quran progress: $e');
    }
  }
}

class _HomepageState extends State<Homepage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  String _nextPrayerText = 'Loading...';
  Timer? _timer;
  Timer? _countdownTimer;
  Duration _countdown = Duration.zero;
  List<Map<String, dynamic>> _prayerTimes = [];
  String _currentLocationName = 'Malaysia';
  bool _isRefreshing = false;

  PageController _ayatPageController = PageController();
  Timer? _ayatTimer;
  int _currentAyatIndex = 0;

  // ✅ Animation controllers for clouds
  late AnimationController _cloudController1;
  late AnimationController _cloudController2;
  late AnimationController _cloudController3;
  late Animation<double> _cloudAnimation1;
  late Animation<double> _cloudAnimation2;
  late Animation<double> _cloudAnimation3;
  
  // ✅ Animation controllers for birds
  late AnimationController _birdController1;
  late AnimationController _birdController2;
  late Animation<double> _birdAnimation1;
  late Animation<double> _birdAnimation2;
  late AnimationController _birdFlapController;
  late Animation<double> _birdFlapAnimation;

  final List<Map<String, String>> _ayatList = [
    {'ayat': 'Maka sesungguhnya bersama kesulitan ada kemudahan.', 'source': 'QS. Al-Insyirah: 5'},
    {'ayat': 'Dan Dialah Yang menurunkan hujan setelah mereka berputus asa.', 'source': 'QS. Asy-Syura: 28'},
    {'ayat': 'Sesungguhnya Allah tidak mengubah keadaan sesuatu kaum sehingga mereka mengubah keadaan diri mereka sendiri.', 'source': 'QS. Ar-Ra\'d: 11'},
    {'ayat': 'Maka apabila kamu telah selesai (dari sesuatu urusan), kerjakanlah dengan sungguh-sungguh (urusan) yang lain.', 'source': 'QS. Al-Insyirah: 7'},
    {'ayat': 'Dan janganlah kamu berputus asa dari rahmat Allah. Sesungguhnya tiada berputus asa dari rahmat Allah melainkan orang-orang yang kufur.', 'source': 'QS. Yusuf: 87'},
  ];

  @override
  void initState() {
    super.initState();
    
    // ✅ Initialize cloud animations
    _cloudController1 = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
    
    _cloudController2 = AnimationController(
      duration: const Duration(seconds: 35),
      vsync: this,
    )..repeat();
    
    _cloudController3 = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    _cloudAnimation1 = Tween<double>(begin: -100, end: 500).animate(
      CurvedAnimation(parent: _cloudController1, curve: Curves.linear),
    );
    
    _cloudAnimation2 = Tween<double>(begin: -150, end: 500).animate(
      CurvedAnimation(parent: _cloudController2, curve: Curves.linear),
    );
    
    _cloudAnimation3 = Tween<double>(begin: -80, end: 500).animate(
      CurvedAnimation(parent: _cloudController3, curve: Curves.linear),
    );
    
    // ✅ Initialize bird animations
    _birdController1 = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
    
    _birdController2 = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat();
    
    _birdAnimation1 = Tween<double>(begin: -50, end: 500).animate(
      CurvedAnimation(parent: _birdController1, curve: Curves.linear),
    );
    
    _birdAnimation2 = Tween<double>(begin: -80, end: 500).animate(
      CurvedAnimation(parent: _birdController2, curve: Curves.linear),
    );
    
    // Wing flap animation
    _birdFlapController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat(reverse: true);
    
    _birdFlapAnimation = Tween<double>(begin: -0.3, end: 0.3).animate(
      CurvedAnimation(parent: _birdFlapController, curve: Curves.easeInOut),
    );
    
    _loadInitialLocationName();
    _initializeNotifications().then((_) => _loadPrayerTimes());
    _startTimer();
    _startAyatAutoSlide();
  }

  @override
  void dispose() {
    _cloudController1.dispose();
    _cloudController2.dispose();
    _cloudController3.dispose();
    _birdController1.dispose();
    _birdController2.dispose();
    _birdFlapController.dispose();
    _timer?.cancel();
    _countdownTimer?.cancel();
    _scrollController.dispose();
    _ayatTimer?.cancel();
    _ayatPageController.dispose();
    super.dispose();
  }

  // ✅ Pull to refresh function
  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    
    try {
      // Reload prayer times
      await _loadPrayerTimes();
      
      // Small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('❌ Error refreshing: $e');
    }
    
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _loadInitialLocationName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationName = prefs.getString('current_location_name');
      if (locationName != null && mounted) setState(() => _currentLocationName = locationName);
    } catch (e) {
      print('❌ Error loading initial location name: $e');
    }
  }

  void _startAyatAutoSlide() {
    _ayatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_ayatPageController.hasClients) {
        int nextPage = (_currentAyatIndex + 1) % _ayatList.length;
        _ayatPageController.animateToPage(nextPage, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
        if (mounted) setState(() => _currentAyatIndex = nextPage);
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _updateNextPrayer());
  }

  Future<void> _initializeNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequestedPermission = prefs.getBool('notification_permission_requested') ?? false;
      if (!hasRequestedPermission) {
        final notificationService = NotificationService();
        await notificationService.initialize();
        await notificationService.requestPermission();
        await prefs.setBool('notification_permission_requested', true);
      }
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  Future<void> _loadPrayerTimes() async {
    _countdownTimer?.cancel();
    try {
      Position? position = await PrayerTimesService.getCurrentLocation();
      if (position != null) {
        final prayerData = await PrayerTimesService.getPrayerTimesForMalaysia(position.latitude, position.longitude);
        if (prayerData != null && prayerData['code'] == 200) {
          if (mounted) setState(() => _prayerTimes = PrayerTimesService.parsePrayerTimes(prayerData));
          _updateNextPrayer();
          final locationName = await PrayerTimesService.getLocationName(position.latitude, position.longitude);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_location_name', locationName);
          if (mounted) setState(() => _currentLocationName = locationName);
          _scheduleNotificationsIfNeeded(position);
        } else {
          _setDefaultCountdown();
        }
      } else {
        _setDefaultCountdown();
      }
    } catch (e) {
      _setDefaultCountdown();
    }
  }

  Future<void> _scheduleNotificationsIfNeeded(Position position) async {
    try {
      if (_prayerTimes.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final hasRequestedPermission = prefs.getBool('notification_permission_requested') ?? false;
      if (!hasRequestedPermission) return;

      final lastScheduledDate = prefs.getString('last_scheduled_date');
      final lastScheduledLocation = prefs.getString('last_scheduled_location');
      final today = DateTime.now().toIso8601String().split('T')[0];
      final locationName = await PrayerTimesService.getLocationName(position.latitude, position.longitude);
      await prefs.setString('current_location_name', locationName);

      if (lastScheduledDate == today && lastScheduledLocation == locationName) return;

      final notificationService = NotificationService();
      final locationChanged = lastScheduledLocation != null && lastScheduledLocation != locationName;
      
      if (lastScheduledDate == today && locationChanged) {
        await notificationService.forceReschedule(_prayerTimes, locationName: locationName);
        await notificationService.cachePrayerTimesMinimal(_prayerTimes);
        await prefs.setString('last_scheduled_location', locationName);
        return;
      }

      try {
        final monthly = await PrayerTimesService.getMonthlyPrayerTimes(position.latitude, position.longitude, DateTime.now());
        if (monthly != null && monthly.isNotEmpty) {
          final now = DateTime.now();
          final List<Map<String, dynamic>> allPrayerTimes = [];
          for (int day = 0; day < 7; day++) {
            final target = now.add(Duration(days: day));
            final dayKey = target.day.toString().padLeft(2, '0');
            final dayPrayers = monthly[dayKey];
            if (dayPrayers != null && dayPrayers.isNotEmpty) {
              for (var p in dayPrayers) {
                allPrayerTimes.add({'dayOffset': day, 'name': p['name'], 'time': p['time'] ?? p['time24'] ?? '', 'time24': p['time24'] ?? p['time'] ?? ''});
              }
            } else {
              for (var p in _prayerTimes) {
                allPrayerTimes.add({'dayOffset': day, 'name': p['name'], 'time': p['time'] ?? '', 'time24': p['time24'] ?? p['time'] ?? ''});
              }
            }
          }
          await notificationService.schedule7DaysPrayerNotifications(allPrayerTimes, locationName: locationName);
        } else {
          await notificationService.schedulePrayerNotificationsWithTracking(_prayerTimes, locationName: locationName);
        }
      } catch (e) {
        await notificationService.schedulePrayerNotificationsWithTracking(_prayerTimes, locationName: locationName);
      }

      await notificationService.cachePrayerTimesMinimal(_prayerTimes);
      await prefs.setString('last_scheduled_location', locationName);
    } catch (e) {
      print('❌ Error scheduling notifications: $e');
    }
  }

  void _setDefaultCountdown() {
    if (mounted) setState(() { _nextPrayerText = 'Tidak dapat memuatkan waktu solat'; _countdown = Duration.zero; });
    _countdownTimer?.cancel();
  }

  void _updateNextPrayer() {
    if (_prayerTimes.isEmpty) return;
    final nextPrayer = PrayerTimesService.getNextPrayer(_prayerTimes);
    if (nextPrayer != null && mounted) {
      final name = nextPrayer['name'] ?? '';
      final timeStr = nextPrayer['time'] ?? '';
      final time24 = nextPrayer['time24'] ?? timeStr;
      final newPrayerText = 'Solat Seterusnya: $name - $timeStr';
      final bool isPrayerChanged = _nextPrayerText != newPrayerText;
      setState(() => _nextPrayerText = newPrayerText);

      if (isPrayerChanged || _countdownTimer == null || !_countdownTimer!.isActive) {
        try {
          final parts = time24.split(':');
          if (parts.length >= 2) {
            final int hour = int.parse(parts[0]);
            final int minute = int.parse(parts[1]);
            DateTime now = DateTime.now();
            DateTime target = DateTime(now.year, now.month, now.day, hour, minute);
            if (target.isBefore(now)) target = target.add(const Duration(days: 1));

            _countdownTimer?.cancel();
            setState(() => _countdown = target.difference(now));

            _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (!mounted) return;
              final remaining = target.difference(DateTime.now());
              if (remaining.inSeconds <= 0) { timer.cancel(); _loadPrayerTimes(); return; }
              setState(() => _countdown = remaining);
            });
          }
        } catch (e) {
          print('Error parsing prayer time: $e');
        }
      }
    }
  }

  String _formatDuration(Duration d) => PrayerHelpers.formatDuration(d);

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    switch (index) {
      case 1: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const ProgramPage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero)); break;
      case 2: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const WaqafPage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero)); break;
      case 3: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const InboxPage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero)); break;
      case 4: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const AkaunPage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero)); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    // ✅ Responsive: detect if tablet
    final isTablet = screenWidth > 600;
    final headerHeightPercent = isTablet ? 0.25 : 0.32;
    final headerHeight = screenHeight * headerHeightPercent + statusBarHeight;
    
    // ✅ Responsive values
    final cloudEndPosition = screenWidth + 100;
    final birdEndPosition = screenWidth + 50;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      extendBody: false,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF00796B),
        backgroundColor: Colors.white,
        displacement: 40,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              // ✅ 3D Header with shadow/elevation effect
              Container(
                height: headerHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(isTablet ? 70 : 50),
                  ),
                  boxShadow: [
                    // Main shadow - creates depth
                    BoxShadow(
                      color: const Color(0xFF004D40).withOpacity(0.3),
                      offset: const Offset(0, 8),
                      blurRadius: isTablet ? 25 : 20,
                      spreadRadius: 0,
                    ),
                    // Secondary shadow - softer, wider
                    BoxShadow(
                      color: const Color(0xFF00796B).withOpacity(0.15),
                      offset: const Offset(0, 4),
                      blurRadius: isTablet ? 16 : 12,
                      spreadRadius: 2,
                    ),
                    // Inner glow at bottom edge
                    BoxShadow(
                      color: const Color(0xFF26A69A).withOpacity(0.2),
                      offset: const Offset(0, 2),
                      blurRadius: isTablet ? 8 : 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(isTablet ? 70 : 50),
                  ),
                  child: Stack(
                    children: [
                      // Layer 1: Base gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF00363A),
                              Color(0xFF004D40),
                              Color(0xFF00695C),
                              Color(0xFF00897B),
                            ],
                            stops: [0.0, 0.3, 0.6, 1.0],
                          ),
                        ),
                      ),
                      
                      // ✅ Layer 2: Moving Cloud 1 (responsive)
                      AnimatedBuilder(
                        animation: _cloudAnimation1,
                        builder: (context, child) {
                          final position = (_cloudAnimation1.value / 500) * (screenWidth + 100) - 100;
                          return Positioned(
                            top: statusBarHeight + (isTablet ? 30 : 25),
                            left: position,
                            child: _buildCloud(isTablet ? 80 : 60, 0.1),
                          );
                        },
                      ),
                      
                      // ✅ Layer 3: Moving Cloud 2 (responsive)
                      AnimatedBuilder(
                        animation: _cloudAnimation2,
                        builder: (context, child) {
                          final position = (_cloudAnimation2.value / 500) * (screenWidth + 150) - 150;
                          return Positioned(
                            top: statusBarHeight + (isTablet ? 70 : 55),
                            left: position,
                            child: _buildCloud(isTablet ? 100 : 80, 0.07),
                          );
                        },
                      ),
                      
                      // ✅ Layer 4: Moving Cloud 3 (responsive)
                      AnimatedBuilder(
                        animation: _cloudAnimation3,
                        builder: (context, child) {
                          final position = (_cloudAnimation3.value / 500) * (screenWidth + 80) - 80;
                          return Positioned(
                            top: statusBarHeight + (isTablet ? 110 : 85),
                            left: position,
                            child: _buildCloud(isTablet ? 65 : 50, 0.08),
                          );
                        },
                      ),
                      
                      // ✅ Layer 4b: Flying Bird 1 (responsive)
                      AnimatedBuilder(
                        animation: Listenable.merge([_birdAnimation1, _birdFlapAnimation]),
                        builder: (context, child) {
                          final position = (_birdAnimation1.value / 500) * (screenWidth + 50) - 50;
                          return Positioned(
                            top: statusBarHeight + (isTablet ? 50 : 40),
                            left: position,
                            child: _buildBird(isTablet ? 16 : 12, 0.25),
                          );
                        },
                      ),
                      
                      // ✅ Layer 4c: Flying Bird 2 (responsive)
                      AnimatedBuilder(
                        animation: Listenable.merge([_birdAnimation2, _birdFlapAnimation]),
                        builder: (context, child) {
                          final position = (_birdAnimation2.value / 500) * (screenWidth + 80) - 80;
                          return Positioned(
                            top: statusBarHeight + (isTablet ? 85 : 65),
                            left: position,
                            child: _buildBird(isTablet ? 14 : 10, 0.2),
                          );
                        },
                      ),
                      
                      // Layer 5: SVG Masjid background - aligned to right
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Opacity(
                          opacity: 0.25,
                          child: SvgPicture.asset(
                            'assets/images/HeaderMasjid9.svg',
                            fit: BoxFit.cover,
                            alignment: Alignment.centerRight,
                          ),
                        ),
                      ),
                      
                      // Layer 6: Glowing dots (stars) - bottom left corner
                      Positioned(
                        bottom: isTablet ? 25 : 20,
                        left: isTablet ? 30 : 20,
                        child: _buildGlowDot(isTablet ? 8 : 6, 0.45),
                      ),
                      Positioned(
                        bottom: isTablet ? 50 : 40,
                        left: isTablet ? 60 : 45,
                        child: _buildGlowDot(isTablet ? 6 : 4, 0.3),
                      ),
                      Positioned(
                        bottom: isTablet ? 35 : 28,
                        left: isTablet ? 100 : 75,
                        child: _buildGlowDot(isTablet ? 5 : 3, 0.2),
                      ),
                      
                      // ✅ Layer 7: 3D edge highlight (bottom edge glow)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.15),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomepageAppBar(),
                    SizedBox(height: screenHeight * (isTablet ? 0.005 : 0.003)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * (isTablet ? 0.08 : 0.05)),
                      child: PrayerCardWidget(
                        nextPrayerText: _nextPrayerText,
                        countdown: _countdown,
                        currentLocationName: _currentLocationName,
                        formatDuration: _formatDuration,
                      ),
                    ),
                    SizedBox(height: screenHeight * (isTablet ? 0.03 : 0.025)),
                    Padding(
                      padding: EdgeInsets.only(top: screenHeight * (isTablet ? 0.03 : 0.025)),
                      child: PrayerTimesRow(
                        prayerTimes: _prayerTimes,
                        getPrayerColor: PrayerHelpers.getPrayerColor,
                        getPrayerIcon: PrayerHelpers.getPrayerIcon,
                        isPrayerPassed: PrayerHelpers.isPrayerPassed,
                      ),
                    ),
                    SizedBox(height: screenHeight * (isTablet ? 0.015 : 0.01)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * (isTablet ? 0.08 : 0.05)),
                      child: const QuranTrackerWidget(),
                    ),
                    SizedBox(height: screenHeight * (isTablet ? 0.02 : 0.015)),
                    const MenuGridWidget(),
                    SizedBox(height: screenHeight * (isTablet ? 0.02 : 0.015)),
                    _buildDivider(),
                    SizedBox(height: screenHeight * (isTablet ? 0.015 : 0.012)),
                    const PeluangBersamaWidget(),
                    SizedBox(height: screenHeight * (isTablet ? 0.015 : 0.012)),
                    _buildDivider(),
                    SizedBox(height: screenHeight * (isTablet ? 0.02 : 0.015)),
                    const AgihanManfaatWidget(),
                    SizedBox(height: screenHeight * (isTablet ? 0.02 : 0.015)),
                    _buildDivider(),
                    SizedBox(height: screenHeight * (isTablet ? 0.02 : 0.015)),
                    AyatHariIniWidget(
                      pageController: _ayatPageController,
                      currentAyatIndex: _currentAyatIndex,
                      ayatList: _ayatList,
                      onPageChanged: (index) => setState(() => _currentAyatIndex = index),
                    ),
                    SizedBox(height: screenHeight * (isTablet ? 0.15 : 0.12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        scrollController: _scrollController,
      ),
    );
  }

  // ✅ Cloud widget
  Widget _buildCloud(double width, double opacity) {
    return CustomPaint(
      size: Size(width, width * 0.5),
      painter: _CloudPainter(opacity: opacity),
    );
  }

  // ✅ Bird widget with flapping wings
  Widget _buildBird(double size, double opacity) {
    return AnimatedBuilder(
      animation: _birdFlapAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(size, size * 0.5),
          painter: _BirdPainter(
            opacity: opacity,
            flapAngle: _birdFlapAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildGlowDot(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(opacity * 0.5),
            blurRadius: size,
            spreadRadius: size * 0.3,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(height: 0.5, color: Colors.black.withOpacity(0.1));
}

// ✅ Cloud Painter
class _CloudPainter extends CustomPainter {
  final double opacity;
  
  _CloudPainter({required this.opacity});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final shadowPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    final path = Path();
    final centerY = size.height * 0.6;
    
    // Main body
    path.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.5, centerY),
      width: size.width * 0.6,
      height: size.height * 0.5,
    ));
    
    // Left bump
    path.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.25, centerY - size.height * 0.1),
      width: size.width * 0.4,
      height: size.height * 0.5,
    ));
    
    // Right bump
    path.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.7, centerY - size.height * 0.05),
      width: size.width * 0.45,
      height: size.height * 0.55,
    ));
    
    // Top bump
    path.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.45, centerY - size.height * 0.25),
      width: size.width * 0.35,
      height: size.height * 0.4,
    ));
    
    // Small top bump
    path.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.6, centerY - size.height * 0.2),
      width: size.width * 0.25,
      height: size.height * 0.3,
    ));
    
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ✅ Bird Painter - draws a simple bird with flapping wings
class _BirdPainter extends CustomPainter {
  final double opacity;
  final double flapAngle;
  
  _BirdPainter({required this.opacity, required this.flapAngle});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Save canvas state
    canvas.save();
    canvas.translate(centerX, centerY);
    
    // Left wing
    final leftWingPath = Path();
    leftWingPath.moveTo(0, 0);
    leftWingPath.quadraticBezierTo(
      -size.width * 0.3,
      -size.height * flapAngle * 2,
      -size.width * 0.5,
      -size.height * flapAngle,
    );
    canvas.drawPath(leftWingPath, paint);
    
    // Right wing
    final rightWingPath = Path();
    rightWingPath.moveTo(0, 0);
    rightWingPath.quadraticBezierTo(
      size.width * 0.3,
      -size.height * flapAngle * 2,
      size.width * 0.5,
      -size.height * flapAngle,
    );
    canvas.drawPath(rightWingPath, paint);
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(covariant _BirdPainter oldDelegate) {
    return oldDelegate.flapAngle != flapAngle;
  }
}
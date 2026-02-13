import 'package:flutter/material.dart';
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

/// Main Homepage
/// Displays prayer times, Quran tracker, menu grid, and Islamic content
/// Features: prayer countdown, location-based times, notifications
class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();

  /// Saves user's Quran reading progress to SharedPreferences
  /// Used by Quran page to track last read surah and ayah
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
      print('📖 Saved Quran progress: Surah $surahNumber, Ayat $ayahNumber');
    } catch (e) {
      print('❌ Error saving Quran progress: $e');
    }
  }
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  String _nextPrayerText = 'Loading...';
  Timer? _timer;
  Timer? _countdownTimer;
  Duration _countdown = Duration.zero;
  List<Map<String, dynamic>> _prayerTimes = [];
  String _currentLocationName = 'Malaysia';

  PageController _ayatPageController = PageController();
  Timer? _ayatTimer;
  int _currentAyatIndex = 0;

  final List<Map<String, String>> _ayatList = [
    {
      'ayat': 'Maka sesungguhnya bersama kesulitan ada kemudahan.',
      'source': 'QS. Al-Insyirah: 5',
    },
    {
      'ayat': 'Dan Dialah Yang menurunkan hujan setelah mereka berputus asa.',
      'source': 'QS. Asy-Syura: 28',
    },
    {
      'ayat':
          'Sesungguhnya Allah tidak mengubah keadaan sesuatu kaum sehingga mereka mengubah keadaan diri mereka sendiri.',
      'source': 'QS. Ar-Ra\'d: 11',
    },
    {
      'ayat':
          'Maka apabila kamu telah selesai (dari sesuatu urusan), kerjakanlah dengan sungguh-sungguh (urusan) yang lain.',
      'source': 'QS. Al-Insyirah: 7',
    },
    {
      'ayat':
          'Dan janganlah kamu berputus asa dari rahmat Allah. Sesungguhnya tiada berputus asa dari rahmat Allah melainkan orang-orang yang kufur.',
      'source': 'QS. Yusuf: 87',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialLocationName();
    _initializeNotifications().then((_) {
      _loadPrayerTimes();
    });
    _startTimer();
    _startAyatAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _scrollController.dispose();
    _ayatTimer?.cancel();
    _ayatPageController.dispose();
    super.dispose();
  }

  // ✅ Load initial location name
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
      print('❌ Error loading initial location name: $e');
    }
  }

  // ✅ AUTO-SLIDE AYAT (your code)
  void _startAyatAutoSlide() {
    _ayatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_ayatPageController.hasClients) {
        int nextPage = (_currentAyatIndex + 1) % _ayatList.length;
        _ayatPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateNextPrayer();
    });
  }

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

        await prefs.setBool('notification_permission_requested', true);
      } else {
        print('ℹ️ Notification permission already requested previously');
      }
    } catch (e) {
      print('❌ Error initializing notifications on homepage: $e');
    }
  }

  Future<void> _loadPrayerTimes() async {
    _countdownTimer?.cancel();
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

          // ✅ Update location name
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

          _scheduleNotificationsIfNeeded(position);
        } else {
          _setDefaultCountdown();
        }
      } else {
        _setDefaultCountdown();
      }
    } catch (e) {
      print('Error loading prayer times for homepage: $e');
      _setDefaultCountdown();
    }
  }

  Future<void> _scheduleNotificationsIfNeeded(Position position) async {
    try {
      if (_prayerTimes.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final hasRequestedPermission =
          prefs.getBool('notification_permission_requested') ?? false;

      if (!hasRequestedPermission) {
        return;
      }

      final lastScheduledDate = prefs.getString('last_scheduled_date');
      final lastScheduledLocation = prefs.getString('last_scheduled_location');
      final today = DateTime.now().toIso8601String().split('T')[0];

      final locationName = await PrayerTimesService.getLocationName(
        position.latitude,
        position.longitude,
      );

      await prefs.setString('current_location_name', locationName);

      // If we've already scheduled for today and the location hasn't changed,
      // skip scheduling. If location changed, force a reschedule so notifications
      // reflect the new place even on the same day.
      if (lastScheduledDate == today && lastScheduledLocation == locationName) {
        print(
          'ℹ️ Notifications already scheduled for today and location unchanged',
        );
        return;
      }

      print('📅 Scheduling notifications with user location...');

      final notificationService = NotificationService();

      // If location changed but schedule already exists for today, force reschedule
      final locationChanged =
          lastScheduledLocation != null &&
          lastScheduledLocation != locationName;
      if (lastScheduledDate == today && locationChanged) {
        print(
          '📍 Location changed from "$lastScheduledLocation" to "$locationName" - forcing reschedule from homepage',
        );
        try {
          await notificationService.forceReschedule(
            _prayerTimes,
            locationName: locationName,
          );
          await notificationService.cachePrayerTimesMinimal(_prayerTimes);
          await prefs.setString('last_scheduled_location', locationName);
          print(
            '✅ Forced reschedule completed from homepage for $locationName',
          );
        } catch (e) {
          print('❌ Failed to force reschedule from homepage: $e');
        }
        return;
      }

      // Try to fetch full monthly prayer times so we can schedule accurate
      // notifications for each of the next 7 days (times change slightly day-to-day)
      try {
        final monthly = await PrayerTimesService.getMonthlyPrayerTimes(
          position.latitude,
          position.longitude,
          DateTime.now(),
        );

        if (monthly != null && monthly.isNotEmpty) {
          final now = DateTime.now();
          final List<Map<String, dynamic>> allPrayerTimes = [];

          for (int day = 0; day < 7; day++) {
            final target = now.add(Duration(days: day));
            final dayKey = target.day.toString().padLeft(2, '0');

            final dayPrayers = monthly[dayKey];
            if (dayPrayers != null && dayPrayers.isNotEmpty) {
              for (var p in dayPrayers) {
                allPrayerTimes.add({
                  'dayOffset': day,
                  'name': p['name'],
                  'time': p['time'] ?? p['time24'] ?? '',
                  'time24': p['time24'] ?? p['time'] ?? '',
                });
              }
            } else {
              // Fallback: replicate today's times for this day
              for (var p in _prayerTimes) {
                allPrayerTimes.add({
                  'dayOffset': day,
                  'name': p['name'],
                  'time': p['time'] ?? '',
                  'time24': p['time24'] ?? p['time'] ?? '',
                });
              }
            }
          }

          await notificationService.schedule7DaysPrayerNotifications(
            allPrayerTimes,
            locationName: locationName,
          );
        } else {
          // Fallback to single-day scheduling if monthly fetch failed
          await notificationService.schedulePrayerNotificationsWithTracking(
            _prayerTimes,
            locationName: locationName,
          );
        }
      } catch (e) {
        debugPrint(
          '⚠️ Failed to fetch monthly prayer times: $e - falling back',
        );
        await notificationService.schedulePrayerNotificationsWithTracking(
          _prayerTimes,
          locationName: locationName,
        );
      }

      await notificationService.cachePrayerTimesMinimal(_prayerTimes);
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
    _countdownTimer?.cancel();
  }

  void _updateNextPrayer() {
    if (_prayerTimes.isEmpty) return;

    final nextPrayer = PrayerTimesService.getNextPrayer(_prayerTimes);
    if (nextPrayer != null && mounted) {
      final name = nextPrayer['name'] ?? '';
      final timeStr = nextPrayer['time'] ?? '';
      final time24 = nextPrayer['time24'] ?? timeStr;

      print('Next prayer: $name at $timeStr (24h: $time24)');

      final newPrayerText = 'Solat Seterusnya: $name - $timeStr';
      final bool isPrayerChanged = _nextPrayerText != newPrayerText;

      setState(() {
        _nextPrayerText = newPrayerText;
      });

      if (isPrayerChanged ||
          _countdownTimer == null ||
          !_countdownTimer!.isActive) {
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

            _countdownTimer?.cancel();
            final initialCountdown = target.difference(now);
            print(
              'Starting new countdown: ${initialCountdown.inSeconds} seconds (${_formatDuration(initialCountdown)})',
            );

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
                _loadPrayerTimes();
                return;
              }
              setState(() {
                _countdown = remaining;
              });
            });
          }
        } catch (e) {
          print('Error parsing prayer time: $e');
        }
      }
    }
  }

  String _formatDuration(Duration d) {
    return PrayerHelpers.formatDuration(d);
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
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
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      extendBody: true,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Stack(
          children: [
            Container(
              height: screenHeight * 0.25 + statusBarHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF66B2B2),
                    Color(0xFF99C8C8),
                    Color(0xFFCCDFDF),
                    Color(0xFFE6F0F0),
                    Color(0xFFFFFFFF),
                  ],
                  stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomepageAppBar(),
                  SizedBox(height: screenHeight * 0.0025),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03,
                    ),
                    child: PrayerCardWidget(
                      nextPrayerText: _nextPrayerText,
                      countdown: _countdown,
                      currentLocationName: _currentLocationName,
                      formatDuration: _formatDuration,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.0025),
                  PrayerTimesRow(
                    prayerTimes: _prayerTimes,
                    getPrayerColor: PrayerHelpers.getPrayerColor,
                    getPrayerIcon: PrayerHelpers.getPrayerIcon,
                    isPrayerPassed: PrayerHelpers.isPrayerPassed,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: const QuranTrackerWidget(),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  const MenuGridWidget(),
                  SizedBox(height: screenHeight * 0.015),
                  _buildDivider(),
                  SizedBox(height: screenHeight * 0.012),
                  const PeluangBersamaWidget(),
                  SizedBox(height: screenHeight * 0.012),
                  _buildDivider(),
                  SizedBox(height: screenHeight * 0.015),
                  const AgihanManfaatWidget(),
                  SizedBox(height: screenHeight * 0.015),
                  _buildDivider(),
                  SizedBox(height: screenHeight * 0.015),
                  AyatHariIniWidget(
                    pageController: _ayatPageController,
                    currentAyatIndex: _currentAyatIndex,
                    ayatList: _ayatList,
                    onPageChanged: (index) {
                      setState(() {
                        _currentAyatIndex = index;
                      });
                    },
                  ),
                  SizedBox(height: screenHeight * 0.12),
                ],
              ),
            ),
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

  Widget _buildDivider() {
    return Container(height: 0.5, color: Colors.black.withOpacity(0.1));
  }
}

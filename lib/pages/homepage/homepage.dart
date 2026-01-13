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
import '../doaharian/doa_harian_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import '../../utils/page_transitions.dart';
import 'others_menu_page.dart';
import 'searchpage/search_page.dart';
import '../kiblat/kiblat.dart';
import '../quran/quranpage.dart';
import '../tahlil/tahlil.dart';
import '../hadis40/hadis40.dart';
import 'package:hijri/hijri_calendar.dart'; // ✅ For Hijri dates
import '../../services/quran_service.dart'; // ✅ For Quran tracker
import '../../models/quran_models.dart'; // ✅ For Quran models

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();

  // ✅ Static method to save Quran progress
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
  String _currentLocationName = 'Malaysia'; // ✅ Track location name

  // ✅ AYAT CAROUSEL VARIABLES (your code)
  PageController _ayatPageController = PageController();
  Timer? _ayatTimer;
  int _currentAyatIndex = 0;

  // ✅ AYAT DATA - 5 Different Ayat (your code)
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
      final today = DateTime.now().toIso8601String().split('T')[0];

      if (lastScheduledDate == today) {
        print('ℹ️ Notifications already scheduled for today');
        return;
      }

      print('📅 Scheduling notifications with user location...');

      final locationName = await PrayerTimesService.getLocationName(
        position.latitude,
        position.longitude,
      );

      await prefs.setString('current_location_name', locationName);

      final notificationService = NotificationService();

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

  // ✅ GET PRAYER COLOR (from kawan - colorful icons)
  Color _getPrayerColor(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
      case 'fajr':
        return const Color(0xFF9C27B0); // Purple
      case 'syuruk':
      case 'sunrise':
        return const Color(0xFFFF6F00); // Orange
      case 'zohor':
      case 'dhuhr':
        return const Color(0xFFFFC107); // Golden
      case 'asar':
      case 'asr':
        return const Color(0xFFFF9800); // Amber
      case 'maghrib':
        return const Color(0xFFE91E63); // Pink
      case 'isyak':
      case 'isha':
        return const Color(0xFF3F51B5); // Indigo
      default:
        return const Color(0xFF00897B);
    }
  }

  // ✅ GET PRAYER ICON (from kawan)
  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
      case 'fajr':
        return Icons.wb_twilight;
      case 'syuruk':
      case 'sunrise':
        return Icons.wb_sunny;
      case 'zohor':
      case 'dhuhr':
        return Icons.wb_cloudy;
      case 'asar':
      case 'asr':
        return Icons.wb_sunny;
      case 'maghrib':
        return Icons.brightness_3;
      case 'isyak':
      case 'isha':
        return Icons.brightness_2;
      default:
        return Icons.access_time;
    }
  }

  // ✅ IS PRAYER PASSED
  bool _isPrayerPassed(Map<String, dynamic> prayer) {
    try {
      final timeStr = prayer['time24'] ?? prayer['time'] ?? '';
      if (timeStr.isEmpty) return false;

      final parts = timeStr.split(':');
      if (parts.length < 2) return false;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = DateTime.now();
      final prayerTime = DateTime(now.year, now.month, now.day, hour, minute);

      return now.isAfter(prayerTime);
    } catch (e) {
      return false;
    }
  }

  // ✅ GET LAST READ QURAN (from kawan)
  Future<Map<String, dynamic>> _getLastReadQuran() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSurahNumber = prefs.getInt('last_read_surah') ?? 1;
      final lastAyahNumber = prefs.getInt('last_read_ayah') ?? 1;
      final hasRead = prefs.getBool('has_read_quran') ?? false;

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

      final progress = lastSurahNumber / 114.0;

      return {
        'surahName': lastSurah?.englishName ?? 'Al-Fatihah',
        'surahNumber': lastSurahNumber,
        'ayahNumber': lastAyahNumber,
        'progress': progress,
        'hasRead': hasRead,
      };
    } catch (e) {
      print('Error getting last read Quran: $e');
      return {
        'surahName': 'Al-Fatihah',
        'surahNumber': 1,
        'ayahNumber': 1,
        'progress': 0.0,
        'hasRead': false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context),
                  SizedBox(height: screenHeight * 0.0025),

                  // ✅ 1. MODERN PRAYER CARD (with dates - from kawan, using your colors)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03,
                    ),
                    child: _buildModernPrayerCard(context),
                  ),
                  SizedBox(height: screenHeight * 0.0025),

                  // ✅ 2. COLORFUL HORIZONTAL PRAYER TIMES (from kawan, your size)
                  _buildColorfulHorizontalPrayerCards(),
                  SizedBox(height: screenHeight * 0.01),

                  // ✅ 3. QURAN TRACKER (from kawan)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: _buildQuranTracker(context),
                  ),
                  SizedBox(height: screenHeight * 0.015),

                  // ✅ 4. MENU UTAMA (your code with new colors)
                  _buildIconMenu(context),
                  SizedBox(height: screenHeight * 0.015),
                  _buildDivider(),
                  SizedBox(height: screenHeight * 0.012),

                  // ✅ 5. PELUANG BERSAMA (your code)
                  _buildPeluangBersama(context),
                  SizedBox(height: screenHeight * 0.012),
                  _buildDivider(),
                  SizedBox(height: screenHeight * 0.015),

                  // ✅ 6. AGIHAN MANFAAT (your code)
                  _buildProgramAgihanManfaat(context),
                  SizedBox(height: screenHeight * 0.015),
                  _buildDivider(),
                  SizedBox(height: screenHeight * 0.015),

                  // ✅ 7. AYAT HARI INI (your auto-sliding)
                  _buildAyatHariIni(context),
                  SizedBox(height: screenHeight * 0.025),
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

  Widget _buildAppBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.015,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assalamualaikum,',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.003),
                Text(
                  'Selamat Datang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.022),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: screenWidth * 0.055,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ✅ COMPLETE PRAYER CARD - FULL CODE
  // ════════════════════════════════════════════════════════════════
  // Copy this ENTIRE function to replace _buildModernPrayerCard() in your homepage.dart

  Widget _buildModernPrayerCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Parse prayer info
    String nextPrayerName = '';
    String nextPrayerTime = '';
    if (_nextPrayerText.contains(':') &&
        _nextPrayerText != 'Loading...' &&
        _nextPrayerText != 'Tidak dapat memuatkan waktu solat') {
      final cleaned = _nextPrayerText.replaceAll('Solat Seterusnya: ', '');
      final parts = cleaned.split(' - ');
      if (parts.length == 2) {
        nextPrayerName = parts[0].trim();
        nextPrayerTime = parts[1].trim();
      }
    }

    // Get current date (Gregorian)
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

    // ════════════════════════════════════════════════════════════════
    // SKELETON LOADING STATE
    // ════════════════════════════════════════════════════════════════
    if (_nextPrayerText == 'Loading...' || _prayerTimes.isEmpty) {
      return Container(
        height: screenHeight * 0.26,
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: screenHeight * 0.008,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00695C), Color(0xFF00796B), Color(0xFF00897B)],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          // ✅ SUBTLE ELEVATED SHADOW
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00695C).withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF00695C).withOpacity(0.10),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.015,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Skeleton date row
              Row(
                children: [
                  Container(
                    width: screenWidth * 0.18,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.015),
              // Skeleton main content
              Row(
                children: [
                  Container(
                    width: screenWidth * 0.22,
                    height: screenHeight * 0.11,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 18,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          height: 18,
                          margin: const EdgeInsets.only(bottom: 8),
                          width: screenWidth * 0.35,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          height: 18,
                          width: screenWidth * 0.28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Skeleton bottom row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // ════════════════════════════════════════════════════════════════
    // ACTUAL PRAYER CARD
    // ════════════════════════════════════════════════════════════════
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenHeight * 0.008,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00695C), Color(0xFF00796B), Color(0xFF00897B)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        // ✅ SUBTLE ELEVATED 3D SHADOW
        boxShadow: [
          // Primary shadow - gives depth
          BoxShadow(
            color: const Color(0xFF00695C).withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          // Secondary shadow - adds softness
          BoxShadow(
            color: const Color(0xFF00695C).withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          // Top highlight - creates 3D effect
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: SvgPicture.asset(
                  'assets/images/widget-bg-wsolat.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Inner border for elevated effect
            Container(
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.5),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.015,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ════════════════════════════════════════════════
                    // DATE ROW (Gregorian + Hijri)
                    // ════════════════════════════════════════════════
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$currentDate / $hijriDate',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: screenWidth * 0.024,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),

                    // ════════════════════════════════════════════════
                    // MAIN CONTENT (Icon + Prayer Name)
                    // ════════════════════════════════════════════════
                    Row(
                      children: [
                        // Clock icon
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        // Prayer name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SOLAT SETERUSNYA',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: screenWidth * 0.028,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.25),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                nextPrayerName.isNotEmpty
                                    ? nextPrayerName.toUpperCase()
                                    : 'MEMUAT...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.052,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.015),

                    // ════════════════════════════════════════════════
                    // DIVIDER LINE
                    // ════════════════════════════════════════════════
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),

                    // ════════════════════════════════════════════════
                    // BOTTOM ROW (Waktu + Baki Masa)
                    // ════════════════════════════════════════════════
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // WAKTU (Left)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'WAKTU',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: screenWidth * 0.026,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  nextPrayerTime.isNotEmpty
                                      ? nextPrayerTime
                                      : '--:--',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.058,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.25),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        // BAKI MASA (Right)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'BAKI MASA',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: screenWidth * 0.026,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFFB8860B).withOpacity(0.4),
                                      const Color(0xFFDAA520).withOpacity(0.35),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFDAA520,
                                    ).withOpacity(0.4),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFDAA520,
                                      ).withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _countdown.inSeconds > 0
                                      ? _formatDuration(_countdown)
                                      : '--:--:--',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.046,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.25),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),

                    // ════════════════════════════════════════════════
                    // LOCATION ROW - RIGHT ALIGNED ✅
                    // ════════════════════════════════════════════════
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end, // ✅ RIGHT SIDE
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _currentLocationName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ COLORFUL HORIZONTAL PRAYER CARDS (from kawan, YOUR size structure)
  Widget _buildColorfulHorizontalPrayerCards() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Skeleton loading
    if (_prayerTimes.isEmpty) {
      return Container(
        height: screenHeight * 0.15, // ✅ Reduced from 0.18
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.01, // ✅ Reduced vertical margin
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025,
          vertical: screenHeight * 0.015, // ✅ Reduced padding
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Skeleton title
            Container(
              height: 16, // ✅ Smaller skeleton
              width: screenWidth * 0.3,
              margin: EdgeInsets.only(bottom: screenHeight * 0.01),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Skeleton prayer items
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.005,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            height: screenHeight * 0.06,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: screenWidth * 0.12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    }

    final nextPrayer = PrayerTimesService.getNextPrayer(_prayerTimes);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01, // ✅ Reduced from 0.015
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ SMALLER HEADER SECTION
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.012, // ✅ Reduced from 0.018
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: screenWidth * 0.038, // ✅ Smaller icon (was 0.045)
                  color: const Color(0xFF00897B),
                ),
                SizedBox(width: screenWidth * 0.015), // ✅ Reduced gap
                Text(
                  'Waktu Solat Hari Ini',
                  style: TextStyle(
                    fontSize: screenWidth * 0.034, // ✅ REDUCED from 0.042
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          // ✅ PRAYER TIMES GRID (more compact)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.015, // ✅ Reduced from 0.02
              vertical: screenHeight * 0.014, // ✅ Reduced from 0.018
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  _prayerTimes.map((prayer) {
                    final bool isNextPrayer =
                        nextPrayer != null &&
                        nextPrayer['name'] == prayer['name'];
                    final bool isPassed = _isPrayerPassed(prayer);

                    return _buildCompactPrayerItem(
                      // ✅ New compact version
                      prayer['name'] ?? '',
                      prayer['time'] ?? '--:--',
                      _getPrayerIcon(prayer['name'] ?? ''),
                      _getPrayerColor(prayer['name'] ?? ''),
                      isNextPrayer,
                      isPassed,
                      screenWidth,
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: COMPACT PRAYER ITEM (smaller & cleaner)
  Widget _buildCompactPrayerItem(
    String name,
    String time,
    IconData icon,
    Color prayerColor,
    bool isNext,
    bool isPassed,
    double screenWidth,
  ) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.008,
        ), // ✅ Reduced
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ SMALLER ICON CONTAINER
            Container(
              width: screenWidth * 0.11, // ✅ Reduced from 0.12
              height: screenWidth * 0.11,
              decoration: BoxDecoration(
                color:
                    isNext
                        ? prayerColor
                        : isPassed
                        ? Colors.grey.shade200
                        : prayerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    isNext ? Border.all(color: prayerColor, width: 2) : null,
              ),
              child: Icon(
                icon,
                color:
                    isNext
                        ? Colors.white
                        : isPassed
                        ? Colors.grey.shade400
                        : prayerColor,
                size: screenWidth * 0.048, // ✅ Reduced from 0.05
              ),
            ),
            SizedBox(height: screenWidth * 0.012), // ✅ Reduced gap
            // ✅ SMALLER PRAYER NAME
            Text(
              name,
              style: TextStyle(
                fontSize: screenWidth * 0.028, // ✅ Reduced from 0.030
                fontWeight: isNext ? FontWeight.w900 : FontWeight.w600,
                color:
                    isNext
                        ? prayerColor
                        : isPassed
                        ? Colors.grey.shade500
                        : Colors.black87,
                letterSpacing: 0.1,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: screenWidth * 0.006), // ✅ Reduced gap
            // ✅ SMALLER PRAYER TIME
            Text(
              time,
              style: TextStyle(
                fontSize: screenWidth * 0.026, // ✅ Reduced from 0.028
                fontWeight: isNext ? FontWeight.w500 : FontWeight.w500,
                color:
                    isNext
                        ? prayerColor
                        : isPassed
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),

            // ✅ SMALLER NEXT BADGE
            if (isNext) ...[
              SizedBox(height: screenWidth * 0.008), // ✅ Reduced gap
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.016, // ✅ Reduced
                  vertical: screenWidth * 0.004, // ✅ Reduced
                ),
                decoration: BoxDecoration(
                  color: prayerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'NEXT',
                  style: TextStyle(
                    fontSize: screenWidth * 0.018, // ✅ Reduced from 0.020
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ QURAN TRACKER (Compact Design)
  Widget _buildQuranTracker(BuildContext context) {
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
            setState(() {});
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenWidth * 0.035,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF9800).withOpacity(0.12),
                  const Color(0xFFFBC02D).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFF9800).withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFFFF9800),
                    size: 22,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surahName,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenWidth * 0.015),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ayat $ayahNumber',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025,
                              vertical: screenWidth * 0.012,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF9800),
                                  const Color(0xFFF57C00),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF9800,
                                  ).withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasRead
                                      ? Icons.play_arrow_rounded
                                      : Icons.auto_stories_rounded,
                                  color: Colors.white,
                                  size: screenWidth * 0.035,
                                ),
                                SizedBox(width: screenWidth * 0.015),
                                Text(
                                  hasRead ? 'Teruskan' : 'Mula Baca',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.032,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
      },
    );
  }

  // ✅ BEAUTIFUL COLOR SCHEME FOR ALL MENU CARDS
  // Replace _buildIconMenu() function

  Widget _buildIconMenu(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ✅ SMALLER TITLE
              Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: screenWidth * 0.042, // ✅ REDUCED from 0.048
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              // ✅ SMALLER "LIHAT LAGI" BUTTON
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20), // ✅ Reduced from 25
                  border: Border.all(
                    color: const Color(0xFF00897B).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => OthersMenuPage.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.032, // ✅ Reduced from 0.04
                        vertical: screenHeight * 0.008, // ✅ Reduced from 0.01
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Lagi',
                            style: TextStyle(
                              color: const Color(0xFF00897B),
                              fontWeight: FontWeight.w700,
                              fontSize:
                                  screenWidth * 0.031, // ✅ REDUCED from 0.035
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(
                            width: screenWidth * 0.012,
                          ), // ✅ Reduced from 0.015
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFF00897B),
                            size: screenWidth * 0.031, // ✅ REDUCED from 0.035
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.035), // ✅ Reduced from 0.04
          // ✅ ROW 1: WAKTU SOLAT + ARAH KIBLAT
          Row(
            children: [
              Expanded(
                child: _buildLargeCardWithImage(
                  context,
                  'Waktu Solat',
                  'assets/images/solat_newtest2.png',
                  const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00897B),
                      Color(0xFF26A69A),
                      Color(0xFF4DB6AC),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const PrayerTimesPage()),
                    );
                  },
                ),
              ),
              SizedBox(width: screenWidth * 0.025), // ✅ Reduced from 0.03
              Expanded(
                child: _buildLargeCardWithImage(
                  context,
                  'Arah Kiblat',
                  'assets/images/kaabah_newtest2.png',
                  const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF9A825),
                      Color(0xFFFBC02D),
                      Color(0xFFFFD54F),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const KiblatPage()),
                    );
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: screenWidth * 0.025), // ✅ Reduced from 0.03
          // ✅ ROW 2: AL-QURAN + TASBIH + HADITH
          Row(
            children: [
              Expanded(
                child: _buildSmallerMediumCardWithImage(
                  context,
                  'Al Qur\'an',
                  'assets/images/Quran_newTest3.png',
                  const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1976D2),
                      Color(0xFF2196F3),
                      Color(0xFF42A5F5),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const QuranPage()),
                    );
                  },
                ),
              ),
              SizedBox(width: screenWidth * 0.02), // ✅ Reduced from 0.025
              Expanded(
                child: _buildSmallerMediumCardWithImage(
                  context,
                  'Tasbih',
                  'assets/images/tasbih_newtest.png',
                  const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7B1FA2),
                      Color(0xFF9C27B0),
                      Color(0xFFAB47BC),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const ZikirCounterPage()),
                    );
                  },
                ),
              ),
              SizedBox(width: screenWidth * 0.02), // ✅ Reduced from 0.025
              Expanded(
                child: _buildSmallerMediumCardWithImage(
                  context,
                  'Hadith 40',
                  'assets/images/Hadith_newTest.png',
                  const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFC2185B),
                      Color(0xFFE91E63),
                      Color(0xFFEC407A),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const Hadis40Page()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Keep _buildSmallerMediumCardWithImage() and _buildLargeCardWithImage() unchanged
  // They already handle gradients correctly

  Widget _buildSmallerMediumCardWithImage(
    BuildContext context,
    String title,
    String imagePath,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.95,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 5),
                spreadRadius: 0.5,
              ),
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 1.5,
              ),
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: 2.5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.5),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 8,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: screenWidth * 0.031,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1.5),
                                blurRadius: 3,
                              ),
                              Shadow(
                                color: Colors.black.withOpacity(0.15),
                                offset: const Offset(0, 3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          width: screenWidth * 0.16,
                          height: screenWidth * 0.16,
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image_not_supported,
                                color: Colors.white.withOpacity(0.5),
                                size: screenWidth * 0.08,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeCardWithImage(
    BuildContext context,
    String title,
    String imagePath,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: screenWidth * 0.28,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.08),
              blurRadius: 35,
              offset: const Offset(0, 15),
              spreadRadius: 3,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.5),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.15),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: screenWidth * 0.16,
                        height: screenWidth * 0.16,
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: Colors.white.withOpacity(0.5),
                              size: screenWidth * 0.08,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ PELUANG BERSAMA & AGIHAN MANFAAT - FIXED
  // 1. "Lihat Lagi" navigates to Program page
  // 2. Badge only on first card (index 0)

  // Replace _buildPeluangBersama() function
  Widget _buildPeluangBersama(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> peluangItems = [
      {
        'image': 'assets/images/KP5R3.png',
        'badge': 'TERKINI',
        'badgeColor': Color(0xFFFF5252),
        'showBadge': true, // ✅ Only first card has badge
      },
      {
        'image': 'assets/images/IST2.png',
        'badge': 'BARU',
        'badgeColor': Color(0xFF4CAF50),
        'showBadge': false, // ✅ No badge
      },
      {
        'image': 'assets/images/WQT1.png',
        'badge': 'BARU',
        'badgeColor': Color(0xFFF9A825),
        'showBadge': false, // ✅ No badge
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peluang Bersama',
                      style: TextStyle(
                        fontSize: screenWidth * 0.048,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.003),
                    Text(
                      'Jangan lepaskan peluang ini',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF00897B).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // ✅ NAVIGATE TO PROGRAM PAGE
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const ProgramPage(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(25),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Lagi',
                            style: TextStyle(
                              color: const Color(0xFF00897B),
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.035,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFF00897B),
                            size: screenWidth * 0.035,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          SizedBox(
            height: screenHeight * 0.20,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: peluangItems.length,
              itemBuilder: (context, index) {
                return _buildPeluangCard(
                  context,
                  peluangItems[index]['image'],
                  peluangItems[index]['badge'],
                  peluangItems[index]['badgeColor'],
                  peluangItems[index]['showBadge'], // ✅ Pass showBadge flag
                  screenWidth,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Replace _buildPeluangCard() function
  Widget _buildPeluangCard(
    BuildContext context,
    String imagePath,
    String badge,
    Color badgeColor,
    bool showBadge, // ✅ New parameter
    double screenWidth,
  ) {
    return Container(
      width: screenWidth * 0.7,
      margin: EdgeInsets.only(right: screenWidth * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF00897B).withOpacity(0.3),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: screenWidth * 0.12,
                    ),
                  ),
                );
              },
            ),
            // ✅ BADGE ONLY IF showBadge = true
            if (showBadge)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.028,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Replace _buildProgramAgihanManfaat() function
  Widget _buildProgramAgihanManfaat(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> programItems = [
      {
        'image': 'assets/images/CardAM001.png',
        'badge': 'POPULAR',
        'badgeColor': Color(0xFFFF9800),
        'showBadge': true, // ✅ Only first card has badge
      },
      {
        'image': 'assets/images/CardAM002.png',
        'badge': 'BARU',
        'badgeColor': Color(0xFF2196F3),
        'showBadge': false, // ✅ No badge
      },
      {
        'image': 'assets/images/CardAM003.png',
        'badge': 'BARU',
        'badgeColor': Color(0xFF9C27B0),
        'showBadge': false, // ✅ No badge
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agihan Manfaat',
                      style: TextStyle(
                        fontSize: screenWidth * 0.048,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.003),
                    Text(
                      'Rasai manfaatnya bersama kami',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF00897B).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // ✅ NAVIGATE TO PROGRAM PAGE
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const ProgramPage(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(25),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Lagi',
                            style: TextStyle(
                              color: const Color(0xFF00897B),
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.035,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFF00897B),
                            size: screenWidth * 0.035,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          SizedBox(
            height: screenHeight * 0.20,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: programItems.length,
              itemBuilder: (context, index) {
                return _buildProgramCard(
                  context,
                  programItems[index]['image'],
                  programItems[index]['badge'],
                  programItems[index]['badgeColor'],
                  programItems[index]['showBadge'], // ✅ Pass showBadge flag
                  screenWidth,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Replace _buildProgramCard() function
  Widget _buildProgramCard(
    BuildContext context,
    String imagePath,
    String badge,
    Color badgeColor,
    bool showBadge, // ✅ New parameter
    double screenWidth,
  ) {
    return Container(
      width: screenWidth * 0.7,
      margin: EdgeInsets.only(right: screenWidth * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF9A825).withOpacity(0.3),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: screenWidth * 0.12,
                    ),
                  ),
                );
              },
            ),
            // ✅ BADGE ONLY IF showBadge = true
            if (showBadge)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.028,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 0.5, color: Colors.black.withOpacity(0.1));
  }

  // ✅ AYAT HARI INI WITH AUTO-SLIDING CAROUSEL
  // ✅ AYAT HARI INI WITH 5 DIFFERENT BEAUTIFUL CARD DESIGNS
  // Replace _buildAyatHariIni() and _buildAyatCard() functions

  // ✅ AYAT HARI INI WITH AUTO-SLIDING CAROUSEL
  Widget _buildAyatHariIni(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title & Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ' # Ayat Hari Ini',
                style: TextStyle(
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              // Counter badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00897B).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_currentAyatIndex + 1}/${_ayatList.length}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00897B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),

          // PageView with Auto-Sliding
          SizedBox(
            height: screenHeight * 0.20,
            child: PageView.builder(
              controller: _ayatPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentAyatIndex = index;
                });
              },
              itemCount: _ayatList.length,
              itemBuilder: (context, index) {
                return _buildAyatCard(
                  context,
                  _ayatList[index]['ayat']!,
                  _ayatList[index]['source']!,
                  index, // ✅ Pass index to determine card design
                );
              },
            ),
          ),

          SizedBox(height: screenHeight * 0.012),

          // Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _ayatList.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentAyatIndex == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      _currentAyatIndex == index
                          ? _getCardColors(
                            index,
                          )['primary'] // ✅ Matching indicator color
                          : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ GET CARD COLORS BASED ON INDEX
  Map<String, Color> _getCardColors(int index) {
    switch (index) {
      case 0: // Golden Yellow
        return {
          'primary': const Color(0xFFFBC02D),
          'gradient1': const Color(0xFFFDD835),
          'gradient2': const Color(0xFFFBC02D),
        };
      case 1: // Purple Gradient
        return {
          'primary': const Color(0xFF9C27B0),
          'gradient1': const Color(0xFFAB47BC),
          'gradient2': const Color(0xFF8E24AA),
        };
      case 2: // Teal/Cyan
        return {
          'primary': const Color(0xFF00897B),
          'gradient1': const Color(0xFF00BCD4),
          'gradient2': const Color(0xFF00897B),
        };
      case 3: // Orange/Red
        return {
          'primary': const Color(0xFFFF5722),
          'gradient1': const Color(0xFFFF6F00),
          'gradient2': const Color(0xFFFF5722),
        };
      case 4: // Blue Gradient
        return {
          'primary': const Color(0xFF2196F3),
          'gradient1': const Color(0xFF42A5F5),
          'gradient2': const Color(0xFF1976D2),
        };
      default:
        return {
          'primary': const Color(0xFFFBC02D),
          'gradient1': const Color(0xFFFDD835),
          'gradient2': const Color(0xFFFBC02D),
        };
    }
  }
  // ✅ FIXED - NO OVERFLOW ERROR
  // Auto-adjust height for different ayat lengths
  // Replace _buildAyatCard() function only

  Widget _buildAyatCard(
    BuildContext context,
    String ayatText,
    String source,
    int cardIndex,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // ✅ Get colors for this card
    final colors = _getCardColors(cardIndex);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
      padding: EdgeInsets.all(screenWidth * 0.04), // ✅ Reduced padding slightly
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors['gradient1']!, colors['gradient2']!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors['primary']!.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ ROW: Quote Icon + Ayat Text (start)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quote Icon
              Container(
                padding: const EdgeInsets.all(6), // ✅ Smaller padding
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.format_quote_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.05, // ✅ Slightly smaller (was 0.055)
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),

              SizedBox(width: screenWidth * 0.025), // ✅ Smaller gap (was 0.03)
              // Ayat Text (beside icon)
              Expanded(
                child: Text(
                  ayatText,
                  style: TextStyle(
                    fontSize: screenWidth * 0.033, // ✅ Smaller font (was 0.036)
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.4, // ✅ Tighter line height (was 1.45)
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: const Offset(0, 1.5),
                        blurRadius: 3,
                      ),
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  maxLines: 6, // ✅ More lines to prevent overflow (was 5)
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.01), // ✅ Smaller gap (was 0.015)
          // Decorative Line
          Container(
            height: 1.5, // ✅ Thinner (was 2)
            width: screenWidth * 0.15, // ✅ Shorter (was 0.18)
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(height: screenHeight * 0.008), // ✅ Smaller gap (was 0.01)
          // Source Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8, // ✅ Smaller (was 10)
              vertical: 4, // ✅ Smaller (was 5)
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.028, // ✅ Smaller (was 0.03)
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  source,
                  style: TextStyle(
                    fontSize: screenWidth * 0.026, // ✅ Smaller (was 0.028)
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
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
}

// Helper: render SVG if asset exists, otherwise show a fallback Icon
Widget _svgOrFallback(
  String assetPath, {
  double? width,
  double? height,
  BoxFit? fit,
  Color? color,
  BlendMode? colorBlendMode,
}) {
  return FutureBuilder<bool>(
    future: _assetExists(assetPath),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.data == true) {
        return SvgPicture.asset(
          assetPath,
          width: width,
          height: height,
          fit: fit ?? BoxFit.contain,
          color: color,
          colorBlendMode: colorBlendMode ?? BlendMode.srcIn,
        );
      }
      // fallback icon
      return Icon(
        Icons.image_not_supported_rounded,
        size: width ?? height ?? 24,
        color: color ?? Colors.white,
      );
    },
  );
}

Future<bool> _assetExists(String path) async {
  try {
    await rootBundle.load(path);
    return true;
  } catch (_) {
    return false;
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var controlPoint = Offset(size.width / 2, size.height);
    var endPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

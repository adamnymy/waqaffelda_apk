import 'package:flutter/material.dart';
import 'dart:async';
import '../../navbar.dart';
import '../prayertimes/prayertimes.dart';
import '../../services/prayer_times_service.dart';
import 'package:geolocator/geolocator.dart';
import '../zikircounter/zikircounter.dart';
import '../program/program_page.dart';
import '../waqaf/waqafpage.dart';
import '../inbox/inboxpage.dart';
import '../akaun/akaunpage.dart';
import '../doaharian/doa_harian_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/page_transitions.dart';
import 'others_menu_page.dart';
import 'searchpage/search_page.dart';
import '../kiblat/kiblat.dart';
import '../quran/quranpage.dart';
import '../tahlil/tahlil.dart';
import '../hadis40/hadis40.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

int _searchTextIndex = 0;
Timer? _searchTextTimer;
final List<String> _searchSuggestions = [
  'Beramal Quran',
  'Waktu Solat',
  'Arah Kiblat',
  'Al Quran',
  'Doa Harian',
  'Hadith',
];

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;
  int _carouselIndex = 0;
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  // Carousel images moved to class-level so timers can access length
  final List<String> _carouselImages = [
    'assets/images/KP5R3.png', //Kempen Potong Lima
    'assets/images/infak-subuh.png', //Infak Subuh
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
    _loadPrayerTimes();
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
          _prayerTimes = PrayerTimesService.parsePrayerTimes(prayerData);
          _updateNextPrayer();
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

  void _setDefaultCountdown() {
    if (mounted) {
      setState(() {
        _nextPrayerText = 'Solat Seterusnya: Maghrib - 18:30';
        _countdown = const Duration(hours: 1);
      });
    }
    DateTime target = DateTime.now().add(const Duration(hours: 1));
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final remaining = target.difference(DateTime.now());
      if (remaining.inSeconds <= 0) {
        timer.cancel();
        _loadPrayerTimes(); // Try to reload real prayer times
        return;
      }
      if (mounted) {
        setState(() {
          _countdown = remaining;
        });
      }
    });
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
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Stack(
          children: [
            // SMOOTH GRADIENT - No more petak!
            Container(
              height: screenHeight * 0.30 + statusBarHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF66B2B2), // Base Teal (#66b2b2)
                    Color(0xFF99C8C8), // Light Teal
                    Color(0xFFCCDFDF), // Very Light Teal
                    Color(0xFFE6F0F0), // Foggy Teal
                    Color(0xFFFFFFFF), // Pure White
                  ],
                  stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  _buildAppBar(context),
                  SizedBox(height: screenHeight * 0.02),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03,
                    ),
                    child: _buildCompactPrayerCard(context),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  _buildIconMenu(context),
                  SizedBox(height: screenHeight * 0.03),
                  _buildMainCarousel(context),
                  SizedBox(height: screenHeight * 0.03),
                  _buildAyatHariIni(context),
                  SizedBox(height: screenHeight * 0.03),
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Row(
        children: [
          // Logo/Icon
          SvgPicture.asset(
            'assets/icons/logoNg.svg',
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            fit: BoxFit.contain,
          ),
          SizedBox(width: screenWidth * 0.005),
          // Search Bar
          Expanded(
            child: SizedBox(
              width:
                  screenWidth *
                  0.8, // Adjust this value to make it narrower/wider
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
                child: Container(
                  height: screenHeight * 0.045,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(screenWidth * 0.45),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.search, color: Colors.grey.shade600),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                          ) {
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
                                color: Colors.grey.shade500,
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildMainCarousel(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Use class-level _carouselImages so timers and other methods can access
    final List<String> carouselImages = _carouselImages;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peluang Beramal',
                    style: TextStyle(
                      fontSize: screenWidth * 0.048,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Program Terkini',
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.045),
          SizedBox(
            height: screenHeight * 0.2, // Adjusted for 1600x900 aspect ratio
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
                const double activeWidth = 18.0;
                const double inactiveWidth = 6.0;
                const double dotHeight = 6.0;
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
                    borderRadius: BorderRadius.circular(4),
                    color:
                        _carouselIndex == index
                            ? const Color(0xFFFBC02D)
                            : Colors.grey.withOpacity(0.3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(String imagePath, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        child: Image.asset(
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
      ),
    );
  }

  // Redesigned modern prayer card
  Widget _buildCompactPrayerCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Parse current _nextPrayerText which we set to 'Solat Seterusnya: Name - HH:mm'
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
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenHeight * 0.01,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // SVG Background with opacity
            Positioned.fill(
              child: Opacity(
                opacity: 0.9,
                child: SvgPicture.asset(
                  'assets/images/widget-bg-wsolat.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with progress ring and prayer name
                  Row(
                    children: [
                      // Clock icon without progress ring
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.access_time_rounded,
                          color: const Color(0xFF00897B),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SOLAT SETERUSNYA',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextPrayerName.isNotEmpty
                                  ? nextPrayerName.toUpperCase()
                                  : 'MEMUAT...',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: screenWidth * 0.052,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  // Time and countdown section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Prayer Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WAKTU',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: screenWidth * 0.028,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextPrayerTime.isNotEmpty
                                  ? nextPrayerTime
                                  : '--:--',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Countdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'BAKI MASA',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: screenWidth * 0.028,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _countdown.inSeconds >= 0
                                  ? _formatDuration(_countdown)
                                  : 'Loading...',
                              style: TextStyle(
                                color: const Color(0xFF00897B),
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.w800,
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
  }

  Widget _buildIconMenu(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBC02D), Color(0xFFFFA726)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBC02D).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '8',
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF57C00),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: screenWidth * 0.04,
            crossAxisSpacing: screenWidth * 0.04,
            childAspectRatio: 0.85,
            children: [
              _buildMenuItem(
                'Waktu Solat',
                SvgPicture.asset(
                  'assets/icons/menu/waktu_solat.svg',
                  fit: BoxFit.contain,
                ),
                const Color(0xFF00897B),
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const PrayerTimesPage()),
                  );
                },
              ),
              _buildMenuItem(
                'Arah Kiblat',
                SvgPicture.asset(
                  'assets/icons/menu/kiblat.svg',
                  fit: BoxFit.contain,
                ),
                const Color(0xFFFBC02D),
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const KiblatPage()),
                  );
                },
              ),
              _buildMenuItem(
                'Al Qur\'an',
                SvgPicture.asset(
                  'assets/icons/menu/alquran.svg',
                  fit: BoxFit.contain,
                ),
                const Color(0xFF00897B),
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const QuranPage()),
                  );
                },
              ),
              _buildMenuItem(
                'Tasbih',
                SvgPicture.asset(
                  'assets/icons/menu/tasbih.svg',
                  fit: BoxFit.contain,
                ),
                const Color(0xFFFBC02D), // Changed color to green
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const ZikirCounterPage()),
                  );
                },
              ),
              _buildMenuItem(
                'Hadith 40',
                SvgPicture.asset(
                  'assets/icons/menu/hadis.svg',
                  fit: BoxFit.contain,
                ),
                const Color(0xFF00897B),
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const Hadis40Page()),
                  );
                },
              ),
              _buildMenuItem(
                'Doa Harian',
                SvgPicture.asset(
                  'assets/icons/menu/doa.svg',
                  fit: BoxFit.contain,
                ),
                const Color(0xFFFBC02D),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoaHarianPage(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                'Tahlil',
                SvgPicture.asset(
                  'assets/icons/menu/tahlil.svg',
                  fit: BoxFit.contain,
                ),
                const Color(0xFF00897B),
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const TahlilPage()),
                  );
                },
              ),

              _buildMenuItem(
                'Lainnya',
                SvgPicture.asset(
                  'assets/icons/menu/lain_lain.svg',
                  fit: BoxFit.contain,
                ),
                const Color(0xFFFBC02D),
                () {
                  OthersMenuPage.show(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    Widget iconWidget,
    Color color,
    VoidCallback onTap,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final iconSize = constraints.maxWidth * 0.7;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onTap,
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: FittedBox(fit: BoxFit.contain, child: iconWidget),
              ),
            ),
            SizedBox(height: constraints.maxHeight * 0.06),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: screenWidth * 0.028,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAyatHariIni(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ayat Hari Ini',
            style: TextStyle(
              color: const Color(0xFF00897B),
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            '"Dan dirikanlah solat, tunaikanlah zakat, dan ruku\'lah beserta orang-orang yang ruku\'."',
            style: TextStyle(
              color: Colors.black,
              fontSize: screenWidth * 0.04,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            '(Surah Al-Baqarah, Ayat 43)',
            style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50); // Start path
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

import 'package:flutter/material.dart';
import 'dart:async';
import '../../navbar.dart';
import '../prayertimes/prayertimes.dart';
import '../../services/prayer_times_service.dart';
import 'package:geolocator/geolocator.dart';
import '../zikircounter/zikircounter.dart';
import '../navbar_pages/program/program_page.dart';
import '../navbar_pages/waqaf/waqafpage.dart';
import '../navbar_pages/inbox/inboxpage.dart';
import '../navbar_pages/akaun/akaunpage.dart';
import '../quran/quranpage.dart';
import '../kiblat/kiblat.dart';
import '../../utils/page_transitions.dart';
import 'searchpage/search_page.dart'; // Corrected import path for SearchPage

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;
  int _carouselIndex = 0;
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  // Carousel images moved to class-level so timers can access length
  final List<String> _carouselImages = [
    'assets/images/infak_subuh.jpeg',
    'assets/images/waqaf_quran.png',
    'assets/images/infak_spa.png',
    'assets/images/kempen_potong_lima.png',
  ];
  Timer? _carouselTimer; // Auto-scroll timer for the carousel
  String _nextPrayerText = 'Loading...';
  Timer? _timer;
  Timer? _countdownTimer;
  Duration _countdown = Duration.zero;
  Duration? _totalCountdown;
  List<Map<String, dynamic>> _prayerTimes = [];

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _startTimer();
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _carouselTimer?.cancel();
    _countdownTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    // Keep a periodic tick to refresh next-prayer calculation (every second)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
        _totalCountdown = _countdown;
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
      // Expect nextPrayer contains 'name' and 'time' (HH:mm)
      final name = nextPrayer['name'] ?? '';
      final timeStr = nextPrayer['time'] ?? '';

      setState(() {
        _nextPrayerText = 'Solat Seterusnya: $name - $timeStr';
      });

      // Parse time and start countdown
      try {
        final parts = timeStr.split(':');
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
          _countdown = target.difference(now);
          _totalCountdown = _countdown;

          _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
        // ignore parse errors
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

    return Scaffold(
      backgroundColor: Colors.white, // Changed to white
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),

              // App Bar with Search
              _buildAppBar(context),

              SizedBox(height: screenHeight * 0.02),

              // Step 3: Main Carousel
              _buildMainCarousel(context),

              SizedBox(height: screenHeight * 0.03),

              // Step 4: Icon Menu
              _buildIconMenu(context),

              SizedBox(height: screenHeight * 0.03),

              // Step 5: Compact Prayer Time Card (moved below menu)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                ),
                child: _buildCompactPrayerCard(context),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Step 6: Ayat Hari Ini
              _buildAyatHariIni(context),

              SizedBox(height: screenHeight * 0.03),
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

  Widget _buildAppBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Row(
        children: [
          // Logo/Icon
          Container(
            padding: EdgeInsets.all(screenWidth * 0.025),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
            child: Image.asset(
              'assets/images/LogoWaqafer.png',
              height: screenWidth * 0.08,
              width: screenWidth * 0.08,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.mosque,
                  color: Colors.teal,
                  size: screenWidth * 0.08,
                );
              },
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          // Search Bar
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              child: Container(
                height: screenHeight * 0.05,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.search, color: Colors.grey),
                    ),
                    Text(
                      'Search...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ],
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
    // screenWidth not needed here

    // Use class-level _carouselImages so timers and other methods can access
    final List<String> carouselImages = _carouselImages;

    return Column(
      children: [
        SizedBox(
          height: screenHeight * 0.25, // 25% of screen height
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
              color: Colors.teal.withOpacity(0.3),
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
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.015,
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
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with progress ring and prayer name
            Row(
              children: [
                // Progress ring with clock icon
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_totalCountdown != null &&
                          _totalCountdown!.inSeconds > 0)
                        CircularProgressIndicator(
                          value:
                              (_totalCountdown!.inSeconds -
                                  _countdown.inSeconds) /
                              _totalCountdown!.inSeconds,
                          strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFBC02D),
                          ),
                          backgroundColor: Colors.grey.shade200,
                        ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.access_time_rounded,
                          color: Colors.teal.shade600,
                          size: 20,
                        ),
                      ),
                    ],
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
                          color: Colors.grey.shade600,
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
                // Action button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    tooltip: 'Lihat Waktu Solat',
                    onPressed: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(page: const PrayerTimesPage()),
                      );
                    },
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.teal.shade600,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
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
                          color: Colors.grey.shade500,
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextPrayerTime.isNotEmpty ? nextPrayerTime : '--:--',
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
                          color: Colors.grey.shade500,
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _countdown.inSeconds > 0
                            ? _formatDuration(_countdown)
                            : '--:--:--',
                        style: TextStyle(
                          color: Colors.teal.shade600,
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
    );
  }

  Widget _buildIconMenu(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: screenWidth * 0.03,
        crossAxisSpacing: screenWidth * 0.03,
        children: [
          _buildMenuItem(
            'Waktu Solat',
            Icons.access_time_outlined,
            Colors.teal,
            () {
              Navigator.push(
                context,
                SmoothPageRoute(page: const PrayerTimesPage()),
              );
            },
          ),
          _buildMenuItem(
            'Arah Kiblat',
            Icons.explore_outlined,
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
            Icons.menu_book_outlined,
            Colors.teal,
            () {
              Navigator.push(context, SmoothPageRoute(page: const QuranPage()));
            },
          ),
          _buildMenuItem(
            'Tasbih',
            Icons.cable_outlined, // Changed icon
            const Color(0xFFFBC02D), // Changed color to green
            () {
              Navigator.push(
                context,
                SmoothPageRoute(page: const ZikirCounterPage()),
              );
            },
          ),
          _buildMenuItem('Hadith 40', Icons.book_outlined, Colors.teal, () {}),
          _buildMenuItem(
            'Doa',
            Icons.volunteer_activism_outlined,
            const Color(0xFFFBC02D),
            () {},
          ),
          _buildMenuItem(
            'Kegemaran',
            Icons.favorite_outline,
            Colors.teal,
            () {},
          ),
          _buildMenuItem(
            'Lainnya',
            Icons.apps_outlined,
            const Color(0xFFFBC02D),
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final iconSize = constraints.maxWidth * 0.4; // 40% of available width

        return GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(constraints.maxWidth * 0.15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(height: constraints.maxHeight * 0.08),
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
          ),
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
              color: Colors.teal,
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

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
  String _nextPrayerText = 'Loading...';
  String _currentTime = '';
  Timer? _timer;
  List<Map<String, dynamic>> _prayerTimes = [];

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
      _updateNextPrayer();
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (mounted) {
      setState(() {
        _currentTime = timeString;
      });
    }
  }

  Future<void> _loadPrayerTimes() async {
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
        }
      }
    } catch (e) {
      print('Error loading prayer times for homepage: $e');
      if (mounted) {
        setState(() {
          _nextPrayerText = 'Prayer times unavailable';
        });
      }
    }
  }

  void _updateNextPrayer() {
    if (_prayerTimes.isEmpty) return;

    final nextPrayer = PrayerTimesService.getNextPrayer(_prayerTimes);
    if (nextPrayer != null && mounted) {
      setState(() {
        _nextPrayerText =
            'Next Prayer: ${nextPrayer['name']} - ${nextPrayer['time']}';
      });
    }
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
    final screenWidth = MediaQuery.of(context).size.width;

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

              // Step 4: Wallet and Prayer Times
              _buildWalletAndPrayerInfo(context),

              SizedBox(height: screenHeight * 0.035),

              // Step 5: Icon Menu
              _buildIconMenu(context),

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
          SizedBox(width: screenWidth * 0.03),
          // Notification Icon
          Container(
            padding: EdgeInsets.all(screenWidth * 0.025),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            child: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: Colors.grey[700],
                  size: screenWidth * 0.06,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: screenWidth * 0.015,
                      minHeight: screenWidth * 0.015,
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

  Widget _buildMainCarousel(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final List<String> carouselImages = [
      'assets/images/infak_subuh.jpeg',
      'assets/images/waqaf_quran.png',
      'assets/images/infak_spa.png',
      'assets/images/kempen_potong_lima.png',
    ];

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
            },
            itemCount: carouselImages.length,
            itemBuilder: (context, index) {
              return _buildCarouselCard(carouselImages[index], context);
            },
          ),
        ),
        SizedBox(height: screenHeight * 0.015),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carouselImages.length,
            (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
              width:
                  _carouselIndex == index
                      ? screenWidth * 0.06
                      : screenWidth * 0.02,
              height: screenHeight * 0.01,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color:
                    _carouselIndex == index
                        ? Colors.teal
                        : Colors.grey.withOpacity(0.3),
              ),
            ),
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

  Widget _buildWalletAndPrayerInfo(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Parse next prayer details
    String nextPrayerName = 'Loading...';
    String nextPrayerTime = '';

    if (_nextPrayerText.contains(':') &&
        _nextPrayerText != 'Loading...' &&
        _nextPrayerText != 'Prayer times unavailable') {
      final parts = _nextPrayerText
          .replaceAll('Next Prayer: ', '')
          .split(' - ');
      if (parts.length == 2) {
        nextPrayerName = parts[0];
        nextPrayerTime = parts[1];
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.025),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.06,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Flexible(
                child: Text(
                  'Waktu Solat Akan Datang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.025),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextPrayerName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      ),
                      child: Text(
                        _currentTime.isEmpty ? 'Loading...' : _currentTime,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Waktu',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                  Text(
                    nextPrayerTime.isEmpty ? '--:--' : nextPrayerTime,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.01,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                  size: screenWidth * 0.035,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  '30 Rabiul Akhir 1447 H',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: screenWidth * 0.032,
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

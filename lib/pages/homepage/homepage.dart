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

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;
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
    return Scaffold(
      backgroundColor: Colors.white, // Changed to white
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 2: New Header
              _buildHeader(),

              const SizedBox(height: 24),

              // Step 3: Main Carousel
              _buildMainCarousel(),

              const SizedBox(height: 24),

              // Step 4: Wallet and Prayer Times
              _buildWalletAndPrayerInfo(),

              const SizedBox(height: 28),

              // Step 5: Icon Menu
              _buildIconMenu(),

              const SizedBox(height: 24),

              // Step 6: Second Banner
              _buildSecondaryBanner(),

              const SizedBox(height: 24),
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

  // Placeholder widgets for the new structure
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/LogoWaqafer.png',
              height: 24,
              width: 24,
            ),
          ),
          // Search Bar
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Sedekah Subuh',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.teal), // Changed color
                ),
              ),
            ),
          ),
          // Action Icons
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.teal,
                ), // Changed color
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.favorite_border,
                  color: Colors.teal,
                ), // Changed color
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainCarousel() {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Color(0xFFFBC02D)], // Teal to Golden Yellow
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // PageView for multiple banners
            PageView(
              children: [
                _buildCarouselItem(
                  'Wujudkan Masjid\nBersih & Sejahtera',
                  'Cahaya Iman Bermula dari\nMasjid yang Bersinar',
                  'assets/images/masjidnegara.jpg', // Using available image
                ),
                // Add more items here if needed
              ],
            ),
            // Dots indicator
            Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselItem(String title, String subtitle, String imagePath) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 40),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Wujudkan Disini',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.image_not_supported,
                  color: Colors.white,
                  size: 50,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletAndPrayerInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/images/LogoWaqafer.png', // Using app logo as placeholder
                      height: 20,
                      width: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Saku kebaikanmu',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Isi saldo'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _nextPrayerText.replaceAll('Next Prayer: ', ''),
                    style: TextStyle(color: Colors.grey[800], fontSize: 14),
                  ),
                ],
              ),
              Text(
                '30 Rabiul Akhir 1447 H', // Example date
                style: TextStyle(color: Colors.grey[800], fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _buildMenuItem(
            'Tabungan Qurban',
            Icons.savings_outlined,
            Colors.teal, // Changed color
            () {},
          ),
          _buildMenuItem(
            'Sedekah Rutin',
            Icons.autorenew,
            const Color(0xFFFBC02D), // Changed color
            () {},
          ),
          _buildMenuItem(
            'Zakat',
            Icons.account_balance_wallet_outlined,
            Colors.teal, // Changed color
            () {},
          ),
          _buildMenuItem(
            'Al Qur\'an',
            Icons.menu_book_outlined,
            const Color(0xFFFBC02D), // Changed color
            () {
              Navigator.pushReplacement(
                context,
                SmoothPageRoute(page: const QuranPage()),
              );
            },
          ),
          _buildMenuItem(
            'Hadits',
            Icons.book_outlined,
            Colors.teal, // Changed color
            () {},
          ),
          _buildMenuItem(
            'Waktu Sholat',
            Icons.access_time_outlined,
            const Color(0xFFFBC02D), // Changed color
            () {
              Navigator.pushReplacement(
                context,
                SmoothPageRoute(page: const PrayerTimesPage()),
              );
            },
          ),
          _buildMenuItem(
            'Dzikir',
            Icons.wb_sunny_outlined,
            Colors.teal, // Changed color
            () {},
          ),
          _buildMenuItem(
            'Lainnya',
            Icons.apps_outlined,
            const Color(0xFFFBC02D), // Changed color
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.teal, Color(0xFFFBC02D)], // Teal to Golden Yellow
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Santri Berdaya,\nIndonesia Berjaya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Mari terus dukung perjuangan mereka menjaga Al-Qur\'an',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('YUK MULIAKAN MERAKA'),
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

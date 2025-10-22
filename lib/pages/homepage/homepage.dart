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
              const SizedBox(height: 16),

              // Step 3: Main Carousel
              _buildMainCarousel(),

              const SizedBox(height: 24),

              // Step 4: Wallet and Prayer Times
              _buildWalletAndPrayerInfo(),

              const SizedBox(height: 28),

              // Step 5: Icon Menu
              _buildIconMenu(),

              const SizedBox(height: 24),

              // Step 6: Ayat Hari Ini
              _buildAyatHariIni(),

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

  Widget _buildMainCarousel() {
    return SizedBox(
      height: 238,
      child: PageView(
        children: [
          _buildCarouselCard(
            'INFAK SUBUH',
            'KEUTAMAAN SEDEKAH SUBUH :',
            'MENDAPAT DOA MALAIKAT',
            '"Tidak ada satu hari pun bagi seorang hamba, kecuali datang dua malaikat yang salah satu dari mereka berdoa, \'Ya Allah berilah ganti yang lebih baik bagi orang yang bersedekah.\'"',
            'Mafhum Hadis',
            'assets/images/infak_subuh.jpeg',
          ),
          _buildCarouselCard(
            'WAQAF AL-QURAN',
            'Berserta terjemahan,',
            'tajwid, dan panduan',
            'berhenti serta memulakan bacaan.',
            'IMBAS UNTUK WAKAF QURAN',
            'assets/images/waqaf_quran.jpeg',
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(
    String mainTitle,
    String subtitle1,
    String subtitle2,
    String description,
    String footer,
    String imagePath,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.teal.withOpacity(0.3),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            );
          },
        ),
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
            const Color(0xFF4CAF50), // Changed color to green
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

  Widget _buildAyatHariIni() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          const Text(
            'Ayat Hari Ini',
            style: TextStyle(
              color: Colors.teal,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '"Dan dirikanlah solat, tunaikanlah zakat, dan ruku\'lah beserta orang-orang yang ruku\'."',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '(Surah Al-Baqarah, Ayat 43)',
            style: TextStyle(color: Colors.grey, fontSize: 14),
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

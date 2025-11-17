import 'package:flutter/material.dart';
import '../prayertimes/prayertimes.dart';
import '../kiblat/kiblat.dart';
import '../quran/quranpage.dart';
import '../zikircounter/zikircounter.dart';
import '../../utils/page_transitions.dart';
import '../doaharian/doa_harian_page.dart';
import '../tahlil/tahlil.dart';
import '../masjid_terdekat/masjid_terdekat.dart';
import '../hadis40/hadis40.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OthersMenuPage extends StatelessWidget {
  const OthersMenuPage({Key? key}) : super(key: key);

  // Show as modal bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OthersMenuPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: screenHeight * 0.92,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF00897B), const Color(0xFF4DB6AC)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.05,
              12,
              screenWidth * 0.05,
              20,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.dashboard_customize_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Menu Utama',
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Akses pantas ke semua ciri aplikasi',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content area with white background
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured section (top 2 items - larger)
                    Text(
                      'Pintasan',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeaturedCard(
                            context,
                            'Waktu Solat',
                            'assets/icons/menu/waktu_solat.svg',
                            const Color(0xFF00897B),
                            const Color(0xFF00897B).withOpacity(0.1),
                            () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                SmoothPageRoute(page: const PrayerTimesPage()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeaturedCard(
                            context,
                            'Al Qur\'an',
                            'assets/icons/menu/alquran.svg',
                            const Color(0xFF00897B),
                            const Color(0xFF00897B).withOpacity(0.1),
                            () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                SmoothPageRoute(page: const QuranPage()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // All menus section
                    Text(
                      'Semua Menu',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCompactMenuItem(
                      context,
                      'Arah Kiblat',
                      'Cari arah kiblat dengan mudah',
                      'assets/icons/menu/kiblat.svg',
                      const Color(0xFFFF6F00),
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const KiblatPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildCompactMenuItem(
                      context,
                      'Tasbih',
                      'Kira zikir digital',
                      'assets/icons/menu/tasbih.svg',
                      const Color(0xFF5E35B1),
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const ZikirCounterPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildCompactMenuItem(
                      context,
                      'Doa Harian',
                      'Koleksi doa harian',
                      'assets/icons/menu/doa.svg',
                      const Color(0xFFE53935),
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DoaHarianPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildCompactMenuItem(
                      context,
                      'Hadith 40',
                      'Hadith Nawawi',
                      'assets/icons/menu/hadis.svg',
                      const Color(0xFF1976D2),
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const Hadis40Page()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildCompactMenuItem(
                      context,
                      'Tahlil',
                      'Bacaan tahlil lengkap',
                      'assets/icons/menu/tahlil.svg',
                      const Color(0xFF00897B),
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const TahlilPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildCompactMenuItem(
                      context,
                      'Masjid Terdekat',
                      'Cari masjid berhampiran',
                      'assets/icons/menu/masjid.svg',
                      const Color(0xFF43A047),
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const MasjidTerdekatPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildCompactMenuItem(
                      context,
                      'Kalender Islam',
                      'Kalendar Hijriah',
                      'assets/icons/menu/kalendar_islam.svg',
                      const Color(0xFFFBC02D),
                      () {
                        Navigator.pop(context);
                        // TODO: Navigate to Islamic calendar page
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Featured card - larger, more prominent
  Widget _buildFeaturedCard(
    BuildContext context,
    String title,
    String iconPath,
    Color primaryColor,
    Color backgroundColor,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color:
                (title == 'Waktu Solat' || title == 'Al Qur\'an')
                    ? Colors.transparent
                    : primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Background SVG (for Waktu Solat and Al Qur'an)
              if (title == 'Waktu Solat')
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SvgPicture.asset(
                      'assets/icons/menu/waktu_solat-bg.svg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (title == 'Al Qur\'an')
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SvgPicture.asset(
                      'assets/icons/menu/alquran-bg.svg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              // Decorative circle (for cards without background)
              if (title != 'Waktu Solat' && title != 'Al Qur\'an')
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (title != 'Waktu Solat' && title != 'Al Qur\'an')
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SvgPicture.asset(
                          iconPath,
                          width: 48,
                          height: 48,
                        ),
                      ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
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

  // Compact menu item - list style with icon, title, subtitle
  Widget _buildCompactMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    String iconPath,
    Color color,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: SvgPicture.asset(iconPath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

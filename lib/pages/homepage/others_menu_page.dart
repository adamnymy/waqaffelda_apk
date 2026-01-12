import 'package:flutter/material.dart';
import '../prayertimes/prayertimes.dart';
import '../kiblat/kiblat.dart';
import '../quran/quranpage.dart';
import '../zikircounter/zikircounter.dart';
import '../doaharian/doa_harian_page.dart';
import '../tahlil/tahlil.dart';
import '../masjid_terdekat/masjid_terdekat.dart';
import '../hadis40/hadis40.dart';
import '../kalendar/kalendar_islam.dart';

class OthersMenuPage extends StatelessWidget {
  const OthersMenuPage({Key? key}) : super(key: key);

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
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu Utama',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: 8,
              ),
              children: [
                // Ibadah Section
                _buildSectionHeader('Ibadah', Icons.mosque_outlined),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Waktu Solat',
                  description: 'Jadual waktu solat harian berdasarkan lokasi anda',
                  icon: Icons.access_time_rounded,
                  iconBgColor: const Color(0xFF00897B),
                  page: const PrayerTimesPage(),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Arah Kiblat',
                  description: 'Cari arah kiblat dengan mudah menggunakan kompas digital',
                  icon: Icons.explore_rounded,
                  iconBgColor: const Color(0xFFFF6F00),
                  page: const KiblatPage(),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Tasbih Digital',
                  description: 'Kira zikir dan tasbih dengan mudah secara digital',
                  icon: Icons.timer_outlined,
                  iconBgColor: const Color(0xFF5E35B1),
                  page: const ZikirCounterPage(),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Doa Harian',
                  description: 'Koleksi doa harian lengkap untuk amalan seharian',
                  icon: Icons.auto_stories_rounded,
                  iconBgColor: const Color(0xFFE53935),
                  page: const DoaHarianPage(),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Bacaan Tahlil',
                  description: 'Panduan bacaan tahlil lengkap dengan terjemahan',
                  icon: Icons.people_outline_rounded,
                  iconBgColor: const Color(0xFF00897B),
                  page: const TahlilPage(),
                ),
                
                const SizedBox(height: 24),
                
                // Al-Quran & Ilmu
                _buildSectionHeader('Al-Quran & Ilmu', Icons.menu_book_rounded),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Al-Quran',
                  description: 'Baca Al-Quran dengan terjemahan dan tafsir lengkap',
                  icon: Icons.menu_book,
                  iconBgColor: const Color(0xFF1565C0),
                  page: const QuranPage(),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Hadith 40',
                  description: 'Hadith 40 Imam Nawawi dengan terjemahan Bahasa Melayu',
                  icon: Icons.import_contacts_rounded,
                  iconBgColor: const Color(0xFF1976D2),
                  page: const Hadis40Page(),
                ),
                
                const SizedBox(height: 24),
                
                // Kemudahan
                _buildSectionHeader('Kemudahan', Icons.location_on_outlined),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Masjid Terdekat',
                  description: 'Cari masjid atau surau yang berhampiran dengan lokasi anda',
                  icon: Icons.mosque,
                  iconBgColor: const Color(0xFF43A047),
                  page: const MasjidTerdekatPage(),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Kalendar Islam',
                  description: 'Kalendar Hijriah dengan peristiwa penting Islam',
                  icon: Icons.calendar_month_rounded,
                  iconBgColor: const Color(0xFFFBC02D),
                  page: const KalendarIslamPage(),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color iconBgColor,
    required Widget page,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconBgColor,
                      iconBgColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconBgColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
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

class MenuItemData {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBgColor;
  final Widget page;

  MenuItemData({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBgColor,
    required this.page,
  });
}

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
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                    decoration: TextDecoration.none,
                    fontFamily: 'Inter',
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
            child: DefaultTextStyle(
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.black87,
                decoration: TextDecoration.none,
              ),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: 8,
                ),
                children: [
                  // Ibadah Section
                  _buildSection(
                    context,
                    title: 'Ibadah',
                    icon: Icons.mosque_outlined,
                    items: [
                      MenuItemData(
                        title: 'Waktu Solat',
                        description: 'Jadual waktu solat harian',
                        icon: Icons.access_time_rounded,
                        iconBgColor: const Color(0xFF4B5563),
                        page: const PrayerTimesPage(),
                      ),
                      MenuItemData(
                        title: 'Arah Kiblat',
                        description: 'Cari arah kiblat dengan mudah',
                        icon: Icons.explore_rounded,
                        iconBgColor: const Color(0xFF5D6B7A),
                        page: const KiblatPage(),
                      ),
                      MenuItemData(
                        title: 'Tasbih Digital',
                        description: 'Kira zikir dan tasbih',
                        icon: Icons.repeat_rounded,
                        iconBgColor: const Color(0xFF6F7A8B),
                        page: const ZikirCounterPage(),
                      ),
                      MenuItemData(
                        title: 'Doa Harian',
                        description: 'Koleksi doa harian lengkap',
                        icon: Icons.auto_stories_rounded,
                        iconBgColor: const Color(0xFF818C9A),
                        page: const DoaHarianPage(),
                      ),
                      MenuItemData(
                        title: 'Bacaan Tahlil',
                        description: 'Panduan bacaan tahlil',
                        icon: Icons.people_outline_rounded,
                        iconBgColor: const Color(0xFF929DAA),
                        page: const TahlilPage(),
                      ),
                    ],
                    screenWidth: screenWidth,
                  ),
                  const SizedBox(height: 24),

                  // Al-Quran & Ilmu Section
                  _buildSection(
                    context,
                    title: 'Al-Quran & Ilmu',
                    icon: Icons.menu_book_rounded,
                    items: [
                      MenuItemData(
                        title: 'Al-Quran',
                        description: 'Baca Al-Quran dengan terjemahan',
                        icon: Icons.auto_stories_rounded,
                        iconBgColor: const Color(0xFF4B5563),
                        page: const QuranPage(),
                      ),
                      MenuItemData(
                        title: 'Hadith 40',
                        description: 'Hadith 40 Imam Nawawi',
                        icon: Icons.book_rounded,
                        iconBgColor: const Color(0xFF5D6B7A),
                        page: const Hadis40Page(),
                      ),
                    ],
                    screenWidth: screenWidth,
                  ),
                  const SizedBox(height: 24),

                  // Kemudahan Section
                  _buildSection(
                    context,
                    title: 'Kemudahan',
                    icon: Icons.location_on_outlined,
                    items: [
                      MenuItemData(
                        title: 'Masjid Terdekat',
                        description: 'Cari masjid atau surau',
                        icon: Icons.mosque,
                        iconBgColor: const Color(0xFF6F7A8B),
                        page: const MasjidTerdekatPage(),
                      ),
                      MenuItemData(
                        title: 'Kalendar Islam',
                        description: 'Kalendar Hijriah',
                        icon: Icons.calendar_month_rounded,
                        iconBgColor: const Color(0xFF818C9A),
                        page: const CombinedCalendarPage(),
                      ),
                    ],
                    screenWidth: screenWidth,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<MenuItemData> items,
    required double screenWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                  decoration: TextDecoration.none,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Menu items in grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: screenWidth * 0.04,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildMenuCardCompact(
              context: context,
              data: item,
              screenWidth: screenWidth,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuCardCompact({
    required BuildContext context,
    required MenuItemData data,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => data.page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.iconBgColor.withOpacity(0.15),
              ),
              child: Icon(
                data.icon,
                size: screenWidth * 0.06,
                color: data.iconBgColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: Text(
                data.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                  decoration: TextDecoration.none,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: screenWidth * 0.024,
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.none,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

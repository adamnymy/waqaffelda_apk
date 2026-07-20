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

const _gold = Color(0xFFC49B28);
const _goldLight = Color(0xFFF5EDD5);
const _goldBorder = Color(0xFFD4B896);
const _textDark = Color(0xFF3A3A5C);

class MenuItemData {
  final String title;
  final String description;
  final String imagePath;
  final Widget page;

  MenuItemData({
    required this.title,
    required this.description,
    required this.imagePath,
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

  static const _sections = [
    {
      'title': 'Ibadah',
      'icon': Icons.mosque_outlined,
    },
    {
      'title': 'Al-Quran & Ilmu',
      'icon': Icons.menu_book_rounded,
    },
    {
      'title': 'Kemudahan',
      'icon': Icons.location_on_outlined,
    },
  ];

  List<List<MenuItemData>> _getItems() => [
        // Ibadah
        [
          MenuItemData(
            title: 'Waktu Solat',
            description: 'Jadual waktu solat harian',
            imagePath: 'assets/images/solat_newtest2.png',
            page: const PrayerTimesPage(),
          ),
          MenuItemData(
            title: 'Arah Kiblat',
            description: 'Cari arah kiblat dengan mudah',
            imagePath: 'assets/images/kaabah_newtest2.png',
            page: const KiblatPage(),
          ),
          MenuItemData(
            title: 'Tasbih Digital',
            description: 'Kira zikir dan tasbih',
            imagePath: 'assets/images/tasbih_newtest.png',
            page: const ZikirCounterPage(),
          ),
          MenuItemData(
            title: 'Doa Harian',
            description: 'Koleksi doa harian lengkap',
            imagePath: 'assets/images/bacaan_doa.png',
            page: const DoaHarianPage(),
          ),
          MenuItemData(
            title: 'Bacaan Tahlil',
            description: 'Panduan bacaan tahlil',
            imagePath: 'assets/images/bacaan_tahlil.png',
            page: const TahlilPage(),
          ),
        ],
        // Al-Quran & Ilmu
        [
          MenuItemData(
            title: "Al-Quran",
            description: "Baca Al-Quran dengan terjemahan",
            imagePath: 'assets/images/Quran_newTest3.png',
            page: const QuranPage(),
          ),
          MenuItemData(
            title: 'Hadith 40',
            description: 'Hadith 40 Imam Nawawi',
            imagePath: 'assets/images/Hadith_newTest.png',
            page: const Hadis40Page(),
          ),
        ],
        // Kemudahan
        [
          MenuItemData(
            title: 'Masjid Terdekat',
            description: 'Cari masjid atau surau',
            imagePath: 'assets/images/masjid_terdekat.png',
            page: const MasjidTerdekatPage(),
          ),
          MenuItemData(
            title: 'Kalendar Islam',
            description: 'Kalendar Hijriah',
            imagePath: 'assets/images/calendar_hijrah.png',
            page: const CombinedCalendarPage(),
          ),
        ],
      ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final allSections = _getItems();

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8F3),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
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
              color: _goldBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Menu Utama',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      fontFamily: 'Inter',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _goldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close, size: 18, color: _gold),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(height: 1, color: _goldBorder.withOpacity(0.3)),
          // Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _sections.length,
              itemBuilder: (context, sectionIndex) {
                final section = _sections[sectionIndex];
                final items = allSections[sectionIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _gold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              section['icon'] as IconData,
                              size: 16,
                              color: _gold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              section['title'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _gold,
                                fontFamily: 'Inter',
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Items
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: _goldBorder.withOpacity(0.4), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: List.generate(items.length, (i) {
                            final item = items[i];
                            final isLast = i == items.length - 1;
                            return _buildListTile(context, item, isLast);
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
      BuildContext context, MenuItemData item, bool isLast) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item.page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: _goldBorder.withOpacity(0.25), width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _goldLight,
                border: Border.all(color: _goldBorder, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.widgets_rounded,
                    color: _gold,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      fontFamily: 'Inter',
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: 'Inter',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right_rounded,
                size: 20, color: _goldBorder),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../prayertimes/prayertimes.dart';
import '../../kiblat/kiblat.dart';
import '../../quran/quranpage.dart';
import '../../zikircounter/zikircounter.dart';
import '../../hadis40/hadis40.dart';
import '../others_menu_page.dart';

class MenuGridWidget extends StatelessWidget {
  const MenuGridWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final List<Map<String, dynamic>> menuItems = [
      {
        'name': 'Waktu Solat',
        'icon': Icons.access_time_rounded,
        'color': const Color(0xFF4B5563),
        'page': const PrayerTimesPage(),
      },
      {
        'name': 'Arah Kiblat',
        'icon': Icons.explore_rounded,
        'color': const Color(0xFF5D6B7A),
        'page': const KiblatPage(),
      },
      {
        'name': 'Al Quran',
        'icon': Icons.auto_stories_rounded,
        'color': const Color(0xFF6F7A8B),
        'page': const QuranPage(),
      },
      {
        'name': 'Tasbih',
        'icon': Icons.repeat_rounded,
        'color': const Color(0xFF818C9A),
        'page': const ZikirCounterPage(),
      },
      {
        'name': 'Hadith 40',
        'icon': Icons.book_rounded,
        'color': const Color(0xFF929DAA),
        'page': const Hadis40Page(),
      },
      {
        'name': 'Lihat Lagi',
        'icon': Icons.arrow_forward_ios_rounded,
        'color': const Color(0xFFA4AFBA),
        'page': const OthersMenuPage(),
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: screenWidth * 0.04,
          mainAxisSpacing: screenHeight * 0.02,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _buildMenuCard(
            context: context,
            name: item['name'],
            icon: item['icon'],
            color: item['color'],
            page: item['page'],
            screenWidth: screenWidth,
          );
        },
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String name,
    required IconData icon,
    required Color color,
    required Widget page,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => page,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: screenWidth * 0.16,
              height: screenWidth * 0.16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, size: screenWidth * 0.08, color: color),
            ),
            SizedBox(height: screenWidth * 0.04),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: screenWidth * 0.026,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

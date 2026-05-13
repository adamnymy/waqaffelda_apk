import 'package:flutter/material.dart';
import '../../../utils/page_transitions.dart';
import '../../prayertimes/prayertimes.dart';
import '../../kiblat/kiblat.dart';
import '../../quran/quranpage.dart';
import '../../zikircounter/zikircounter.dart';
import '../../hadis40/hadis40.dart';
import '../others_menu_page.dart';

class MenuGridWidget extends StatelessWidget {
  const MenuGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Waktu Solat',
        'image': 'assets/images/solat_newtest2.png',
        'onTap':
            () => Navigator.push(
              context,
              SmoothPageRoute(page: const PrayerTimesPage()),
            ),
      },
      {
        'title': 'Arah Kiblat',
        'image': 'assets/images/kaabah_newtest2.png',
        'onTap':
            () => Navigator.push(
              context,
              SmoothPageRoute(page: const KiblatPage()),
            ),
      },
      {
        'title': "Al Qur'an",
        'image': 'assets/images/Quran_newTest3.png',
        'onTap':
            () => Navigator.push(
              context,
              SmoothPageRoute(page: const QuranPage()),
            ),
      },
      {
        'title': 'Tasbih',
        'image': 'assets/images/tasbih_newtest.png',
        'onTap':
            () => Navigator.push(
              context,
              SmoothPageRoute(page: const ZikirCounterPage()),
            ),
      },
      {
        'title': 'Hadith 40',
        'image': 'assets/images/Hadith_newTest.png',
        'onTap':
            () => Navigator.push(
              context,
              SmoothPageRoute(page: const Hadis40Page()),
            ),
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: 3 items
          Row(
            children: [
              Expanded(
                child: _buildItem(
                  context,
                  menuItems[0],
                  screenWidth,
                  screenHeight,
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: _buildItem(
                  context,
                  menuItems[1],
                  screenWidth,
                  screenHeight,
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: _buildItem(
                  context,
                  menuItems[2],
                  screenWidth,
                  screenHeight,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          // Row 2: 2 items + Lihat Lagi
          Row(
            children: [
              Expanded(
                child: _buildItem(
                  context,
                  menuItems[3],
                  screenWidth,
                  screenHeight,
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: _buildItem(
                  context,
                  menuItems[4],
                  screenWidth,
                  screenHeight,
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: _buildMoreItem(context, screenWidth, screenHeight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    Map<String, dynamic> item,
    double screenWidth,
    double screenHeight,
  ) {
    return GestureDetector(
      onTap: item['onTap'] as VoidCallback,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.018,
          horizontal: screenWidth * 0.018,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5EDD5),
                border: Border.all(color: const Color(0xFFD4B896), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Image.asset(
                  item['image'] as String,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => Icon(
                        Icons.widgets_rounded,
                        color: const Color(0xFFC49B28),
                        size: 18,
                      ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            Text(
              item['title'] as String,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3A3A5C),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreItem(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return GestureDetector(
      onTap: () => OthersMenuPage.show(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.018,
          horizontal: screenWidth * 0.018,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5EDD5),
                border: Border.all(color: const Color(0xFFD4B896), width: 1.5),
              ),
              child: Icon(
                Icons.apps_rounded,
                color: const Color(0xFFC49B28),
                size: screenWidth * 0.055,
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            Text(
              'Lihat Lagi',
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFC49B28),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../utils/page_transitions.dart';
import '../../prayertimes/prayertimes.dart';
import '../../kiblat/kiblat.dart';
import '../../quran/quranpage.dart';
import '../../zikircounter/zikircounter.dart';
import '../../hadis40/hadis40.dart';
import '../others_menu_page.dart';

class MenuGridWidgetNew extends StatelessWidget {
  const MenuGridWidgetNew({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.018),
          // 3-Column Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: screenWidth * 0.05,
            mainAxisSpacing: screenHeight * 0.02,
            childAspectRatio: 0.95,
            children: [
              _buildGridItem(
                context,
                'Waktu Solat',
                Icons.schedule_rounded,
                Colors.teal,
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const PrayerTimesPage()),
                  );
                },
              ),
              _buildGridItem(
                context,
                'Arah Kiblat',
                Icons.navigation_rounded,
                Colors.amber,
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const KiblatPage()),
                  );
                },
              ),
              _buildGridItem(
                context,
                'Al-Quran',
                Icons.book_rounded,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const QuranPage()),
                  );
                },
              ),
              _buildGridItem(
                context,
                'Tasbih',
                Icons.blur_on_rounded,
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const ZikirCounterPage()),
                  );
                },
              ),
              _buildGridItem(
                context,
                'Hadith 40',
                Icons.library_books_rounded,
                Colors.pink,
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const Hadis40Page()),
                  );
                },
              ),
              _buildGridItem(
                context,
                'Lihat Lagi',
                Icons.more_horiz_rounded,
                Colors.grey,
                () {
                  OthersMenuPage.show(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.035),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: screenWidth * 0.065,
                color: color,
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.032,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

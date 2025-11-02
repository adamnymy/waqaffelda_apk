import 'package:flutter/material.dart';
import '../prayertimes/prayertimes.dart';
import '../kiblat/kiblat.dart';
import '../quran/quranpage.dart';
import '../zikircounter/zikircounter.dart';
import '../../utils/page_transitions.dart';
import '../doaharian/doa_harian_page.dart';

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
      height: screenHeight * 0.85, // 85% of screen height
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade50, Colors.white],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: 20,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semua Menu',
                        style: TextStyle(
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Pilih menu untuk meneruskan',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Menu list
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context,
                  'Waktu Solat',
                  Icons.access_time_outlined,
                  Colors.teal,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const PrayerTimesPage()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  'Arah Kiblat',
                  Icons.explore_outlined,
                  const Color(0xFFFBC02D),
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const KiblatPage()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  'Al Qur\'an',
                  Icons.menu_book_outlined,
                  Colors.teal,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const QuranPage()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  'Tasbih',
                  Icons.cable_outlined,
                  const Color(0xFFFBC02D),
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const ZikirCounterPage()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  'Hadith 40',
                  Icons.book_outlined,
                  Colors.teal,
                  () {
                    Navigator.pop(context);
                    // TODO: Navigate to Hadith page
                  },
                ),
                _buildMenuItem(
                  context,
                  'Doa Harian',
                  Icons.volunteer_activism_outlined,
                  const Color(0xFFFBC02D),
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
                _buildMenuItem(
                  context,
                  'Tahlil',
                  Icons.auto_stories,
                  Colors.teal,
                  () {
                    Navigator.pop(context);
                    // TODO: Navigate to Tahlil page
                  },
                ),
                _buildMenuItem(
                  context,
                  'Kalender Islam',
                  Icons.calendar_month_outlined,
                  Colors.teal,
                  () {
                    Navigator.pop(context);
                    // TODO: Navigate to Islamic calendar page
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

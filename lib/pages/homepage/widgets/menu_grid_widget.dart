import 'package:flutter/material.dart';
import '../../../utils/page_transitions.dart';
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00897B).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => OthersMenuPage.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.032,
                        vertical: screenHeight * 0.008,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Lagi',
                            style: TextStyle(
                              color: const Color(0xFF00897B),
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.031,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.012),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFF00897B),
                            size: screenWidth * 0.031,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.035),
          // Row 1: Waktu Solat + Arah Kiblat
          Row(
            children: [
              Expanded(
                child: _buildLargeCard(
                  context,
                  'Waktu Solat',
                  'assets/images/solat_newtest2.png',
                  const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00897B),
                      Color(0xFF26A69A),
                      Color(0xFF4DB6AC),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const PrayerTimesPage()),
                    );
                  },
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: _buildLargeCard(
                  context,
                  'Arah Kiblat',
                  'assets/images/kaabah_newtest2.png',
                  const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF9A825),
                      Color(0xFFFBC02D),
                      Color(0xFFFFD54F),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const KiblatPage()),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.025),
          // Row 2: Al-Quran + Tasbih + Hadith
          Row(
            children: [
              Expanded(
                child: _buildMediumCard(
                  context,
                  'Al Qur\'an',
                  'assets/images/Quran_newTest3.png',
                  const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1976D2),
                      Color(0xFF2196F3),
                      Color(0xFF42A5F5),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const QuranPage()),
                    );
                  },
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: _buildMediumCard(
                  context,
                  'Tasbih',
                  'assets/images/tasbih_newtest.png',
                  const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7B1FA2),
                      Color(0xFF9C27B0),
                      Color(0xFFAB47BC),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const ZikirCounterPage()),
                    );
                  },
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: _buildMediumCard(
                  context,
                  'Hadith 40',
                  'assets/images/Hadith_newTest.png',
                  const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFC2185B),
                      Color(0xFFE91E63),
                      Color(0xFFEC407A),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const Hadis40Page()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediumCard(
    BuildContext context,
    String title,
    String imagePath,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.95,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 5),
                spreadRadius: 0.5,
              ),
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 1.5,
              ),
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: 2.5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.5),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 8,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: screenWidth * 0.031,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1.5),
                                blurRadius: 3,
                              ),
                              Shadow(
                                color: Colors.black.withOpacity(0.15),
                                offset: const Offset(0, 3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          width: screenWidth * 0.16,
                          height: screenWidth * 0.16,
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image_not_supported,
                                color: Colors.white.withOpacity(0.5),
                                size: screenWidth * 0.08,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeCard(
    BuildContext context,
    String title,
    String imagePath,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: screenWidth * 0.28,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.08),
              blurRadius: 35,
              offset: const Offset(0, 15),
              spreadRadius: 3,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.5),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.15),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: screenWidth * 0.16,
                        height: screenWidth * 0.16,
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: Colors.white.withOpacity(0.5),
                              size: screenWidth * 0.08,
                            );
                          },
                        ),
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
}

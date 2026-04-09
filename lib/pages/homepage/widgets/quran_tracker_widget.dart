import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/quran_service.dart';
import '../../../models/quran_models.dart';
import '../../../utils/page_transitions.dart';
import '../../quran/quranpage.dart';

class QuranTrackerWidget extends StatelessWidget {
  const QuranTrackerWidget({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _getLastReadQuran() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSurahNumber = prefs.getInt('last_read_surah') ?? 1;
      final lastAyahNumber = prefs.getInt('last_read_ayah') ?? 1;
      final hasRead = prefs.getBool('has_read_quran') ?? false;

      final allSurahs = await QuranService.getAllSurahs();
      Surah? lastSurah;
      if (allSurahs.isNotEmpty) {
        try {
          lastSurah = allSurahs.firstWhere(
            (surah) => surah.number == lastSurahNumber,
          );
        } catch (e) {
          lastSurah = allSurahs.first;
        }
      }

      return {
        'surahName': lastSurah?.englishName ?? 'Al-Fatihah',
        'surahNumber': lastSurahNumber,
        'ayahNumber': lastAyahNumber,
        'hasRead': hasRead,
      };
    } catch (e) {
      print('Error getting last read Quran: $e');
      return {
        'surahName': 'Al-Fatihah',
        'surahNumber': 1,
        'ayahNumber': 1,
        'hasRead': false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getLastReadQuran(),
      builder: (context, snapshot) {
        final lastRead = snapshot.data ?? {};
        final surahName = lastRead['surahName'] ?? 'Al-Fatihah';
        final ayahNumber = lastRead['ayahNumber'] ?? 1;
        final hasRead = lastRead['hasRead'] ?? false;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                SmoothPageRoute(page: const QuranPage()),
              );
            },
            child: Container(
              padding: EdgeInsets.only(
                left: screenWidth * 0.03,
                right: screenWidth * 0.03,
                top: screenWidth * 0.025,
                bottom: screenWidth * 0.04,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F766E).withOpacity(0.15),
                    const Color(0xFF0F766E).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.035),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF0F766E),
                      size: 28,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Quran Completion',
                          style: TextStyle(
                            color: const Color(0xFF0F766E),
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.03),
                        Text(
                          '$surahName, Ayat $ayahNumber',
                          style: TextStyle(
                            color: const Color(0xFF0F766E).withOpacity(0.7),
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenWidth * 0.035),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.032,
                              vertical: screenWidth * 0.015,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hasRead ? 'Teruskan' : 'Mula Baca',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.03,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
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
      },
    );
  }
}

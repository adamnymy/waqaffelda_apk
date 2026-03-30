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

      final progress = lastSurahNumber / 114.0;

      return {
        'surahName': lastSurah?.englishName ?? 'Al-Fatihah',
        'surahNumber': lastSurahNumber,
        'ayahNumber': lastAyahNumber,
        'progress': progress,
        'hasRead': hasRead,
      };
    } catch (e) {
      print('Error getting last read Quran: $e');
      return {
        'surahName': 'Al-Fatihah',
        'surahNumber': 1,
        'ayahNumber': 1,
        'progress': 0.0,
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
        final progress = (lastRead['progress'] as double?) ?? 0.0;
        final hasRead = lastRead['hasRead'] ?? false;
        final progressPercentage = (progress * 100).toStringAsFixed(0);

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
                    const Color(0xFFD4B896).withOpacity(0.3),
                    const Color(0xFFE8D7C3).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.035),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90A4).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF4A90A4),
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
                            color: Colors.grey.shade800,
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.03),
                        Text(
                          '$surahName, Ayat $ayahNumber',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenWidth * 0.035),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: screenWidth * 0.028,
                                  backgroundColor: const Color(
                                    0xFFD4B896,
                                  ).withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFFD4B896),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Text(
                              '$progressPercentage%',
                              style: TextStyle(
                                color: const Color(0xFFD4B896),
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenWidth * 0.03),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.032,
                              vertical: screenWidth * 0.015,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4B896),
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

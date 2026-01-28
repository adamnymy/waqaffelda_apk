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
        final hasRead = lastRead['hasRead'] ?? false;

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              SmoothPageRoute(page: const QuranPage()),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenWidth * 0.035,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF9800).withOpacity(0.12),
                  const Color(0xFFFBC02D).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFF9800).withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFFFF9800),
                    size: 22,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surahName,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenWidth * 0.015),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ayat $ayahNumber',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025,
                              vertical: screenWidth * 0.012,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF9800),
                                  Color(0xFFF57C00),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9800)
                                      .withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasRead
                                      ? Icons.play_arrow_rounded
                                      : Icons.auto_stories_rounded,
                                  color: Colors.white,
                                  size: screenWidth * 0.035,
                                ),
                                SizedBox(width: screenWidth * 0.015),
                                Text(
                                  hasRead ? 'Teruskan' : 'Mula Baca',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.032,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

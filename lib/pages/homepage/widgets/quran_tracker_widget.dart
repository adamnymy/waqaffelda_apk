import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/quran_service.dart';
import '../../../models/quran_models.dart';
import '../../../utils/page_transitions.dart';
import '../../quran/quranpage.dart';

class QuranTrackerWidget extends StatelessWidget {
  const QuranTrackerWidget({super.key});

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
          lastSurah = allSurahs.firstWhere((s) => s.number == lastSurahNumber);
        } catch (_) {
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
    } catch (_) {
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
    final screenHeight = MediaQuery.of(context).size.height;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getLastReadQuran(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final surahName = data['surahName'] ?? 'Al-Fatihah';
        final ayahNumber = data['ayahNumber'] ?? 1;
        final progress = (data['progress'] ?? 0.0) as double;
        final hasRead = data['hasRead'] ?? false;
        final progressPercent = (progress * 100).toStringAsFixed(0);

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              SmoothPageRoute(page: const QuranPage()),
            );
          },
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.038),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF0E8CC),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Quran book image
                Image.asset(
                  'assets/images/Quran_newTest3.png',
                  width: screenWidth * 0.22,
                  height: screenWidth * 0.22,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: screenWidth * 0.22,
                    height: screenWidth * 0.22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC49B28).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFFC49B28),
                      size: 36,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.035),
                // Right: content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Quran Completion',
                        style: TextStyle(
                          color: const Color(0xFF1A1A2E),
                          fontSize: screenWidth * 0.036,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        'Terakhir Dibaca: $surahName $ayahNumber',
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.009),
                      // Progress bar + percentage
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE8D9A0),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFC49B28),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            '$progressPercent%',
                            style: TextStyle(
                              color: const Color(0xFFC49B28),
                              fontSize: screenWidth * 0.028,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.009),
                      // Teruskan button aligned right
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenWidth * 0.015,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFC49B28), Color(0xFFB8860B)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC49B28).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            hasRead ? 'Teruskan' : 'Mula Baca',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeight.w700,
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
        );
      },
    );
  }
}

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:http/http.dart' as http;
import '../models/quran_models.dart';

class QuranService {
  static const String _baseUrl = 'https://api.quran.com/api/v4';
  static List<Surah>? _cachedSurahs;
  static Map<int, List<Ayah>> _cachedAyahs = {};

  /// Load all Surahs using quran package
  static Future<List<Surah>> getAllSurahs() async {
    // Return cached data if available
    if (_cachedSurahs != null) {
      return _cachedSurahs!;
    }

    try {
      // Load metadata JSON for additional info
      final String metadataString = await rootBundle.loadString(
        'assets/quran/surah_metadata.json',
      );
      final List<dynamic> metadataJson = json.decode(metadataString);

      _cachedSurahs = [];

      // Use quran package to get verse data
      for (var metadata in metadataJson) {
        final surahNumber = metadata['number'];
        final totalVerses = quran.getVerseCount(surahNumber);
        final List<Ayah> ayahs = [];

        // Get all verses for this surah from quran package
        for (int verse = 1; verse <= totalVerses; verse++) {
          final arabicText = quran.getVerse(surahNumber, verse);

          ayahs.add(
            Ayah(
              number: verse,
              text: arabicText,
              numberInSurah: verse,
              translation: 'Terjemahan akan datang...', // Placeholder
            ),
          );
        }

        // Create Surah object
        _cachedSurahs!.add(
          Surah(
            number: metadata['number'] ?? 0,
            name: metadata['name'] ?? '',
            englishName: metadata['englishName'] ?? '',
            englishNameTranslation: metadata['englishNameTranslation'] ?? '',
            numberOfAyahs: metadata['numberOfAyahs'] ?? 0,
            revelationType: metadata['revelationType'] ?? '',
            ayahs: ayahs,
          ),
        );
      }

      print('✅ Loaded ${_cachedSurahs!.length} surahs using quran package');
      return _cachedSurahs!;
    } catch (e) {
      print('❌ Error loading Quran data: $e');
      return [];
    }
  }

  /// Get a specific Surah by number (1-114)
  static Future<Surah?> getSurah(int surahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) {
      print('❌ Invalid surah number: $surahNumber');
      return null;
    }

    final surahs = await getAllSurahs();

    if (surahs.isEmpty) {
      return null;
    }

    // Find surah by number
    try {
      return surahs.firstWhere((surah) => surah.number == surahNumber);
    } catch (e) {
      print('❌ Surah $surahNumber not found');
      return null;
    }
  }

  /// Get a specific Ayah
  static Future<Ayah?> getAyah(int surahNumber, int ayahNumber) async {
    final surah = await getSurah(surahNumber);

    if (surah == null) {
      return null;
    }

    try {
      return surah.ayahs.firstWhere((ayah) => ayah.numberInSurah == ayahNumber);
    } catch (e) {
      print('❌ Ayah $ayahNumber not found in Surah $surahNumber');
      return null;
    }
  }

  /// Get all ayahs for a specific surah from API with fallback to package
  static Future<List<Ayah>> getSurahAyahs(int surahNumber) async {
    // Return cached data if available
    if (_cachedAyahs.containsKey(surahNumber)) {
      print(
        '✅ Loaded ${_cachedAyahs[surahNumber]!.length} ayahs from cache for surah $surahNumber',
      );
      return _cachedAyahs[surahNumber]!;
    }

    try {
      // Try API first for clean text and translation
      final ayahs = await _getAyahsFromAPI(surahNumber);
      if (ayahs.isNotEmpty) {
        _cachedAyahs[surahNumber] = ayahs;
        return ayahs;
      }
    } catch (e) {
      print('⚠️ API failed, using fallback: $e');
    }

    // Fallback to quran package
    try {
      final totalVerses = quran.getVerseCount(surahNumber);
      final List<Ayah> ayahs = [];

      for (int verse = 1; verse <= totalVerses; verse++) {
        final arabicText = quran.getVerse(surahNumber, verse);

        ayahs.add(
          Ayah(
            number: verse,
            text: arabicText,
            numberInSurah: verse,
            translation: 'Terjemahan tidak tersedia dalam mod offline',
          ),
        );
      }

      print(
        '✅ Loaded $totalVerses ayahs for surah $surahNumber using quran package (offline)',
      );
      _cachedAyahs[surahNumber] = ayahs;
      return ayahs;
    } catch (e) {
      print('❌ Error loading ayahs: $e');
      return [];
    }
  }

  /// Fetch ayahs from Quran.com API
  static Future<List<Ayah>> _getAyahsFromAPI(int surahNumber) async {
    try {
      // Get Arabic text (Imlaei - clean without complex tajweed symbols)
      final arabicResponse = await http
          .get(
            Uri.parse(
              '$_baseUrl/quran/verses/imlaei?chapter_number=$surahNumber',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (arabicResponse.statusCode != 200) {
        throw Exception(
          'Failed to load Arabic text: ${arabicResponse.statusCode}',
        );
      }

      // Get Malay translation (translation_id 39 = Malay)
      final translationResponse = await http
          .get(
            Uri.parse(
              '$_baseUrl/quran/translations/39?chapter_number=$surahNumber',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (translationResponse.statusCode != 200) {
        throw Exception(
          'Failed to load translation: ${translationResponse.statusCode}',
        );
      }

      final arabicData = json.decode(arabicResponse.body);
      final translationData = json.decode(translationResponse.body);

      final List<Ayah> ayahs = [];
      final arabicVerses = arabicData['verses'] as List;
      final translationVerses = translationData['translations'] as List;

      for (int i = 0; i < arabicVerses.length; i++) {
        final arabicVerse = arabicVerses[i];
        final translationVerse =
            i < translationVerses.length ? translationVerses[i] : null;

        ayahs.add(
          Ayah(
            number: arabicVerse['verse_number'] ?? (i + 1),
            text: arabicVerse['text_imlaei'] ?? '',
            numberInSurah:
                arabicVerse['verse_key']?.split(':')[1] != null
                    ? int.parse(arabicVerse['verse_key'].split(':')[1])
                    : (i + 1),
            translation:
                translationVerse?['text'] ?? 'Terjemahan tidak tersedia',
          ),
        );
      }

      print(
        '✅ Loaded ${ayahs.length} ayahs for surah $surahNumber from API with translation',
      );
      return ayahs;
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  /// Search for text in Quran
  static Future<List<Map<String, dynamic>>> searchQuran(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final surahs = await getAllSurahs();
    final List<Map<String, dynamic>> results = [];

    for (var surah in surahs) {
      for (var ayah in surah.ayahs) {
        if (ayah.text.contains(query)) {
          results.add({'surah': surah, 'ayah': ayah});
        }
      }
    }

    return results;
  }

  /// Clear cache (useful for testing or if data needs to be reloaded)
  static void clearCache() {
    _cachedSurahs = null;
  }
}

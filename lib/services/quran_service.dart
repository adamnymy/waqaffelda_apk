import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/quran_models.dart';

class QuranService {
  static List<Surah>? _cachedSurahs;
  
  /// Load all Surahs from local JSON file
  static Future<List<Surah>> getAllSurahs() async {
    // Return cached data if available
    if (_cachedSurahs != null) {
      return _cachedSurahs!;
    }

    try {
      // Load metadata JSON
      final String metadataString = await rootBundle.loadString(
        'assets/quran/surah_metadata.json',
      );
      final List<dynamic> metadataJson = json.decode(metadataString);
      
      // Load ayahs JSON
      final String ayahsString = await rootBundle.loadString(
        'assets/quran/quran_arabic.json',
      );
      final Map<String, dynamic> ayahsData = json.decode(ayahsString);
      
      // Combine metadata with ayahs
      _cachedSurahs = [];
      for (var metadata in metadataJson) {
        final surahNumber = metadata['number'].toString();
        final ayahsList = ayahsData[surahNumber] as List<dynamic>?;
        
        if (ayahsList != null) {
          // Convert ayahs to Ayah objects
          final ayahs = ayahsList.map((ayahJson) {
            return Ayah(
              number: ayahJson['verse'] ?? 0,
              text: ayahJson['text'] ?? '',
              numberInSurah: ayahJson['verse'] ?? 0,
            );
          }).toList();
          
          // Create Surah object
          _cachedSurahs!.add(Surah(
            number: metadata['number'] ?? 0,
            name: metadata['name'] ?? '',
            englishName: metadata['englishName'] ?? '',
            englishNameTranslation: metadata['englishNameTranslation'] ?? '',
            numberOfAyahs: metadata['numberOfAyahs'] ?? 0,
            revelationType: metadata['revelationType'] ?? '',
            ayahs: ayahs,
          ));
        }
      }
      
      print('✅ Loaded ${_cachedSurahs!.length} surahs from local storage');
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
      return surah.ayahs.firstWhere(
        (ayah) => ayah.numberInSurah == ayahNumber,
      );
    } catch (e) {
      print('❌ Ayah $ayahNumber not found in Surah $surahNumber');
      return null;
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
          results.add({
            'surah': surah,
            'ayah': ayah,
          });
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

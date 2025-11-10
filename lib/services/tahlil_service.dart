import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/tahlil_model.dart';

class TahlilService {
  static TahlilData? _cachedData;

  /// Load Tahlil data from JSON file
  static Future<TahlilData> loadTahlilData() async {
    // Return cached data if already loaded
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString(
        'assets/data/tahlil_yasin.json',
      );

      // Parse JSON
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Convert to TahlilData model
      final tahlilData = TahlilData.fromJson(jsonData);

      _cachedData = tahlilData;

      return _cachedData!;
    } catch (e) {
      throw Exception('Failed to load Tahlil data: $e');
    }
  }

  /// Clear cached data (useful for testing or reloading)
  static void clearCache() {
    _cachedData = null;
  }

  /// Get a specific section by ID
  static TahlilSection? getSectionById(TahlilData data, String sectionId) {
    try {
      return data.sections.firstWhere((section) => section.id == sectionId);
    } catch (e) {
      return null;
    }
  }

  /// Get total number of sections
  static int getTotalSections(TahlilData data) {
    return data.sections.length;
  }

  /// Get total number of content items across all sections
  static int getTotalContentItems(TahlilData data) {
    return data.sections.fold(
      0,
      (total, section) => total + section.contents.length,
    );
  }
}

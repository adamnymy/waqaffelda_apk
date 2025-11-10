// Model classes for Tahlil & Yasin content

/// Types of content sections in Tahlil
enum ContentType {
  simpleText, // Simple prayer text (e.g., opening prayers)
  verse, // Quranic verses with translation
  zikir, // Zikir with counter (e.g., Tasbih 33x)
}

/// Represents a single content item within a section
class TahlilContent {
  final ContentType type;
  final String? arabic;
  final String? transliteration;
  final String? translation;
  final int? targetCount; // For zikir type
  final int? verseNumber; // For verse type

  TahlilContent({
    required this.type,
    this.arabic,
    this.transliteration,
    this.translation,
    this.targetCount,
    this.verseNumber,
  });

  factory TahlilContent.fromJson(Map<String, dynamic> json) {
    ContentType type;
    switch (json['type']) {
      case 'verse':
        type = ContentType.verse;
        break;
      case 'zikir':
        type = ContentType.zikir;
        break;
      default:
        type = ContentType.simpleText;
    }

    return TahlilContent(
      type: type,
      arabic: json['arabic'],
      transliteration: json['transliteration'],
      translation: json['translation'],
      targetCount: json['targetCount'],
      verseNumber: json['verseNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type':
          type == ContentType.verse
              ? 'verse'
              : type == ContentType.zikir
              ? 'zikir'
              : 'simpleText',
      'arabic': arabic,
      'transliteration': transliteration,
      'translation': translation,
      'targetCount': targetCount,
      'verseNumber': verseNumber,
    };
  }
}

/// Represents a section in the Tahlil (e.g., Opening Prayers, Surah Yasin)
class TahlilSection {
  final String id;
  final String title;
  final String? subtitle;
  final List<TahlilContent> contents;

  TahlilSection({
    required this.id,
    required this.title,
    this.subtitle,
    required this.contents,
  });

  factory TahlilSection.fromJson(Map<String, dynamic> json) {
    return TahlilSection(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      contents:
          (json['contents'] as List)
              .map((item) => TahlilContent.fromJson(item))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'contents': contents.map((c) => c.toJson()).toList(),
    };
  }
}

/// Main Tahlil data structure
class TahlilData {
  final String title;
  final String description;
  final List<TahlilSection> sections;

  TahlilData({
    required this.title,
    required this.description,
    required this.sections,
  });

  factory TahlilData.fromJson(Map<String, dynamic> json) {
    return TahlilData(
      title: json['title'],
      description: json['description'],
      sections:
          (json['sections'] as List)
              .map((item) => TahlilSection.fromJson(item))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }
}

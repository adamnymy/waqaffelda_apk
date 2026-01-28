import 'package:flutter/material.dart';

class HomepageConstants {
  // Colors
  static const Color primaryColor = Color(0xFF00897B);
  static const Color primaryGradient1 = Color(0xFF00695C);
  static const Color primaryGradient2 = Color(0xFF00796B);
  static const Color primaryGradient3 = Color(0xFF00897B);

  // Prayer colors
  static const Map<String, Color> prayerColors = {
    'subuh': Color(0xFF9C27B0),
    'fajr': Color(0xFF9C27B0),
    'syuruk': Color(0xFFFF6F00),
    'sunrise': Color(0xFFFF6F00),
    'zohor': Color(0xFFFFC107),
    'dhuhr': Color(0xFFFFC107),
    'asar': Color(0xFFFF9800),
    'asr': Color(0xFFFF9800),
    'maghrib': Color(0xFFE91E63),
    'isyak': Color(0xFF3F51B5),
    'isha': Color(0xFF3F51B5),
  };

  // Ayat card colors
  static const List<Map<String, Color>> ayatCardColors = [
    {
      'primary': Color(0xFFFBC02D),
      'gradient1': Color(0xFFFDD835),
      'gradient2': Color(0xFFFBC02D),
    },
    {
      'primary': Color(0xFF9C27B0),
      'gradient1': Color(0xFFAB47BC),
      'gradient2': Color(0xFF8E24AA),
    },
    {
      'primary': Color(0xFF00897B),
      'gradient1': Color(0xFF00BCD4),
      'gradient2': Color(0xFF00897B),
    },
    {
      'primary': Color(0xFFFF5722),
      'gradient1': Color(0xFFFF6F00),
      'gradient2': Color(0xFFFF5722),
    },
    {
      'primary': Color(0xFF2196F3),
      'gradient1': Color(0xFF42A5F5),
      'gradient2': Color(0xFF1976D2),
    },
  ];

  // Menu gradients
  static const LinearGradient solatGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00897B),
      Color(0xFF26A69A),
      Color(0xFF4DB6AC),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient kiblatGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF9A825),
      Color(0xFFFBC02D),
      Color(0xFFFFD54F),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient quranGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1976D2),
      Color(0xFF2196F3),
      Color(0xFF42A5F5),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient tasbihGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7B1FA2),
      Color(0xFF9C27B0),
      Color(0xFFAB47BC),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient hadithGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC2185B),
      Color(0xFFE91E63),
      Color(0xFFEC407A),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Strings
  static const String assalamualaikum = 'Assalamualaikum,';
  static const String selamatDatang = 'Selamat Datang';
  static const String solatSeterusnya = 'SOLAT SETERUSNYA';
  static const String waktu = 'WAKTU';
  static const String bakiMasa = 'BAKI MASA';
  static const String waktuSolatHariIni = 'Waktu Solat Hari Ini';
  static const String menuUtama = 'Menu Utama';
  static const String lihatLagi = 'Lihat Lagi';

  // Months in Malay
  static const List<String> malayMonths = [
    'Januari',
    'Februari',
    'Mac',
    'April',
    'Mei',
    'Jun',
    'Julai',
    'Ogos',
    'September',
    'Oktober',
    'November',
    'Disember',
  ];

  // Hijri months
  static const List<String> hijriMonths = [
    'Muharram',
    'Safar',
    "Rabi'ulawal",
    "Rabi'ulakhir",
    'Jamadilawwal',
    'Jamadilakhir',
    'Rejab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    'Zulkaedah',
    'Zulhijjah',
  ];

  // Image assets
  static const String solatImage = 'assets/images/solat_newtest2.png';
  static const String kiblahImage = 'assets/images/kaabah_newtest2.png';
  static const String quranImage = 'assets/images/Quran_newTest3.png';
  static const String tasbihImage = 'assets/images/tasbih_newtest.png';
  static const String hadithImage = 'assets/images/Hadith_newTest.png';
}

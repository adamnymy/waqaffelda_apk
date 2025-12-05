import 'package:flutter/material.dart';
import '../homepage/homepage.dart';
import '../../utils/page_transitions.dart';
import '../../services/quran_service.dart';
import '../../models/quran_models.dart';
import 'surah_detail_page.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({Key? key}) : super(key: key);

  @override
  _QuranPageState createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage>
    with SingleTickerProviderStateMixin {
  int selectedTabIndex = 0;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Add these new variables
  List<Surah> allSurahs = [];
  bool isLoading = true;
  String errorMessage = '';
  late AnimationController _shimmerController;
  DateTime? _loadStartTime;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _loadQuranData();
  }

  // Add this method to load Quran data
  Future<void> _loadQuranData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      _loadStartTime = DateTime.now();
    });

    try {
      final surahs = await QuranService.getAllSurahs();

      // Ensure minimum 1 second loading time for smooth skeleton display
      final elapsed = DateTime.now().difference(_loadStartTime!).inMilliseconds;
      if (elapsed < 1000) {
        await Future.delayed(Duration(milliseconds: 1000 - elapsed));
      }

      setState(() {
        allSurahs = surahs;
        isLoading = false;
      });
      print('✅ Loaded ${surahs.length} surahs successfully!');
    } catch (e) {
      // Still respect minimum time even on error
      final elapsed = DateTime.now().difference(_loadStartTime!).inMilliseconds;
      if (elapsed < 1000) {
        await Future.delayed(Duration(milliseconds: 1000 - elapsed));
      }

      setState(() {
        errorMessage = 'Gagal memuatkan data Al-Quran: $e';
        isLoading = false;
      });
      print('❌ Error loading Quran: $e');
    }
  }

  // List of all 114 Surahs
  final List<Map<String, dynamic>> surahs = [
    {
      'number': 1,
      'nameArabic': 'الفاتحة',
      'nameTransliteration': 'Al-Fatihah',
      'ayatCount': 7,
      'revelation': 'Makkah',
      'meaning': 'Pembukaan',
    },
    {
      'number': 2,
      'nameArabic': 'البقرة',
      'nameTransliteration': 'Al-Baqarah',
      'ayatCount': 286,
      'revelation': 'Madinah',
      'meaning': 'Lembu Betina',
    },
    {
      'number': 3,
      'nameArabic': 'آل عمران',
      'nameTransliteration': "Ali 'Imran",
      'ayatCount': 200,
      'revelation': 'Madinah',
      'meaning': 'Keluarga Imran',
    },
    {
      'number': 4,
      'nameArabic': 'النساء',
      'nameTransliteration': "An-Nisa'",
      'ayatCount': 176,
      'revelation': 'Madinah',
      'meaning': 'Wanita',
    },
    {
      'number': 5,
      'nameArabic': 'المائدة',
      'nameTransliteration': "Al-Ma'idah",
      'ayatCount': 120,
      'revelation': 'Madinah',
      'meaning': 'Hidangan',
    },
    {
      'number': 6,
      'nameArabic': 'الأنعام',
      'nameTransliteration': "Al-An'am",
      'ayatCount': 165,
      'revelation': 'Makkah',
      'meaning': 'Binatang Ternak',
    },
    {
      'number': 7,
      'nameArabic': 'الأعراف',
      'nameTransliteration': "Al-A'raf",
      'ayatCount': 206,
      'revelation': 'Makkah',
      'meaning': 'Tempat Tertinggi',
    },
    {
      'number': 8,
      'nameArabic': 'الأنفال',
      'nameTransliteration': 'Al-Anfal',
      'ayatCount': 75,
      'revelation': 'Madinah',
      'meaning': 'Harta Rampasan Perang',
    },
    {
      'number': 9,
      'nameArabic': 'التوبة',
      'nameTransliteration': 'At-Taubah',
      'ayatCount': 129,
      'revelation': 'Madinah',
      'meaning': 'Taubat',
    },
    {
      'number': 10,
      'nameArabic': 'يونس',
      'nameTransliteration': 'Yunus',
      'ayatCount': 109,
      'revelation': 'Makkah',
      'meaning': 'Nabi Yunus',
    },
    {
      'number': 11,
      'nameArabic': 'هود',
      'nameTransliteration': 'Hud',
      'ayatCount': 123,
      'revelation': 'Makkah',
      'meaning': 'Nabi Hud',
    },
    {
      'number': 12,
      'nameArabic': 'يوسف',
      'nameTransliteration': 'Yusuf',
      'ayatCount': 111,
      'revelation': 'Makkah',
      'meaning': 'Nabi Yusuf',
    },
    {
      'number': 13,
      'nameArabic': 'الرعد',
      'nameTransliteration': "Ar-Ra'd",
      'ayatCount': 43,
      'revelation': 'Madinah',
      'meaning': 'Guruh',
    },
    {
      'number': 14,
      'nameArabic': 'إبراهيم',
      'nameTransliteration': 'Ibrahim',
      'ayatCount': 52,
      'revelation': 'Makkah',
      'meaning': 'Nabi Ibrahim',
    },
    {
      'number': 15,
      'nameArabic': 'الحجر',
      'nameTransliteration': 'Al-Hijr',
      'ayatCount': 99,
      'revelation': 'Makkah',
      'meaning': 'Hijr',
    },
    {
      'number': 16,
      'nameArabic': 'النحل',
      'nameTransliteration': 'An-Nahl',
      'ayatCount': 128,
      'revelation': 'Makkah',
      'meaning': 'Lebah',
    },
    {
      'number': 17,
      'nameArabic': 'الإسراء',
      'nameTransliteration': "Al-Isra'",
      'ayatCount': 111,
      'revelation': 'Makkah',
      'meaning': 'Perjalanan Malam',
    },
    {
      'number': 18,
      'nameArabic': 'الكهف',
      'nameTransliteration': 'Al-Kahf',
      'ayatCount': 110,
      'revelation': 'Makkah',
      'meaning': 'Gua',
    },
    {
      'number': 19,
      'nameArabic': 'مريم',
      'nameTransliteration': 'Maryam',
      'ayatCount': 98,
      'revelation': 'Makkah',
      'meaning': 'Maryam',
    },
    {
      'number': 20,
      'nameArabic': 'طه',
      'nameTransliteration': 'Ta-Ha',
      'ayatCount': 135,
      'revelation': 'Makkah',
      'meaning': 'Ta Ha',
    },
    {
      'number': 21,
      'nameArabic': 'الأنبياء',
      'nameTransliteration': "Al-Anbiya'",
      'ayatCount': 112,
      'revelation': 'Makkah',
      'meaning': 'Para Nabi',
    },
    {
      'number': 22,
      'nameArabic': 'الحج',
      'nameTransliteration': 'Al-Hajj',
      'ayatCount': 78,
      'revelation': 'Madinah',
      'meaning': 'Haji',
    },
    {
      'number': 23,
      'nameArabic': 'المؤمنون',
      'nameTransliteration': "Al-Mu'minun",
      'ayatCount': 118,
      'revelation': 'Makkah',
      'meaning': 'Orang-Orang Beriman',
    },
    {
      'number': 24,
      'nameArabic': 'النور',
      'nameTransliteration': 'An-Nur',
      'ayatCount': 64,
      'revelation': 'Madinah',
      'meaning': 'Cahaya',
    },
    {
      'number': 25,
      'nameArabic': 'الفرقان',
      'nameTransliteration': 'Al-Furqan',
      'ayatCount': 77,
      'revelation': 'Makkah',
      'meaning': 'Pembeza',
    },
    {
      'number': 26,
      'nameArabic': 'الشعراء',
      'nameTransliteration': "Ash-Shu'ara",
      'ayatCount': 227,
      'revelation': 'Makkah',
      'meaning': 'Para Penyair',
    },
    {
      'number': 27,
      'nameArabic': 'النمل',
      'nameTransliteration': 'An-Naml',
      'ayatCount': 93,
      'revelation': 'Makkah',
      'meaning': 'Semut',
    },
    {
      'number': 28,
      'nameArabic': 'القصص',
      'nameTransliteration': 'Al-Qasas',
      'ayatCount': 88,
      'revelation': 'Makkah',
      'meaning': 'Kisah-Kisah',
    },
    {
      'number': 29,
      'nameArabic': 'العنكبوت',
      'nameTransliteration': 'Al-Ankabut',
      'ayatCount': 69,
      'revelation': 'Makkah',
      'meaning': 'Labah-Labah',
    },
    {
      'number': 30,
      'nameArabic': 'الروم',
      'nameTransliteration': 'Ar-Rum',
      'ayatCount': 60,
      'revelation': 'Makkah',
      'meaning': 'Rum',
    },
    {
      'number': 31,
      'nameArabic': 'لقمان',
      'nameTransliteration': 'Luqman',
      'ayatCount': 34,
      'revelation': 'Makkah',
      'meaning': 'Luqman',
    },
    {
      'number': 32,
      'nameArabic': 'السجدة',
      'nameTransliteration': 'As-Sajdah',
      'ayatCount': 30,
      'revelation': 'Makkah',
      'meaning': 'Sujud',
    },
    {
      'number': 33,
      'nameArabic': 'الأحزاب',
      'nameTransliteration': 'Al-Ahzab',
      'ayatCount': 73,
      'revelation': 'Madinah',
      'meaning': 'Golongan-Golongan',
    },
    {
      'number': 34,
      'nameArabic': 'سبأ',
      'nameTransliteration': 'Saba',
      'ayatCount': 54,
      'revelation': 'Makkah',
      'meaning': 'Saba',
    },
    {
      'number': 35,
      'nameArabic': 'فاطر',
      'nameTransliteration': 'Fatir',
      'ayatCount': 45,
      'revelation': 'Makkah',
      'meaning': 'Pencipta',
    },
    {
      'number': 36,
      'nameArabic': 'يس',
      'nameTransliteration': 'Ya-Sin',
      'ayatCount': 83,
      'revelation': 'Makkah',
      'meaning': 'Ya Sin',
    },
    {
      'number': 37,
      'nameArabic': 'الصافات',
      'nameTransliteration': 'As-Saffat',
      'ayatCount': 182,
      'revelation': 'Makkah',
      'meaning': 'Barisan-Barisan',
    },
    {
      'number': 38,
      'nameArabic': 'ص',
      'nameTransliteration': 'Sad',
      'ayatCount': 88,
      'revelation': 'Makkah',
      'meaning': 'Sad',
    },
    {
      'number': 39,
      'nameArabic': 'الزمر',
      'nameTransliteration': 'Az-Zumar',
      'ayatCount': 75,
      'revelation': 'Makkah',
      'meaning': 'Rombongan',
    },
    {
      'number': 40,
      'nameArabic': 'غافر',
      'nameTransliteration': 'Ghafir',
      'ayatCount': 85,
      'revelation': 'Makkah',
      'meaning': 'Yang Mengampuni',
    },
    {
      'number': 41,
      'nameArabic': 'فصلت',
      'nameTransliteration': 'Fussilat',
      'ayatCount': 54,
      'revelation': 'Makkah',
      'meaning': 'Yang Dijelaskan',
    },
    {
      'number': 42,
      'nameArabic': 'الشورى',
      'nameTransliteration': 'Ash-Shura',
      'ayatCount': 53,
      'revelation': 'Makkah',
      'meaning': 'Syura',
    },
    {
      'number': 43,
      'nameArabic': 'الزخرف',
      'nameTransliteration': 'Az-Zukhruf',
      'ayatCount': 89,
      'revelation': 'Makkah',
      'meaning': 'Perhiasan',
    },
    {
      'number': 44,
      'nameArabic': 'الدخان',
      'nameTransliteration': 'Ad-Dukhan',
      'ayatCount': 59,
      'revelation': 'Makkah',
      'meaning': 'Kabut',
    },
    {
      'number': 45,
      'nameArabic': 'الجاثية',
      'nameTransliteration': 'Al-Jathiyah',
      'ayatCount': 37,
      'revelation': 'Makkah',
      'meaning': 'Yang Bertekuk Lutut',
    },
    {
      'number': 46,
      'nameArabic': 'الأحقاف',
      'nameTransliteration': 'Al-Ahqaf',
      'ayatCount': 35,
      'revelation': 'Makkah',
      'meaning': 'Bukit Pasir',
    },
    {
      'number': 47,
      'nameArabic': 'محمد',
      'nameTransliteration': 'Muhammad',
      'ayatCount': 38,
      'revelation': 'Madinah',
      'meaning': 'Nabi Muhammad',
    },
    {
      'number': 48,
      'nameArabic': 'الفتح',
      'nameTransliteration': 'Al-Fath',
      'ayatCount': 29,
      'revelation': 'Madinah',
      'meaning': 'Kemenangan',
    },
    {
      'number': 49,
      'nameArabic': 'الحجرات',
      'nameTransliteration': 'Al-Hujurat',
      'ayatCount': 18,
      'revelation': 'Madinah',
      'meaning': 'Bilik-Bilik',
    },
    {
      'number': 50,
      'nameArabic': 'ق',
      'nameTransliteration': 'Qaf',
      'ayatCount': 45,
      'revelation': 'Makkah',
      'meaning': 'Qaf',
    },
    {
      'number': 51,
      'nameArabic': 'الذاريات',
      'nameTransliteration': 'Adh-Dhariyat',
      'ayatCount': 60,
      'revelation': 'Makkah',
      'meaning': 'Angin Yang Menerbangkan',
    },
    {
      'number': 52,
      'nameArabic': 'الطور',
      'nameTransliteration': 'At-Tur',
      'ayatCount': 49,
      'revelation': 'Makkah',
      'meaning': 'Bukit Tursina',
    },
    {
      'number': 53,
      'nameArabic': 'النجم',
      'nameTransliteration': 'An-Najm',
      'ayatCount': 62,
      'revelation': 'Makkah',
      'meaning': 'Bintang',
    },
    {
      'number': 54,
      'nameArabic': 'القمر',
      'nameTransliteration': 'Al-Qamar',
      'ayatCount': 55,
      'revelation': 'Makkah',
      'meaning': 'Bulan',
    },
    {
      'number': 55,
      'nameArabic': 'الرحمن',
      'nameTransliteration': 'Ar-Rahman',
      'ayatCount': 78,
      'revelation': 'Madinah',
      'meaning': 'Yang Maha Pemurah',
    },
    {
      'number': 56,
      'nameArabic': 'الواقعة',
      'nameTransliteration': "Al-Waqi'ah",
      'ayatCount': 96,
      'revelation': 'Makkah',
      'meaning': 'Hari Kiamat',
    },
    {
      'number': 57,
      'nameArabic': 'الحديد',
      'nameTransliteration': 'Al-Hadid',
      'ayatCount': 29,
      'revelation': 'Madinah',
      'meaning': 'Besi',
    },
    {
      'number': 58,
      'nameArabic': 'المجادلة',
      'nameTransliteration': 'Al-Mujadilah',
      'ayatCount': 22,
      'revelation': 'Madinah',
      'meaning': 'Wanita Yang Berdebat',
    },
    {
      'number': 59,
      'nameArabic': 'الحشر',
      'nameTransliteration': 'Al-Hashr',
      'ayatCount': 24,
      'revelation': 'Madinah',
      'meaning': 'Pengusiran',
    },
    {
      'number': 60,
      'nameArabic': 'الممتحنة',
      'nameTransliteration': 'Al-Mumtahanah',
      'ayatCount': 13,
      'revelation': 'Madinah',
      'meaning': 'Wanita Yang Diuji',
    },
    {
      'number': 61,
      'nameArabic': 'الصف',
      'nameTransliteration': 'As-Saff',
      'ayatCount': 14,
      'revelation': 'Madinah',
      'meaning': 'Barisan',
    },
    {
      'number': 62,
      'nameArabic': 'الجمعة',
      'nameTransliteration': "Al-Jumu'ah",
      'ayatCount': 11,
      'revelation': 'Madinah',
      'meaning': 'Jumaat',
    },
    {
      'number': 63,
      'nameArabic': 'المنافقون',
      'nameTransliteration': 'Al-Munafiqun',
      'ayatCount': 11,
      'revelation': 'Madinah',
      'meaning': 'Orang-Orang Munafik',
    },
    {
      'number': 64,
      'nameArabic': 'التغابن',
      'nameTransliteration': 'At-Taghabun',
      'ayatCount': 18,
      'revelation': 'Madinah',
      'meaning': 'Hari Penipuan',
    },
    {
      'number': 65,
      'nameArabic': 'الطلاق',
      'nameTransliteration': 'At-Talaq',
      'ayatCount': 12,
      'revelation': 'Madinah',
      'meaning': 'Talak',
    },
    {
      'number': 66,
      'nameArabic': 'التحريم',
      'nameTransliteration': 'At-Tahrim',
      'ayatCount': 12,
      'revelation': 'Madinah',
      'meaning': 'Pengharaman',
    },
    {
      'number': 67,
      'nameArabic': 'الملك',
      'nameTransliteration': 'Al-Mulk',
      'ayatCount': 30,
      'revelation': 'Makkah',
      'meaning': 'Kerajaan',
    },
    {
      'number': 68,
      'nameArabic': 'القلم',
      'nameTransliteration': 'Al-Qalam',
      'ayatCount': 52,
      'revelation': 'Makkah',
      'meaning': 'Pena',
    },
    {
      'number': 69,
      'nameArabic': 'الحاقة',
      'nameTransliteration': 'Al-Haqqah',
      'ayatCount': 52,
      'revelation': 'Makkah',
      'meaning': 'Hari Kiamat',
    },
    {
      'number': 70,
      'nameArabic': 'المعارج',
      'nameTransliteration': "Al-Ma'arij",
      'ayatCount': 44,
      'revelation': 'Makkah',
      'meaning': 'Tempat Naik',
    },
    {
      'number': 71,
      'nameArabic': 'نوح',
      'nameTransliteration': 'Nuh',
      'ayatCount': 28,
      'revelation': 'Makkah',
      'meaning': 'Nabi Nuh',
    },
    {
      'number': 72,
      'nameArabic': 'الجن',
      'nameTransliteration': 'Al-Jinn',
      'ayatCount': 28,
      'revelation': 'Makkah',
      'meaning': 'Jin',
    },
    {
      'number': 73,
      'nameArabic': 'المزمل',
      'nameTransliteration': 'Al-Muzzammil',
      'ayatCount': 20,
      'revelation': 'Makkah',
      'meaning': 'Orang Yang Berselimut',
    },
    {
      'number': 74,
      'nameArabic': 'المدثر',
      'nameTransliteration': 'Al-Muddaththir',
      'ayatCount': 56,
      'revelation': 'Makkah',
      'meaning': 'Orang Yang Berkemul',
    },
    {
      'number': 75,
      'nameArabic': 'القيامة',
      'nameTransliteration': 'Al-Qiyamah',
      'ayatCount': 40,
      'revelation': 'Makkah',
      'meaning': 'Hari Kiamat',
    },
    {
      'number': 76,
      'nameArabic': 'الإنسان',
      'nameTransliteration': 'Al-Insan',
      'ayatCount': 31,
      'revelation': 'Madinah',
      'meaning': 'Manusia',
    },
    {
      'number': 77,
      'nameArabic': 'المرسلات',
      'nameTransliteration': 'Al-Mursalat',
      'ayatCount': 50,
      'revelation': 'Makkah',
      'meaning': 'Malaikat Yang Diutus',
    },
    {
      'number': 78,
      'nameArabic': 'النبأ',
      'nameTransliteration': "An-Naba'",
      'ayatCount': 40,
      'revelation': 'Makkah',
      'meaning': 'Berita Besar',
    },
    {
      'number': 79,
      'nameArabic': 'النازعات',
      'nameTransliteration': "An-Nazi'at",
      'ayatCount': 46,
      'revelation': 'Makkah',
      'meaning': 'Malaikat Yang Mencabut',
    },
    {
      'number': 80,
      'nameArabic': 'عبس',
      'nameTransliteration': 'Abasa',
      'ayatCount': 42,
      'revelation': 'Makkah',
      'meaning': 'Bermuka Masam',
    },
    {
      'number': 81,
      'nameArabic': 'التكوير',
      'nameTransliteration': 'At-Takwir',
      'ayatCount': 29,
      'revelation': 'Makkah',
      'meaning': 'Menggulung',
    },
    {
      'number': 82,
      'nameArabic': 'الإنفطار',
      'nameTransliteration': 'Al-Infitar',
      'ayatCount': 19,
      'revelation': 'Makkah',
      'meaning': 'Terbelah',
    },
    {
      'number': 83,
      'nameArabic': 'المطففين',
      'nameTransliteration': 'Al-Mutaffifin',
      'ayatCount': 36,
      'revelation': 'Makkah',
      'meaning': 'Orang Yang Curang',
    },
    {
      'number': 84,
      'nameArabic': 'الإنشقاق',
      'nameTransliteration': 'Al-Inshiqaq',
      'ayatCount': 25,
      'revelation': 'Makkah',
      'meaning': 'Terbelah',
    },
    {
      'number': 85,
      'nameArabic': 'البروج',
      'nameTransliteration': 'Al-Buruj',
      'ayatCount': 22,
      'revelation': 'Makkah',
      'meaning': 'Gugusan Bintang',
    },
    {
      'number': 86,
      'nameArabic': 'الطارق',
      'nameTransliteration': 'At-Tariq',
      'ayatCount': 17,
      'revelation': 'Makkah',
      'meaning': 'Bintang Yang Muncul Malam',
    },
    {
      'number': 87,
      'nameArabic': 'الأعلى',
      'nameTransliteration': "Al-A'la",
      'ayatCount': 19,
      'revelation': 'Makkah',
      'meaning': 'Yang Paling Tinggi',
    },
    {
      'number': 88,
      'nameArabic': 'الغاشية',
      'nameTransliteration': 'Al-Ghashiyah',
      'ayatCount': 26,
      'revelation': 'Makkah',
      'meaning': 'Hari Pembalasan',
    },
    {
      'number': 89,
      'nameArabic': 'الفجر',
      'nameTransliteration': 'Al-Fajr',
      'ayatCount': 30,
      'revelation': 'Makkah',
      'meaning': 'Fajar',
    },
    {
      'number': 90,
      'nameArabic': 'البلد',
      'nameTransliteration': 'Al-Balad',
      'ayatCount': 20,
      'revelation': 'Makkah',
      'meaning': 'Negeri',
    },
    {
      'number': 91,
      'nameArabic': 'الشمس',
      'nameTransliteration': 'Ash-Shams',
      'ayatCount': 15,
      'revelation': 'Makkah',
      'meaning': 'Matahari',
    },
    {
      'number': 92,
      'nameArabic': 'الليل',
      'nameTransliteration': 'Al-Lail',
      'ayatCount': 21,
      'revelation': 'Makkah',
      'meaning': 'Malam',
    },
    {
      'number': 93,
      'nameArabic': 'الضحى',
      'nameTransliteration': 'Ad-Duha',
      'ayatCount': 11,
      'revelation': 'Makkah',
      'meaning': 'Waktu Dhuha',
    },
    {
      'number': 94,
      'nameArabic': 'الشرح',
      'nameTransliteration': 'Ash-Sharh',
      'ayatCount': 8,
      'revelation': 'Makkah',
      'meaning': 'Melapangkan',
    },
    {
      'number': 95,
      'nameArabic': 'التين',
      'nameTransliteration': 'At-Tin',
      'ayatCount': 8,
      'revelation': 'Makkah',
      'meaning': 'Tin',
    },
    {
      'number': 96,
      'nameArabic': 'العلق',
      'nameTransliteration': 'Al-Alaq',
      'ayatCount': 19,
      'revelation': 'Makkah',
      'meaning': 'Segumpal Darah',
    },
    {
      'number': 97,
      'nameArabic': 'القدر',
      'nameTransliteration': 'Al-Qadr',
      'ayatCount': 5,
      'revelation': 'Makkah',
      'meaning': 'Kemuliaan',
    },
    {
      'number': 98,
      'nameArabic': 'البينة',
      'nameTransliteration': 'Al-Bayyinah',
      'ayatCount': 8,
      'revelation': 'Madinah',
      'meaning': 'Bukti Yang Nyata',
    },
    {
      'number': 99,
      'nameArabic': 'الزلزلة',
      'nameTransliteration': 'Az-Zalzalah',
      'ayatCount': 8,
      'revelation': 'Madinah',
      'meaning': 'Kegoncangan',
    },
    {
      'number': 100,
      'nameArabic': 'العاديات',
      'nameTransliteration': "Al-'Adiyat",
      'ayatCount': 11,
      'revelation': 'Makkah',
      'meaning': 'Kuda Yang Berlari Kencang',
    },
    {
      'number': 101,
      'nameArabic': 'القارعة',
      'nameTransliteration': "Al-Qari'ah",
      'ayatCount': 11,
      'revelation': 'Makkah',
      'meaning': 'Hari Kiamat',
    },
    {
      'number': 102,
      'nameArabic': 'التكاثر',
      'nameTransliteration': 'At-Takathur',
      'ayatCount': 8,
      'revelation': 'Makkah',
      'meaning': 'Bermegah-Megahan',
    },
    {
      'number': 103,
      'nameArabic': 'العصر',
      'nameTransliteration': 'Al-Asr',
      'ayatCount': 3,
      'revelation': 'Makkah',
      'meaning': 'Masa',
    },
    {
      'number': 104,
      'nameArabic': 'الهمزة',
      'nameTransliteration': 'Al-Humazah',
      'ayatCount': 9,
      'revelation': 'Makkah',
      'meaning': 'Pengumpat',
    },
    {
      'number': 105,
      'nameArabic': 'الفيل',
      'nameTransliteration': 'Al-Fil',
      'ayatCount': 5,
      'revelation': 'Makkah',
      'meaning': 'Gajah',
    },
    {
      'number': 106,
      'nameArabic': 'قريش',
      'nameTransliteration': 'Quraish',
      'ayatCount': 4,
      'revelation': 'Makkah',
      'meaning': 'Kaum Quraisy',
    },
    {
      'number': 107,
      'nameArabic': 'الماعون',
      'nameTransliteration': "Al-Ma'un",
      'ayatCount': 7,
      'revelation': 'Makkah',
      'meaning': 'Barang-Barang Berguna',
    },
    {
      'number': 108,
      'nameArabic': 'الكوثر',
      'nameTransliteration': 'Al-Kauthar',
      'ayatCount': 3,
      'revelation': 'Makkah',
      'meaning': 'Nikmat Yang Banyak',
    },
    {
      'number': 109,
      'nameArabic': 'الكافرون',
      'nameTransliteration': 'Al-Kafirun',
      'ayatCount': 6,
      'revelation': 'Makkah',
      'meaning': 'Orang-Orang Kafir',
    },
    {
      'number': 110,
      'nameArabic': 'النصر',
      'nameTransliteration': 'An-Nasr',
      'ayatCount': 3,
      'revelation': 'Madinah',
      'meaning': 'Pertolongan',
    },
    {
      'number': 111,
      'nameArabic': 'المسد',
      'nameTransliteration': 'Al-Masad',
      'ayatCount': 5,
      'revelation': 'Makkah',
      'meaning': 'Tali',
    },
    {
      'number': 112,
      'nameArabic': 'الإخلاص',
      'nameTransliteration': 'Al-Ikhlas',
      'ayatCount': 4,
      'revelation': 'Makkah',
      'meaning': 'Ikhlas',
    },
    {
      'number': 113,
      'nameArabic': 'الفلق',
      'nameTransliteration': 'Al-Falaq',
      'ayatCount': 5,
      'revelation': 'Makkah',
      'meaning': 'Waktu Subuh',
    },
    {
      'number': 114,
      'nameArabic': 'الناس',
      'nameTransliteration': 'An-Nas',
      'ayatCount': 6,
      'revelation': 'Makkah',
      'meaning': 'Manusia',
    },
  ];

  List<Surah> get filteredSurahs {
    if (searchQuery.isEmpty) {
      return allSurahs;
    }
    return allSurahs.where((surah) {
      final nameTransliteration = surah.englishName.toLowerCase();
      final nameArabic = surah.name;
      final meaning = surah.englishNameTranslation.toLowerCase();
      final number = surah.number.toString();
      final query = searchQuery.toLowerCase();

      return nameTransliteration.contains(query) ||
          nameArabic.contains(query) ||
          meaning.contains(query) ||
          number.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              SmoothPageRoute(page: const Homepage()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Surah',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari Surah...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
                suffixIcon:
                    searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              searchQuery = '';
                            });
                          },
                        )
                        : null,
                filled: true,
                fillColor: colorScheme.primary.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Last Read Card (Featured Card)
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bacaan Terakhir',
                          style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Al-Fatihah',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ayat 1 - Pembukaan',
                          style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colorScheme.onPrimary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Buttons with Icons
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Surah', Icons.book_rounded, 0),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    'Juzuk',
                    Icons.format_list_numbered_rounded,
                    1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton('Simpan', Icons.bookmark_rounded, 2),
                ),
              ],
            ),
          ),

          // Surah List
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [
                      colorScheme.secondary,
                      colorScheme.secondary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: isSelected ? null : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? Colors.transparent
                    : colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? colorScheme.onSecondary
                      : colorScheme.onSurface.withOpacity(0.6),
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color:
                      isSelected
                          ? colorScheme.onSecondary
                          : colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (selectedTabIndex == 0) {
      return _buildSurahList();
    } else if (selectedTabIndex == 1) {
      return _buildParaList();
    } else {
      return _buildBookmarkList();
    }
  }

  Widget _buildSurahList() {
    final colorScheme = Theme.of(context).colorScheme;

    // Show loading indicator
    if (isLoading) {
      return _buildSkeletonLoading();
    }

    // Show error message
    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadQuranData,
              icon: const Icon(Icons.refresh),
              label: const Text('Cuba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final displaySurahs = filteredSurahs;

    if (displaySurahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Surah tidak ditemui',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: displaySurahs.length + 1, // +1 for credit footer
      itemBuilder: (context, index) {
        // Show credit at the end
        if (index == displaySurahs.length) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Divider(color: colorScheme.primary.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text(
                  'Sumber Data Al-Quran',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quran.com API',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Terjemahan Bahasa Melayu',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          );
        }

        final surah = displaySurahs[index];
        return _buildSurahCard(surah);
      },
    );
  }

  Widget _buildSurahCard(Surah surah) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to surah detail page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SurahDetailPage(surah: surah),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Number Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.secondary,
                        colorScheme.secondary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${surah.number}',
                      style: TextStyle(
                        color: colorScheme.onSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Surah Info - Redesigned for better flexibility
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arabic Name on top
                      Text(
                        surah.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          height: 1.2,
                          fontFamily: 'Amiri',
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Transliteration below Arabic
                      Text(
                        surah.englishName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Ayat count and meaning
                      Row(
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Text(
                                  '${surah.numberOfAyahs} Ayat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  width: 3,
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.4,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    surah.malayTranslation,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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

                const SizedBox(width: 12),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParaList() {
    final paras = [
      {
        'number': 1,
        'name': 'Alif Lam Mim',
        'startSurah': 'Al-Fatihah',
        'startAyat': 1,
      },
      {
        'number': 2,
        'name': 'Sayaqulu',
        'startSurah': 'Al-Baqarah',
        'startAyat': 142,
      },
      {
        'number': 3,
        'name': 'Tilkal Rusulu',
        'startSurah': 'Al-Baqarah',
        'startAyat': 253,
      },
      {
        'number': 4,
        'name': 'Lan Tana Lu',
        'startSurah': 'Ali-Imran',
        'startAyat': 92,
      },
      {
        'number': 5,
        'name': 'Wal Muhsanat',
        'startSurah': 'An-Nisa',
        'startAyat': 24,
      },
      {
        'number': 6,
        'name': 'La Yuhibbullah',
        'startSurah': 'An-Nisa',
        'startAyat': 148,
      },
      {
        'number': 7,
        'name': 'Wa Iza Sami\'u',
        'startSurah': 'Al-Ma\'idah',
        'startAyat': 82,
      },
      {
        'number': 8,
        'name': 'Wa Lau Annana',
        'startSurah': 'Al-An\'am',
        'startAyat': 111,
      },
      {
        'number': 9,
        'name': 'Qalal Mala',
        'startSurah': 'Al-A\'raf',
        'startAyat': 88,
      },
      {
        'number': 10,
        'name': 'Wa A\'lamu',
        'startSurah': 'Al-Anfal',
        'startAyat': 41,
      },
      {
        'number': 11,
        'name': 'Ya\'tazirun',
        'startSurah': 'At-Tawbah',
        'startAyat': 93,
      },
      {
        'number': 12,
        'name': 'Wa Ma Min Dabbah',
        'startSurah': 'Hud',
        'startAyat': 6,
      },
      {
        'number': 13,
        'name': 'Wa Ma Ubri\'u',
        'startSurah': 'Yusuf',
        'startAyat': 53,
      },
      {'number': 14, 'name': 'Rubama', 'startSurah': 'Al-Hijr', 'startAyat': 1},
      {
        'number': 15,
        'name': 'Subhanallazi',
        'startSurah': 'Al-Isra',
        'startAyat': 1,
      },
      {
        'number': 16,
        'name': 'Qala Alam',
        'startSurah': 'Al-Kahf',
        'startAyat': 75,
      },
      {
        'number': 17,
        'name': 'Iqtaraba',
        'startSurah': 'Al-Anbiya',
        'startAyat': 1,
      },
      {
        'number': 18,
        'name': 'Qadd Aflaha',
        'startSurah': 'Al-Mu\'minun',
        'startAyat': 1,
      },
      {
        'number': 19,
        'name': 'Wa Qalallazina',
        'startSurah': 'Al-Furqan',
        'startAyat': 21,
      },
      {
        'number': 20,
        'name': 'Amman Khalaqa',
        'startSurah': 'An-Naml',
        'startAyat': 60,
      },
      {
        'number': 21,
        'name': 'Utlu Ma Uhiya',
        'startSurah': 'Al-Ankabut',
        'startAyat': 45,
      },
      {
        'number': 22,
        'name': 'Wa Man Yaqnut',
        'startSurah': 'Al-Ahzab',
        'startAyat': 31,
      },
      {
        'number': 23,
        'name': 'Wa Mali',
        'startSurah': 'Yaseen',
        'startAyat': 22,
      },
      {
        'number': 24,
        'name': 'Fa Mani Azlam',
        'startSurah': 'Az-Zumar',
        'startAyat': 32,
      },
      {
        'number': 25,
        'name': 'Ilaih Yuraddu',
        'startSurah': 'Fussilat',
        'startAyat': 47,
      },
      {
        'number': 26,
        'name': 'Ha Mim',
        'startSurah': 'Al-Ahqaf',
        'startAyat': 1,
      },
      {
        'number': 27,
        'name': 'Qala Fama Khatbukum',
        'startSurah': 'Adh-Dhariyat',
        'startAyat': 31,
      },
      {
        'number': 28,
        'name': 'Qadd Sami Allah',
        'startSurah': 'Al-Mujadilah',
        'startAyat': 1,
      },
      {
        'number': 29,
        'name': 'Tabarakallazi',
        'startSurah': 'Al-Mulk',
        'startAyat': 1,
      },
      {
        'number': 30,
        'name': 'Amma Yatasa\'alun',
        'startSurah': 'An-Naba',
        'startAyat': 1,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paras.length,
      itemBuilder: (context, index) {
        final para = paras[index];
        return _buildParaCard(para);
      },
    );
  }

  Widget _buildParaCard(Map<String, dynamic> para) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to Para detail page
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Para number badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.secondary,
                        colorScheme.secondary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${para['number']}',
                    style: TextStyle(
                      color: colorScheme.onSecondary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Para details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        para['name'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bermula: ${para['startSurah']}, Ayat ${para['startAyat']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkList() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmarks_rounded,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Tiada Tandabuku',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tandakan ayat kegemaran anda',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: 8,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Number Badge Skeleton
            _buildShimmer(
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content Skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmer(
                    Container(
                      width: 120,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildShimmer(
                    Container(
                      width: 100,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildShimmer(
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Arrow Icon Skeleton
            _buildShimmer(
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(Widget child) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }
}

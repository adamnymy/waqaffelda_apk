// Quran Data Models

class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;
  final List<Ayah> ayahs;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
    required this.ayahs,
  });

  // Get Malay translation
  String get malayTranslation {
    return _malayTranslations[number] ?? englishNameTranslation;
  }

  // Get revelation type in Malay
  String get revelationTypeMalay {
    return revelationType == 'Meccan' ? 'Makkah' : 'Madinah';
  }

  // Malay translations mapping
  static const Map<int, String> _malayTranslations = {
    1: 'Pembukaan',
    2: 'Lembu',
    3: 'Keluarga Imran',
    4: 'Wanita',
    5: 'Hidangan',
    6: 'Binatang Ternak',
    7: 'Tempat Tertinggi',
    8: 'Harta Rampasan Perang',
    9: 'Taubat',
    10: 'Nabi Yunus',
    11: 'Nabi Hud',
    12: 'Nabi Yusuf',
    13: 'Guruh',
    14: 'Nabi Ibrahim',
    15: 'Hijr',
    16: 'Lebah',
    17: 'Perjalanan Malam',
    18: 'Gua',
    19: 'Maryam',
    20: 'Taha',
    21: 'Para Nabi',
    22: 'Haji',
    23: 'Orang-Orang Beriman',
    24: 'Cahaya',
    25: 'Pemisah',
    26: 'Para Penyair',
    27: 'Semut',
    28: 'Kisah',
    29: 'Laba-Laba',
    30: 'Bangsa Rum',
    31: 'Luqman',
    32: 'Sujud',
    33: 'Golongan Yang Bersekutu',
    34: 'Saba',
    35: 'Pencipta',
    36: 'Yasin',
    37: 'Barisan-Barisan',
    38: 'Shad',
    39: 'Rombongan',
    40: 'Yang Mengampuni',
    41: 'Yang Dijelaskan',
    42: 'Musyawarah',
    43: 'Perhiasan',
    44: 'Kabut',
    45: 'Yang Bertekuk Lutut',
    46: 'Bukit Pasir',
    47: 'Muhammad',
    48: 'Kemenangan',
    49: 'Kamar-Kamar',
    50: 'Qaf',
    51: 'Angin Yang Menerbangkan',
    52: 'Bukit Tursina',
    53: 'Bintang',
    54: 'Bulan',
    55: 'Yang Maha Pemurah',
    56: 'Hari Kiamat',
    57: 'Besi',
    58: 'Wanita Yang Mengadu',
    59: 'Pengusiran',
    60: 'Wanita Yang Diuji',
    61: 'Barisan',
    62: 'Jumaat',
    63: 'Orang-Orang Munafik',
    64: 'Hari Dinampakkan Kesalahan',
    65: 'Talak',
    66: 'Pengharaman',
    67: 'Kerajaan',
    68: 'Pena',
    69: 'Hari Kiamat',
    70: 'Tangga-Tangga',
    71: 'Nabi Nuh',
    72: 'Jin',
    73: 'Orang Yang Berselimut',
    74: 'Orang Yang Berkemul',
    75: 'Hari Kiamat',
    76: 'Manusia',
    77: 'Malaikat Yang Diutus',
    78: 'Berita Besar',
    79: 'Malaikat Yang Mencabut',
    80: 'Ia Bermuka Masam',
    81: 'Menggulung',
    82: 'Terbelah',
    83: 'Orang-Orang Yang Curang',
    84: 'Terbelah',
    85: 'Gugusan Bintang',
    86: 'Yang Datang Di Malam Hari',
    87: 'Yang Paling Tinggi',
    88: 'Hari Pembalasan',
    89: 'Fajar',
    90: 'Negeri',
    91: 'Matahari',
    92: 'Malam',
    93: 'Dhuha',
    94: 'Kelapangan',
    95: 'Tin',
    96: 'Segumpal Darah',
    97: 'Kemuliaan',
    98: 'Bukti',
    99: 'Goncangan',
    100: 'Kuda Yang Berlari Kencang',
    101: 'Hari Kiamat',
    102: 'Bermegah-Megahan',
    103: 'Masa',
    104: 'Pengumpat',
    105: 'Gajah',
    106: 'Quraisy',
    107: 'Barang-Barang Berguna',
    108: 'Nikmat Yang Banyak',
    109: 'Orang-Orang Kafir',
    110: 'Pertolongan',
    111: 'Api Yang Bergejolak',
    112: 'Ikhlas',
    113: 'Waktu Subuh',
    114: 'Manusia',
  };

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      englishNameTranslation: json['englishNameTranslation'] ?? '',
      numberOfAyahs: json['numberOfAyahs'] ?? 0,
      revelationType: json['revelationType'] ?? '',
      ayahs:
          (json['ayahs'] as List?)
              ?.map((ayah) => Ayah.fromJson(ayah))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'englishName': englishName,
      'englishNameTranslation': englishNameTranslation,
      'numberOfAyahs': numberOfAyahs,
      'revelationType': revelationType,
      'ayahs': ayahs.map((ayah) => ayah.toJson()).toList(),
    };
  }
}

class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int? juz;
  final int? manzil;
  final int? page;
  final int? ruku;
  final int? hizbQuarter;
  final bool? sajda;

  Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    this.juz,
    this.manzil,
    this.page,
    this.ruku,
    this.hizbQuarter,
    this.sajda,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'] ?? 0,
      text: json['text'] ?? '',
      numberInSurah: json['numberInSurah'] ?? 0,
      juz: json['juz'] ?? 0,
      manzil: json['manzil'] ?? 0,
      page: json['page'] ?? 0,
      ruku: json['ruku'] ?? 0,
      hizbQuarter: json['hizbQuarter'] ?? 0,
      sajda: json['sajda'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      'numberInSurah': numberInSurah,
      'juz': juz,
      'manzil': manzil,
      'page': page,
      'ruku': ruku,
      'hizbQuarter': hizbQuarter,
      'sajda': sajda,
    };
  }
}

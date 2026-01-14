import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../navbar.dart';
import '../homepage/homepage.dart';
import '../waqaf/waqafpage.dart';
import '../inbox/inboxpage.dart';
import '../akaun/akaunpage.dart';

// ══════════════════════════════════════════════════════════════════════════════
// THEME COLORS
// ══════════════════════════════════════════════════════════════════════════════

class AppColors {
  static const Color primary = Color(0xFF1B4D3E);
  static const Color primaryLight = Color(0xFF2D6A4F);
  static const Color accent = Color(0xFFD4A853);
  static const Color bgPrimary = Color(0xFFFAFAFA);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textMuted = Color(0xFF8A8A8A);
}

// ══════════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ══════════════════════════════════════════════════════════════════════════════

class ProgramItem {
  final String title;
  final String tagline;
  final String description;
  final String image;
  final String url;
  final String date;
  final IconData icon;
  final List<Color> gradient;
  final String? badge;
  final List<String> highlights;
  final List<AgihanItem>? agihanList; // For cluster details

  const ProgramItem({
    required this.title,
    required this.tagline,
    required this.description,
    required this.image,
    required this.url,
    required this.date,
    required this.icon,
    required this.gradient,
    this.badge,
    this.highlights = const [],
    this.agihanList,
  });
}

// Data model untuk agihan item dalam kluster
class AgihanItem {
  final String name;
  final String beneficiary;
  final String amount;
  final String status;
  final IconData icon;
  final String? image; // Gambar agihan
  final String? url; // Link untuk detail (FB, website, etc)

  const AgihanItem({
    required this.name,
    required this.beneficiary,
    required this.amount,
    required this.status,
    required this.icon,
    this.image,
    this.url,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ══════════════════════════════════════════════════════════════════════════════

class ProgramPage extends StatefulWidget {
  const ProgramPage({Key? key}) : super(key: key);

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 1;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  // ══════════════════════════════════════════════════════════════════════════
  // DATA: PELUANG BERSAMA
  // ══════════════════════════════════════════════════════════════════════════
  final List<ProgramItem> peluangBersama = const [
    ProgramItem(
      title: 'Kempen Potong Lima',
      tagline: 'RM5 Sebulan, Impak Selamanya',
      description:
          'Jom sertai kempen potong lima dengan menyumbang RM5 sahaja. Walaupun jumlahnya kecil, sumbangan ini dapat memberikan impak yang besar apabila digabungkan dengan sumbangan orang lain.\n\nDana yang terkumpul akan diagihkan kepada mereka yang memerlukan dibawah lima kluster agihan manfaat iaitu kesihatan dan dhaif, pendidikan dan kerohanian, bencana, kemudahan awam dan ekonomi.',
      image: 'assets/images/KP5R3.png',
      url: 'https://waqaffelda.waqafer.com.my/order/form/42',
      date: '01/03/2025',
      icon: Icons.favorite_rounded,
      gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
      badge: 'TERKINI',
      highlights: ['Kesihatan', 'Pendidikan', 'Bencana', 'Kemudahan Awam'],
    ),
    ProgramItem(
      title: 'Infak Subuh',
      tagline: 'Sebaik-baik waktu adalah pagi hari',
      description:
          'Infak Subuh mengajak anda menyumbang di waktu penuh keberkatan ini. Sedekah kecil di awal pagi mampu membawa ketenangan dan rezeki yang diberkati sepanjang hari.\n\nMulakan hari dengan kebaikan, dan lihat bagaimana ia mengubah hidup anda dan orang lain.',
      image: 'assets/images/IST2.png',
      url: 'https://waqaffelda.waqafer.com.my/order/form/40',
      date: '01/09/2025',
      icon: Icons.wb_twilight_rounded,
      gradient: [Color(0xFF667EEA), Color(0xFF764BA2)],
      highlights: ['Waktu Berkah', 'Pahala Berganda', 'Rezeki Diberkati'],
    ),
    ProgramItem(
      title: 'Wakaf Senaskhah Al-Quran',
      tagline: 'Sedekah Jariah yang Tidak Putus',
      description:
          'Setiap kali Al-Quran yang anda wakafkan dibaca, pahala mengalir kepada anda. Bantu sediakan mushaf suci untuk masjid, surau, sekolah dan mereka yang memerlukan.\n\nSatu Al-Quran, berjuta bacaan, pahala tidak putus hingga akhirat.',
      image: 'assets/images/WQT1.png',
      url: 'https://waqaffelda.waqafer.com.my/order/form/44',
      date: '20/03/2025',
      icon: Icons.auto_stories_rounded,
      gradient: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      highlights: [
        'Pahala Berterusan',
        'Sedekah Jariah',
        'Manfaat Berpanjangan',
      ],
    ),
    ProgramItem(
      title: 'Set Persalinan Akhir',
      tagline: 'Infak Terakhir, Pahala Berpanjangan',
      description:
          'Bayangkan… di saat seorang insan kembali kepada Allah, keluarga sedang berduka… Set Persalinan Akhir yang anda infakkan inilah yang memudahkan urusan mereka.\n\n✦ Lengkap – Semua keperluan pengurusan jenazah dalam satu set\n✦ Patuh Syariah – Mengikut garis panduan Islam\n✦ Berkualiti – Bahan suci dan terjamin',
      image: 'assets/images/SPAT1.png',
      url: 'https://waqaffelda.waqafer.com.my/order/form/50',
      date: '01/10/2025',
      icon: Icons.spa_rounded,
      gradient: [Color(0xFFF093FB), Color(0xFFF5576C)],
      highlights: ['Lengkap', 'Patuh Syariah', 'Berkualiti'],
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // DATA: AGIHAN MANFAAT
  // ══════════════════════════════════════════════════════════════════════════
  final List<ProgramItem> agihanManfaat = const [
    ProgramItem(
      title: 'Kluster Kesihatan',
      tagline: 'Bantuan perubatan & rawatan',
      description:
          'Membantu golongan yang memerlukan bantuan perubatan dan rawatan kesihatan. Meringankan beban pesakit dan keluarga.',
      image: 'assets/images/CardAM001.png',
      url: 'https://waqaffelda.waqafer.com.my',
      date: 'Berterusan',
      icon: Icons.medical_services_rounded,
      gradient: [Color(0xFFE53935), Color(0xFFFF5252)],
      badge: 'POPULAR',
      highlights: ['Perubatan', 'Rawatan', 'Hospital'],
      agihanList: [
        AgihanItem(
          name: 'Bantuan Peralatan',
          beneficiary: 'Kluster Kesihatan',
          amount: 'RM 74,230',
          status: 'Selesai',
          icon: Icons.medical_services_rounded,
          image: 'assets/images/agihan_pembedahan.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/pembedahan123',
        ),
        AgihanItem(
          name: 'Bantuan Rawatan',
          beneficiary: 'Kluster Kesihatan',
          amount: 'RM 74,231',
          status: 'Dalam Proses',
          icon: Icons.local_hospital_rounded,
          image: 'assets/images/agihan_dialisis.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/dialisis456',
        ),
        AgihanItem(
          name: 'Bantuan Perubatan',
          beneficiary: 'Kluster Kesihatan',
          amount: 'RM 74,230',
          status: 'Selesai',
          icon: Icons.medication_rounded,
          image: 'assets/images/agihan_ubat.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/ubatan789',
        ),
      ],
    ),
    ProgramItem(
      title: 'Kluster Pendidikan',
      tagline: 'Biasiswa & bantuan pelajaran',
      description:
          'Menyediakan biasiswa dan bantuan pendidikan untuk pelajar yang memerlukan. Melahirkan generasi berilmu.',
      image: 'assets/images/CardAM002.png',
      url: 'https://waqaffelda.waqafer.com.my',
      date: 'Berterusan',
      icon: Icons.school_rounded,
      gradient: [Color(0xFF1976D2), Color(0xFF42A5F5)],
      highlights: ['Biasiswa', 'Pelajar', 'Sekolah'],
      agihanList: [
        AgihanItem(
          name: 'Biasiswa Universiti',
          beneficiary: 'Nurul Aina binti Ahmad',
          amount: 'RM 12,000',
          status: 'Selesai',
          icon: Icons.school_rounded,
          image: 'assets/images/agihan_biasiswa.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/biasiswa201',
        ),
        AgihanItem(
          name: 'Bantuan Buku Teks',
          beneficiary: 'Muhammad Hafiz bin Ismail',
          amount: 'RM 800',
          status: 'Selesai',
          icon: Icons.menu_book_rounded,
          image: 'assets/images/agihan_buku.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/buku202',
        ),
        AgihanItem(
          name: 'Yuran Sekolah',
          beneficiary: 'Aisyah binti Yusof',
          amount: 'RM 2,500',
          status: 'Dalam Proses',
          icon: Icons.payments_rounded,
          image: 'assets/images/agihan_yuran.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/yuran203',
        ),
      ],
    ),
    ProgramItem(
      title: 'Kluster Bencana',
      tagline: 'Bantuan kecemasan & pemulihan',
      description:
          'Menyalurkan bantuan segera kepada mangsa bencana alam. Membantu proses pemulihan dan pembinaan semula.',
      image: 'assets/images/CardAM003.png',
      url: 'https://waqaffelda.waqafer.com.my',
      date: 'Berterusan',
      icon: Icons.warning_rounded,
      gradient: [Color(0xFFFF6F00), Color(0xFFFFCA28)],
      highlights: ['Banjir', 'Kecemasan', 'Pemulihan'],
      agihanList: [
        AgihanItem(
          name: 'Bantuan Mangsa Banjir',
          beneficiary: 'Keluarga Pak Hamid',
          amount: 'RM 5,000',
          status: 'Selesai',
          icon: Icons.water_damage_rounded,
          image: 'assets/images/agihan_banjir.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/banjir301',
        ),
        AgihanItem(
          name: 'Pemulihan Rumah',
          beneficiary: 'Keluarga Mak Limah',
          amount: 'RM 18,000',
          status: 'Dalam Proses',
          icon: Icons.home_repair_service_rounded,
          image: 'assets/images/agihan_rumah.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/rumah302',
        ),
        AgihanItem(
          name: 'Bekalan Makanan Kecemasan',
          beneficiary: 'PPS Kuala Lipis',
          amount: 'RM 8,500',
          status: 'Selesai',
          icon: Icons.fastfood_rounded,
          image: 'assets/images/agihan_makanan.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/makanan303',
        ),
      ],
    ),
    ProgramItem(
      title: 'Kluster Ekonomi',
      tagline: 'Modal perniagaan & sara hidup',
      description:
          'Membantu golongan asnaf dengan modal perniagaan kecil dan bantuan sara hidup untuk keluarga yang memerlukan.',
      image: 'assets/images/CardAM001.png',
      url: 'https://waqaffelda.waqafer.com.my',
      date: 'Berterusan',
      icon: Icons.storefront_rounded,
      gradient: [Color(0xFF00897B), Color(0xFF4DB6AC)],
      highlights: ['Modal', 'Perniagaan', 'Asnaf'],
      agihanList: [
        AgihanItem(
          name: 'Modal Perniagaan Kecil',
          beneficiary: 'Puan Aminah',
          amount: 'RM 10,000',
          status: 'Selesai',
          icon: Icons.store_rounded,
          image: 'assets/images/agihan_modal.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/modal401',
        ),
        AgihanItem(
          name: 'Bantuan Sara Hidup',
          beneficiary: 'Keluarga Pak Ali',
          amount: 'RM 3,000',
          status: 'Selesai',
          icon: Icons.family_restroom_rounded,
          image: 'assets/images/agihan_sara.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/sara402',
        ),
        AgihanItem(
          name: 'Peralatan Perniagaan',
          beneficiary: 'Encik Muthu',
          amount: 'RM 6,500',
          status: 'Dalam Proses',
          icon: Icons.construction_rounded,
          image: 'assets/images/agihan_peralatan.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/peralatan403',
        ),
      ],
    ),
    ProgramItem(
      title: 'Kemudahan Awam',
      tagline: 'Infrastruktur & fasiliti',
      description:
          'Pembinaan dan penyelenggaraan kemudahan awam seperti surau, tandas awam, dan kemudahan OKU.',
      image: 'assets/images/CardAM002.png',
      url: 'https://waqaffelda.waqafer.com.my',
      date: 'Berterusan',
      icon: Icons.location_city_rounded,
      gradient: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
      highlights: ['Surau', 'Infrastruktur', 'OKU'],
      agihanList: [
        AgihanItem(
          name: 'Pembinaan Surau',
          beneficiary: 'Kampung Sungai Ruan',
          amount: 'RM 85,000',
          status: 'Dalam Proses',
          icon: Icons.mosque_rounded,
          image: 'assets/images/agihan_surau.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/surau501',
        ),
        AgihanItem(
          name: 'Tandas Awam OKU',
          beneficiary: 'Masjid Al-Falah',
          amount: 'RM 25,000',
          status: 'Selesai',
          icon: Icons.wc_rounded,
          image: 'assets/images/agihan_tandas.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/tandas502',
        ),
        AgihanItem(
          name: 'Landskap Taman',
          beneficiary: 'Taman Rekreasi Felda',
          amount: 'RM 15,000',
          status: 'Dalam Proses',
          icon: Icons.park_rounded,
          image: 'assets/images/agihan_taman.jpg',
          url: 'https://www.facebook.com/waqaffelda/posts/taman503',
        ),
      ],
    ),
  ];

  // Tab Colors
  Color _currentTabColor = AppColors.primary; // Default hijau

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes for color animation
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentTabColor =
            _tabController.index == 0
                ? AppColors
                    .primary // Hijau untuk Peluang Bersama
                : AppColors.accent; // Kuning/Emas untuk Agihan Manfaat
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _launchURL(String urlString) async {
    HapticFeedback.lightImpact();
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showSnackBar('Tidak dapat membuka pautan', isError: true);
      }
    } catch (e) {
      _showSnackBar('Ralat: ${e.toString()}', isError: true);
    }
  }

  Future<void> _shareProgram(ProgramItem item) async {
    HapticFeedback.mediumImpact();
    final String shareText = '''
🌙 *${item.title}*

${item.tagline}

Jom sertai program ini bersama Waqaf FELDA!

🔗 ${item.url}

#WaqafFELDA #Sedekah #Kebajikan
''';

    try {
      await Share.share(shareText, subject: item.title);
    } catch (e) {
      _showSnackBar('Ralat berkongsi: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);

    final pages = [
      const Homepage(),
      null,
      const WaqafPage(),
      const InboxPage(),
      const AkaunPage(),
    ];

    if (pages[index] != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => pages[index]!,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            _buildHeader(),

            // Fixed Tab Bar
            _buildTabBar(),

            // Scrollable Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPeluangBersamaList(),
                  _buildAgihanManfaatList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        scrollController: _scrollController,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER - COMPACT & CLEAN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Icon - Kuning Terang Gradient dengan Tooltip
          Tooltip(
            message: 'Program Waqaf FELDA\nBersama membantu sesama',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            textStyle: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD93D), Color(0xFFFFC107)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            waitDuration: const Duration(milliseconds: 500),
            showDuration: const Duration(seconds: 3),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD93D), // Kuning terang
                    Color(0xFFFFC107), // Kuning amber
                    Color(0xFFFFB300), // Kuning emas terang
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD93D).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.handshake_rounded, // Icon baru
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title - Lebih kecil
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Program Waqaf',
                  style: TextStyle(
                    fontSize: 18, // Dikecilkan dari 22
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pilih program untuk menyumbang',
                  style: TextStyle(
                    fontSize: 12, // Dikecilkan sikit
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Stats - Auto-update jumlah program
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD93D).withOpacity(0.2),
                  const Color(0xFFFFC107).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFD93D).withOpacity(0.3),
              ),
            ),
            child: Text(
              '${peluangBersama.length + agihanManfaat.length} Program',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE6A700), // Kuning gelap untuk text
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB BAR - ANIMATED COLOR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          // Interpolate color based on tab animation
          final Color indicatorColor =
              Color.lerp(
                const Color(0xFF00897B), // Teal (Tab 0 - Peluang Bersama)
                const Color(0xFFFFC107), // Kuning (Tab 1 - Agihan Manfaat)
                _tabController.animation!.value,
              )!;

          return TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    _tabController.animation!.value < 0.5
                        ? [
                          const Color(0xFF00897B),
                          const Color(0xFF26A69A),
                          const Color(0xFF4DB6AC),
                        ] // Teal gradient
                        : [
                          const Color(0xFFFFD93D),
                          const Color(0xFFFFC107),
                          const Color(0xFFFFB300),
                        ], // Kuning gradient
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: indicatorColor.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            labelPadding: EdgeInsets.zero,
            tabs: const [
              Tab(
                height: 42,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Peluang Bersama'),
                  ],
                ),
              ),
              Tab(
                height: 42,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Agihan Manfaat'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PELUANG BERSAMA LIST
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPeluangBersamaList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: peluangBersama.length,
      itemBuilder: (context, index) {
        return _buildProgramCard(item: peluangBersama[index], index: index);
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AGIHAN MANFAAT LIST
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAgihanManfaatList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: agihanManfaat.length,
      itemBuilder: (context, index) {
        return _buildProgramCard(
          item: agihanManfaat[index],
          index: index,
          isCluster: true,
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROGRAM CARD - BEAUTIFUL ELEVATED DESIGN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProgramCard({
    required ProgramItem item,
    required int index,
    bool isCluster = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                // Subtle elevated shadow - nampak timbul tapi tak terlalu tinggi
                boxShadow: [
                  // Main shadow - soft depth
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  // Secondary shadow - subtle lift
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                  // Inner highlight - creates 3D effect
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 0,
                    offset: const Offset(0, -1),
                    spreadRadius: 0,
                  ),
                ],
                // Subtle border for definition
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () => _showProgramDetails(item),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ════════════════════════════════════════════════
                      // IMAGE SECTION
                      // ════════════════════════════════════════════════
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Stack(
                          children: [
                            // Image
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.asset(
                                item.image,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: item.gradient,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          item.icon,
                                          size: 56,
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                              ),
                            ),

                            // Gradient Overlay - more elegant
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.05),
                                      Colors.black.withOpacity(0.35),
                                    ],
                                    stops: const [0.4, 1.0],
                                  ),
                                ),
                              ),
                            ),

                            // Badge (only for first item)
                            if (item.badge != null && index == 0)
                              Positioned(
                                top: 14,
                                left: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: item.gradient,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.gradient[0].withOpacity(
                                          0.4,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    item.badge!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ════════════════════════════════════════════════
                      // CONTENT SECTION - Cleaner layout
                      // ════════════════════════════════════════════════
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon & Title Row
                            Row(
                              children: [
                                // Icon with subtle shadow
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: item.gradient,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.gradient[0].withOpacity(
                                          0.25,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.tagline,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: item.gradient[0],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Highlights Tags - cleaner style
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  item.highlights.take(3).map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.gradient[0].withOpacity(
                                          0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: item.gradient[0].withOpacity(
                                            0.85,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 18),

                            // CTA Button - refined with subtle shadow
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.gradient[0].withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (isCluster && item.agihanList != null) {
                                    // Navigate to agihan detail page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                AgihanDetailPage(cluster: item),
                                      ),
                                    );
                                  } else {
                                    // Open URL for Peluang Bersama
                                    _launchURL(item.url);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: item.gradient[0],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isCluster
                                          ? 'Lihat Agihan'
                                          : 'Sertai Sekarang',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                    ),
                                  ],
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
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEET: PROGRAM DETAILS
  // ══════════════════════════════════════════════════════════════════════════

  void _showProgramDetails(ProgramItem item) {
    HapticFeedback.mediumImpact();
    // Check if this is a cluster (agihan manfaat)
    final bool isCluster = item.agihanList != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _ProgramDetailsSheet(
            item: item,
            isCluster: isCluster,
            onJoin: () {
              if (isCluster) {
                // Navigate to agihan detail page
                Navigator.pop(context); // Close bottom sheet first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgihanDetailPage(cluster: item),
                  ),
                );
              } else {
                // Open URL for Peluang Bersama
                _launchURL(item.url);
              }
            },
            onShare: () => _shareProgram(item),
          ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROGRAM DETAILS SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _ProgramDetailsSheet extends StatelessWidget {
  final ProgramItem item;
  final bool isCluster;
  final VoidCallback onJoin;
  final VoidCallback onShare;

  const _ProgramDetailsSheet({
    required this.item,
    required this.isCluster,
    required this.onJoin,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Hero Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.asset(
                              item.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: item.gradient,
                                      ),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 72,
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                            ),
                          ),
                          // Gradient
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.6),
                                  ],
                                  stops: const [0.4, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // Close Button
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          // Title Overlay
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.badge != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: item.gradient,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item.badge!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.tagline,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: item.gradient[0].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: item.gradient[0],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.date,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: item.gradient[0],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Description
                          Text(
                            isCluster ? 'Maklumat Agihan' : 'Maklumat Program',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Highlights
                          if (item.highlights.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  item.highlights.map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            item.gradient[0].withOpacity(0.1),
                                            item.gradient[1].withOpacity(0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: item.gradient[0].withOpacity(
                                            0.2,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: item.gradient[0],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Action Buttons
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: item.gradient[0].withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: item.gradient[0].withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: onJoin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: item.gradient[0],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isCluster
                                              ? Icons.visibility_rounded
                                              : Icons.how_to_reg_rounded,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isCluster
                                              ? 'Lihat Agihan'
                                              : 'Sertai Sekarang',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Show share button only for Peluang Bersama
                                if (!isCluster) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: onShare,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: item.gradient[0],
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        side: BorderSide(
                                          color: item.gradient[0],
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.share_rounded, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Kongsi Program',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Info Footer
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.grey.shade500,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Untuk maklumat lanjut, sila hubungi pihak Waqaf FELDA',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AGIHAN DETAIL PAGE - Listing agihan untuk setiap kluster
// ══════════════════════════════════════════════════════════════════════════════

class AgihanDetailPage extends StatelessWidget {
  final ProgramItem cluster;

  const AgihanDetailPage({Key? key, required this.cluster}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: cluster.gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cluster.gradient[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Back button & Title row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cluster.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Senarai Agihan',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          cluster.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Jumlah Agihan',
                          '${cluster.agihanList?.length ?? 0}',
                          Icons.list_alt_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          'Selesai',
                          '${cluster.agihanList?.where((a) => a.status == "Selesai").length ?? 0}',
                          Icons.check_circle_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          'Dalam Proses',
                          '${cluster.agihanList?.where((a) => a.status == "Dalam Proses").length ?? 0}',
                          Icons.pending_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List of agihan
            Expanded(
              child:
                  cluster.agihanList == null || cluster.agihanList!.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tiada agihan buat masa ini',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: cluster.agihanList!.length,
                        itemBuilder: (context, index) {
                          final agihan = cluster.agihanList![index];
                          return _buildAgihanCard(agihan, cluster.gradient);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAgihanCard(AgihanItem agihan, List<Color> gradient) {
    final bool isSelesai = agihan.status == "Selesai";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap:
              agihan.url != null
                  ? () {
                    HapticFeedback.lightImpact();
                    _launchURL(agihan.url!);
                  }
                  : null,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section (if available)
              if (agihan.image != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.asset(
                          agihan.image!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: gradient),
                                ),
                                child: Center(
                                  child: Icon(
                                    agihan.icon,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                        ),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Status badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelesai
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelesai
                                    ? Icons.check_circle_rounded
                                    : Icons.pending_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                agihan.status,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Link indicator
                      if (agihan.url != null)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                              color: gradient[0],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradient),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            agihan.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agihan.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                agihan.beneficiary,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status badge (jika tiada gambar)
                        if (agihan.image == null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelesai
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isSelesai
                                        ? Colors.green.shade200
                                        : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelesai
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_rounded,
                                  size: 12,
                                  color:
                                      isSelesai
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  agihan.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isSelesai
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Divider
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 12),

                    // Amount & Link button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 16,
                              color: gradient[0],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              agihan.amount,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: gradient[0],
                              ),
                            ),
                          ],
                        ),
                        if (agihan.url != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: gradient[0].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: gradient[0].withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: gradient[0],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Lihat Detail',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: gradient[0],
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
      ),
    );
  }

  void _launchURL(String urlString) async {
    HapticFeedback.lightImpact();
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        // Error handling if needed
      }
    } catch (e) {
      // Error handling if needed
    }
  }
}

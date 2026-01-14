import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../navbar.dart';
import '../homepage/homepage.dart';
import '../waqaf/waqafpage.dart';
import '../inbox/inboxpage.dart';
import '../akaun/akaunpage.dart';
import 'peluang_bersama_tab.dart';
import 'agihan_manfaat_tab.dart';

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
// PROGRAM PAGE - MAIN
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  PeluangBersamaTab(),
                  AgihanManfaatTab(),
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
  // HEADER
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
          // Icon dengan Tooltip
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
                    Color(0xFFFFD93D),
                    Color(0xFFFFC107),
                    Color(0xFFFFB300),
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
                Icons.handshake_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Program Waqaf',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pilih program untuk menyumbang',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Stats Badge
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
              '${peluangBersamaData.length + agihanManfaatData.length} Program',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE6A700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB BAR
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
          final Color indicatorColor = Color.lerp(
            const Color(0xFF00897B),
            const Color(0xFFFFC107),
            _tabController.animation!.value,
          )!;

          return TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _tabController.animation!.value < 0.5
                    ? [
                        const Color(0xFF00897B),
                        const Color(0xFF26A69A),
                        const Color(0xFF4DB6AC),
                      ]
                    : [
                        const Color(0xFFFFD93D),
                        const Color(0xFFFFC107),
                        const Color(0xFFFFB300),
                      ],
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
}
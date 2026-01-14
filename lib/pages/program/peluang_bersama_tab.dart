import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
// DATA MODEL - PELUANG BERSAMA
// ══════════════════════════════════════════════════════════════════════════════

class PeluangBersamaItem {
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

  const PeluangBersamaItem({
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
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// DATA: PELUANG BERSAMA
// ══════════════════════════════════════════════════════════════════════════════

const List<PeluangBersamaItem> peluangBersamaData = [
  PeluangBersamaItem(
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
  PeluangBersamaItem(
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
  PeluangBersamaItem(
    title: 'Wakaf Senaskhah Al-Quran',
    tagline: 'Sedekah Jariah yang Tidak Putus',
    description:
        'Setiap kali Al-Quran yang anda wakafkan dibaca, pahala mengalir kepada anda. Bantu sediakan mushaf suci untuk masjid, surau, sekolah dan mereka yang memerlukan.\n\nSatu Al-Quran, berjuta bacaan, pahala tidak putus hingga akhirat.',
    image: 'assets/images/WQT1.png',
    url: 'https://waqaffelda.waqafer.com.my/order/form/44',
    date: '20/03/2025',
    icon: Icons.auto_stories_rounded,
    gradient: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    highlights: ['Pahala Berterusan', 'Sedekah Jariah', 'Manfaat Berpanjangan'],
  ),
  PeluangBersamaItem(
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

// ══════════════════════════════════════════════════════════════════════════════
// PELUANG BERSAMA TAB WIDGET
// ══════════════════════════════════════════════════════════════════════════════

class PeluangBersamaTab extends StatelessWidget {
  const PeluangBersamaTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: peluangBersamaData.length,
      itemBuilder: (context, index) {
        return _buildProgramCard(
          context: context,
          item: peluangBersamaData[index],
          index: index,
        );
      },
    );
  }

  Widget _buildProgramCard({
    required BuildContext context,
    required PeluangBersamaItem item,
    required int index,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 0,
                    offset: const Offset(0, -1),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () => _showProgramDetails(context, item),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.asset(
                                item.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
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
                                    gradient: LinearGradient(colors: item.gradient),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.gradient[0].withOpacity(0.4),
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

                      // Content Section
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
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
                                        color: item.gradient[0].withOpacity(0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(item.icon, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: item.highlights.take(3).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.gradient[0].withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: item.gradient[0].withOpacity(0.85),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),
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
                                onPressed: () => _launchURL(item.url),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: item.gradient[0],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sertai Sekarang',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_rounded, size: 16),
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

  void _showProgramDetails(BuildContext context, PeluangBersamaItem item) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProgramDetailsSheet(
        item: item,
        onJoin: () => _launchURL(item.url),
        onShare: () => _shareProgram(item),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    HapticFeedback.lightImpact();
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _shareProgram(PeluangBersamaItem item) async {
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
      debugPrint('Error sharing: $e');
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _ProgramDetailsSheet extends StatelessWidget {
  final PeluangBersamaItem item;
  final VoidCallback onJoin;
  final VoidCallback onShare;

  const _ProgramDetailsSheet({
    required this.item,
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
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.asset(
                              item.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: item.gradient),
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 72,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
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
                                child: const Icon(Icons.close_rounded, size: 22),
                              ),
                            ),
                          ),
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
                                      gradient: LinearGradient(colors: item.gradient),
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
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const Text(
                            'Maklumat Program',
                            style: TextStyle(
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
                          if (item.highlights.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: item.highlights.map((tag) {
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
                                      color: item.gradient[0].withOpacity(0.2),
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
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.how_to_reg_rounded, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Sertai Sekarang',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: onShare,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: item.gradient[0],
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: BorderSide(
                                        color: item.gradient[0],
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
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
                            ),
                          ),
                          const SizedBox(height: 20),
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
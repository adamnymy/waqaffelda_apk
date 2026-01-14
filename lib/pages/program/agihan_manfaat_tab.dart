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
// DATA MODELS - AGIHAN MANFAAT
// ══════════════════════════════════════════════════════════════════════════════

class AgihanItem {
  final String name;
  final String beneficiary;
  final String amount;
  final String status;
  final IconData icon;
  final String? image;
  final String? url;

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

class AgihanManfaatItem {
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
  final List<AgihanItem> agihanList;
  final int jumlahPenerima; // Manual setting for beneficiaries count

  const AgihanManfaatItem({
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
    required this.agihanList,
    required this.jumlahPenerima,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// DATA: AGIHAN MANFAAT
// ══════════════════════════════════════════════════════════════════════════════

const List<AgihanManfaatItem> agihanManfaatData = [
  AgihanManfaatItem(
    title: 'Kluster Kesihatan & Dhaif',
    tagline: 'Bantuan perubatan & rawatan',
    description:
        'Membantu golongan yang memerlukan bantuan perubatan dan rawatan kesihatan. Meringankan beban pesakit dan keluarga.',
    image: 'assets/images/Manfaat/Kluster1.png',
    url: 'https://waqaffelda.com.my/portal',
    date: 'Berterusan',
    icon: Icons.medical_services_rounded,
    gradient: [Color(0xFFE53935), Color(0xFFFF5252)],
    badge: 'POPULAR',
    highlights: ['Perubatan', 'Rawatan', 'Hospital'],
    jumlahPenerima: 2348,
    agihanList: [
      AgihanItem(
        name: 'Bantuan Peralatan',
        beneficiary: 'Kluster Kesihatan',
        amount: 'RM 78,450',
        status: 'Selesai',
        icon: Icons.medical_services_rounded,
        image: 'assets/images/agihan_pembedahan.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Bantuan Rawatan',
        beneficiary: 'Kluster Kesihatan',
        amount: 'RM 82,130',
        status: 'Dalam Proses',
        icon: Icons.local_hospital_rounded,
        image: 'assets/images/agihan_dialisis.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Bantuan Perubatan',
        beneficiary: 'Kluster Kesihatan',
        amount: 'RM 62,111',
        status: 'Selesai',
        icon: Icons.medication_rounded,
        image: 'assets/images/agihan_ubat.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
    ],
  ),
  AgihanManfaatItem(
    title: 'Kluster Pendidikan & Kerohanian',
    tagline: 'Bantuan pelajaran',
    description:'Bantuan pendidikan formal (sekolah) dan tidak formal (madrasah & pondok), sama ada penerimanya adalah institusi seperti sekolah, universiti atau individu',
    image: 'assets/images/Manfaat/Kluster2.png',
    url: 'https://waqaffelda.com.my/portal',
    date: 'Berterusan',
    icon: Icons.school_rounded,
    gradient: [Color(0xFF1976D2), Color(0xFF42A5F5)],
    highlights: ['Pelajar', 'Universiti', 'Sekolah'],
    jumlahPenerima: 8915,
    agihanList: [
      AgihanItem(
        name: 'Bantuan Pendidikan Pelajar IPT',
        beneficiary: 'Nurul Aina binti Ahmad',
        amount: 'RM 38,500',
        status: 'Selesai',
        icon: Icons.school_rounded,
        image: 'assets/images/agihan_biasiswa.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Bantuan Sekolah',
        beneficiary: 'Muhammad Hafiz bin Ismail',
        amount: 'RM 29,450',
        status: 'Selesai',
        icon: Icons.menu_book_rounded,
        image: 'assets/images/agihan_buku.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Peralatan Belajar',
        beneficiary: 'Aisyah binti Yusof',
        amount: 'RM 25,230',
        status: 'Dalam Proses',
        icon: Icons.payments_rounded,
        image: 'assets/images/agihan_yuran.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
    ],
  ),
  AgihanManfaatItem(
    title: 'Kluster Bencana',
    tagline: 'Bantuan kecemasan & pemulihan',
    description:
        'Menyalurkan bantuan segera kepada mangsa bencana alam. Membantu proses pemulihan dan pembinaan semula.',
    image: 'assets/images/Manfaat/Kluster3.png',
    url: 'https://waqaffelda.com.my/portal',
    date: 'Berterusan',
    icon: Icons.warning_rounded,
    gradient: [Color(0xFFFF6F00), Color(0xFFFFCA28)],
    highlights: ['Banjir', 'Kecemasan', 'Pemulihan'],
    jumlahPenerima: 3437,
    agihanList: [
      AgihanItem(
        name: 'Bantuan Mangsa Banjir',
        beneficiary: 'Keluarga Pak Hamid',
        amount: 'RM 45,800',
        status: 'Selesai',
        icon: Icons.water_damage_rounded,
        image: 'assets/images/agihan_banjir.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Pemulihan Rumah',
        beneficiary: 'Keluarga Mak Limah',
        amount: 'RM 32,150',
        status: 'Dalam Proses',
        icon: Icons.home_repair_service_rounded,
        image: 'assets/images/agihan_rumah.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Bekalan Makanan Kecemasan',
        beneficiary: 'PPS Kuala Lipis',
        amount: 'RM 26,276',
        status: 'Selesai',
        icon: Icons.fastfood_rounded,
        image: 'assets/images/agihan_makanan.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
    ],
  ),
  AgihanManfaatItem(
    title: 'Kluster Ekonomi',
    tagline: 'Modal perniagaan & sara hidup',
    description:
        'Membantu golongan asnaf dengan modal perniagaan kecil dan bantuan sara hidup untuk keluarga yang memerlukan.',
    image: 'assets/images/Manfaat/Kluster4.png',
    url: 'https://waqaffelda.com.my/portal',
    date: 'Berterusan',
    icon: Icons.storefront_rounded,
    gradient: [Color(0xFF00897B), Color(0xFF4DB6AC)],
    highlights: ['Modal', 'Perniagaan', 'Asnaf'],
    jumlahPenerima: 95,
    agihanList: [
      AgihanItem(
        name: 'Modal Perniagaan Kecil',
        beneficiary: 'Puan Aminah',
        amount: 'RM 850',
        status: 'Selesai',
        icon: Icons.store_rounded,
        image: 'assets/images/agihan_modal.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Bantuan Sara Hidup',
        beneficiary: 'Keluarga Pak Ali',
        amount: 'RM 1,100',
        status: 'Selesai',
        icon: Icons.family_restroom_rounded,
        image: 'assets/images/agihan_sara.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Peralatan Perniagaan',
        beneficiary: 'Encik Muthu',
        amount: 'RM 550',
        status: 'Dalam Proses',
        icon: Icons.construction_rounded,
        image: 'assets/images/agihan_peralatan.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
    ],
  ),
  AgihanManfaatItem(
    title: 'Kluster Kemudahan Awam',
    tagline: 'Infrastruktur & fasiliti',
    description:
        'Pembinaan dan penyelenggaraan kemudahan awam untuk manfaat komuniti setempat',
    image: 'assets/images/Manfaat/Kluster5.png',
    url: 'https://waqaffelda.com.my/portal',
    date: 'Berterusan',
    icon: Icons.location_city_rounded,
    gradient: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
    highlights: ['Surau', 'Klinik', 'OKU'],
    jumlahPenerima: 8866,
    agihanList: [
      AgihanItem(
        name: 'Klinik Bergerak',
        beneficiary: 'Kampung Sungai Ruan',
        amount: 'RM 42,300',
        status: 'Dalam Proses',
        icon: Icons.mosque_rounded,
        image: 'assets/images/agihan_surau.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Baik Pulih Madrasah/Surau',
        beneficiary: 'Masjid Al-Falah',
        amount: 'RM 28,150',
        status: 'Selesai',
        icon: Icons.wc_rounded,
        image: 'assets/images/agihan_tandas.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Penimbang Getah Digital',
        beneficiary: 'Taman Rekreasi Felda',
        amount: 'RM 18,137',
        status: 'Dalam Proses',
        icon: Icons.park_rounded,
        image: 'assets/images/agihan_taman.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
    ],
  ),
  AgihanManfaatItem(
    title: 'Wakaf Quran',
    tagline: 'Sedekah jariah yang berterusan',
    description:
        'Menyediakan Al-Quran untuk masjid, surau, sekolah dan institusi pendidikan. Setiap kali Al-Quran dibaca, pahala mengalir kepada pewakaf.',
    image: 'assets/images/Manfaat/Kluster6.png',
    url: 'https://waqaffelda.com.my/portal',
    date: 'Berterusan',
    icon: Icons.auto_stories_rounded,
    gradient: [Color(0xFF00796B), Color(0xFF26A69A)],
    badge: 'TERKINI',
    highlights: ['Al-Quran', 'Pahala Jariah', 'Berkah'],
    jumlahPenerima: 4600,
    agihanList: [
      AgihanItem(
        name: 'Pelajar Tahfiz',
        beneficiary: 'Masjid Negeri',
        amount: 'RM 68,500',
        status: 'Selesai',
        icon: Icons.mosque_rounded,
        image: 'assets/images/agihan_quran_masjid.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Pelajar Sekolah',
        beneficiary: 'Sekolah Agama',
        amount: 'RM 72,300',
        status: 'Dalam Proses',
        icon: Icons.school_rounded,
        image: 'assets/images/agihan_quran_sekolah.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
      AgihanItem(
        name: 'Orang Awam',
        beneficiary: 'Surau Kampung',
        amount: 'RM 59,200',
        status: 'Selesai',
        icon: Icons.auto_stories_rounded,
        image: 'assets/images/agihan_quran_surau.jpg',
        url: 'https://waqaffelda.com.my/portal',
      ),
    ],
  ),
];

// ══════════════════════════════════════════════════════════════════════════════
// AGIHAN MANFAAT TAB WIDGET
// ══════════════════════════════════════════════════════════════════════════════

class AgihanManfaatTab extends StatelessWidget {
  const AgihanManfaatTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: agihanManfaatData.length,
      itemBuilder: (context, index) {
        return _buildClusterCard(
          context: context,
          item: agihanManfaatData[index],
          index: index,
        );
      },
    );
  }

  Widget _buildClusterCard({
    required BuildContext context,
    required AgihanManfaatItem item,
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
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 0,
                    offset: const Offset(0, -1),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () => _showClusterDetails(context, item),
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
                            // Fixed badge display logic
                            if (item.badge != null)
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
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AgihanDetailPage(cluster: item),
                                    ),
                                  );
                                },
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
                                      'Lihat Agihan',
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

  void _showClusterDetails(BuildContext context, AgihanManfaatItem item) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClusterDetailsSheet(
        item: item,
        onViewDetails: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgihanDetailPage(cluster: item),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET - CLUSTER DETAILS
// ══════════════════════════════════════════════════════════════════════════════

class _ClusterDetailsSheet extends StatelessWidget {
  final AgihanManfaatItem item;
  final VoidCallback onViewDetails;

  const _ClusterDetailsSheet({
    required this.item,
    required this.onViewDetails,
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
                          // Gradient Background with Icon (instead of image)
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Container(
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
                                  size: 120,
                                  color: Colors.white.withOpacity(0.3),
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
                                    Colors.black.withOpacity(0.4),
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
                            'Maklumat Agihan',
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
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: onViewDetails,
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
                                    Icon(Icons.visibility_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Lihat Agihan',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

// ══════════════════════════════════════════════════════════════════════════════
// AGIHAN DETAIL PAGE
// ══════════════════════════════════════════════════════════════════════════════

class AgihanDetailPage extends StatelessWidget {
  final AgihanManfaatItem cluster;

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

                  // Stats - New Structure
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
                          _formatCurrency(_getTotalAmount(cluster.agihanList)),
                          Icons.payments_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          'Jumlah Penerima',
                          _formatNumber(cluster.jumlahPenerima),
                          Icons.people_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          'Jenis Agihan',
                          '${_getUniqueTypes(cluster.agihanList)}',
                          Icons.category_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: cluster.agihanList.isEmpty
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
                      itemCount: cluster.agihanList.length,
                      itemBuilder: (context, index) {
                        final agihan = cluster.agihanList[index];
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

  // Helper function untuk kira total amount dari semua agihan
  double _getTotalAmount(List<AgihanItem> agihanList) {
    double total = 0.0;
    for (var agihan in agihanList) {
      // Extract number from "RM 74,230" format
      String cleanAmount = agihan.amount.replaceAll('RM', '').replaceAll(',', '').replaceAll(' ', '');
      double amount = double.tryParse(cleanAmount) ?? 0.0;
      total += amount;
    }
    return total;
  }

  // Helper function untuk format currency dengan compact notation
  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      // Format as millions (e.g., RM1.2M)
      double millions = amount / 1000000;
      return 'RM${millions.toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      // Format as thousands (e.g., RM222K)
      double thousands = amount / 1000;
      return 'RM${thousands.toStringAsFixed(0)}K';
    } else {
      // Format as normal (e.g., RM500)
      return 'RM${amount.toStringAsFixed(0)}';
    }
  }

  // Helper function untuk format number dengan comma separator
  String _formatNumber(int number) {
    if (number == 0) return '0';
    
    String numStr = number.toString();
    String result = '';
    int count = 0;
    
    for (int i = numStr.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ',$result';
        count = 0;
      }
      result = numStr[i] + result;
      count++;
    }
    
    return result;
  }

  // Helper function untuk kira unique beneficiaries
  int _getUniqueBeneficiaries(List<AgihanItem> agihanList) {
    final uniqueBeneficiaries = <String>{};
    for (var agihan in agihanList) {
      uniqueBeneficiaries.add(agihan.beneficiary);
    }
    return uniqueBeneficiaries.length;
  }

  // Helper function untuk kira unique types
  int _getUniqueTypes(List<AgihanItem> agihanList) {
    final uniqueTypes = <String>{};
    for (var agihan in agihanList) {
      uniqueTypes.add(agihan.name);
    }
    return uniqueTypes.length;
  }

  Widget _buildAgihanCard(AgihanItem agihan, List<Color> gradient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Main shadow - creates depth
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          // Secondary shadow - adds lift
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          // Subtle highlight on top
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 0,
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: agihan.url != null
              ? () {
                  HapticFeedback.lightImpact();
                  _launchURL(agihan.url!);
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row - Icon & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        agihan.icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        agihan.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Divider
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 12),

                // Amount & Lihat Detail button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Amount
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 18,
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
                    // Lihat Detail button
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
        ),
      ),
    );
  }

  void _launchURL(String urlString) async {
    HapticFeedback.lightImpact();
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
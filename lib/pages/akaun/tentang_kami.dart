import 'package:flutter/material.dart';

/// About Us Page
/// Displays information about WAQAF FELDA and the Waqafer app
class TentangKamiPage extends StatelessWidget {
  const TentangKamiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Tentang WAQAFER — dikekalkan dari code asal
                    _buildWaqaferCard(),
                    const SizedBox(height: 20),

                    // Location Card
                    _buildLocationCard(),
                    const SizedBox(height: 20),

                    // Saluran Perhubungan
                    _buildContactChannels(),
                    const SizedBox(height: 20),

                    // Media Sosial
                    _buildSocialMedia(),
                    const SizedBox(height: 16),

                    // Copyright
                    Center(
                      child: Text(
                        '© WAQAF FELDA',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header dengan gradient hijau Waqafer
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF11998E), Color(0xFF11998E)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tentang Kami',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── DIKEKALKAN DARI CODE ASAL ─────────────────────────────────────────────

  /// Builds card explaining what the Waqafer mobile app is
  Widget _buildWaqaferCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4DB6AC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  size: 24,
                  color: Color(0xFF4DB6AC),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tentang WAQAFER',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Aplikasi mudah alih yang memudahkan masyarakat untuk berwakaf dan menyertai program-program wakaf yang bermanfaat.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.7,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── BAHAGIAN BARU ─────────────────────────────────────────────────────────

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF11998E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF11998E),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Ibu Pejabat WAQAF FELDA',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Level 18, Menara Felda,\nPlatinum Park, No. 11, Persiaran KLCC,\n50088 Kuala Lumpur',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              // TODO: launch Google Maps
            },
            child: const Text(
              'Lihat di Peta →',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF11998E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChannels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SALURAN PERHUBUNGAN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildContactRow(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF11998E),
                label: 'Laman Web',
                value: 'waqaffelda.com.my',
                showChevron: true,
                onTap: () {
                  // TODO: launch browser
                },
              ),
              Divider(height: 1, indent: 66, color: Colors.grey.shade100),
              _buildContactRow(
                icon: Icons.phone_rounded,
                iconColor: const Color(0xFF3B82F6),
                label: 'Telefon',
                value: '+6012-652 3046',
                onTap: () {
                  // TODO: launch phone dialer
                },
              ),
              Divider(height: 1, indent: 66, color: Colors.grey.shade100),
              _buildContactRow(
                icon: Icons.email_rounded,
                iconColor: const Color(0xFFEF4444),
                label: 'E-mel',
                value: 'waqaf.felda@felda.net.my',
                onTap: () {
                  // TODO: launch email
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool showChevron = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: iconColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEDIA SOSIAL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIcon(
              label: 'TikTok',
              gradient: const LinearGradient(
                colors: [Color(0xFF2D2D2D), Color(0xFF111111)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: const Icon(Icons.music_note_rounded,
                  color: Colors.white, size: 24),
              onTap: () {}, // TODO: TikTok
            ),
            const SizedBox(width: 20),
            _socialIcon(
              label: 'Facebook',
              gradient: const LinearGradient(
                colors: [Color(0xFF1877F2), Color(0xFF0C5FCC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: const Text(
                'f',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              onTap: () {}, // TODO: Facebook
            ),
            const SizedBox(width: 20),
            _socialIcon(
              label: 'Instagram',
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF833AB4),
                  Color(0xFFE1306C),
                  Color(0xFFF77737),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 22),
              onTap: () {}, // TODO: Instagram
            ),
            const SizedBox(width: 20),
            _socialIcon(
              label: 'YouTube',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 30),
              onTap: () {}, // TODO: YouTube
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialIcon({
    required String label,
    required Gradient gradient,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: child),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CODE ASAL — DICOMMENT, BOLEH UNCOMMENT BILA PERLU
  // =========================================================================

  // /// Builds the main about card with WAQAF FELDA mission statement
  // Widget _buildMainAboutCard() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [const Color(0xFF4DB6AC), const Color(0xFF26A69A)],
  //       ),
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: const Color(0xFF4DB6AC).withOpacity(0.3),
  //           blurRadius: 15,
  //           offset: const Offset(0, 8),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         const Icon(Icons.info_rounded, size: 32, color: Colors.white),
  //         const SizedBox(height: 20),
  //         Text(
  //           'WAQAF FELDA bertujuan memupuk budaya memberi dan kebersamaan dalam kalangan peneroka, serta mewujudkan kuasa ekonomi ketiga berasaskan kesukarelawanan.',
  //           textAlign: TextAlign.center,
  //           style: TextStyle(fontSize: 15, color: Colors.white, height: 1.7, letterSpacing: 0.2),
  //         ),
  //         const SizedBox(height: 16),
  //         Container(height: 1, width: 60, color: Colors.white.withOpacity(0.4)),
  //         const SizedBox(height: 16),
  //         Text(
  //           'Melalui konsep Wakaf Korporat, WAQAF FELDA menyalurkan pelbagai manfaat bukan sahaja untuk kebajikan, malah sedekah jariah yang memberi keberkatan kepada warga FELDA dan masyarakat Malaysia.',
  //           textAlign: TextAlign.center,
  //           style: TextStyle(fontSize: 15, color: Colors.white, height: 1.7, letterSpacing: 0.2),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // /// Builds card highlighting the real-time notification feature
  // Widget _buildRealtimeNotificationCard() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
  //       ],
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFF4DB6AC).withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: const Icon(Icons.notifications_active_rounded, size: 28, color: Color(0xFF4DB6AC)),
  //         ),
  //         const SizedBox(width: 16),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(
  //                 'Pemberitahuan Real-time',
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 'Update terkini terus ke peranti anda',
  //                 style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // /// Builds card displaying app version, copyright, and establishment year
  // Widget _buildAppInfoCard() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         _buildInfoRow(Icons.verified_rounded, 'Versi Aplikasi', '1.0.0', const Color(0xFF4DB6AC)),
  //         const SizedBox(height: 16),
  //         Divider(height: 1, color: Colors.grey.shade200),
  //         const SizedBox(height: 16),
  //         _buildInfoRow(Icons.copyright_rounded, 'Hak Cipta', '© WAQAF FELDA', const Color(0xFF26A69A)),
  //         const SizedBox(height: 16),
  //         Divider(height: 1, color: Colors.grey.shade200),
  //         const SizedBox(height: 16),
  //         _buildInfoRow(Icons.date_range_rounded, 'Tahun Ditubuhkan', '2021', const Color(0xFF4DB6AC)),
  //       ],
  //     ),
  //   );
  // }

  // /// Builds a single information row with icon, label, and value
  // Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
  //   return Row(
  //     children: [
  //       Container(
  //         padding: const EdgeInsets.all(10),
  //         decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
  //         child: Icon(icon, size: 22, color: color),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600, letterSpacing: 0.2)),
  //             const SizedBox(height: 4),
  //             Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), letterSpacing: 0.2)),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // /// Builds contact section — versi lama (email sahaja)
  // Widget _buildContactSection() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF2C3E50),
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(color: const Color(0xFF2C3E50).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         const Icon(Icons.email_rounded, size: 36, color: Colors.white),
  //         const SizedBox(height: 12),
  //         const Text('Hubungi Kami', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3)),
  //         const SizedBox(height: 8),
  //         Text('waqaf.felda@felda.net.my', style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
  //       ],
  //     ),
  //   );
  // }

  // =========================================================================
  // OLD APPBAR — DICOMMENT, BOLEH UNCOMMENT DAN GUNA BALIK
  // Padam _buildHeader() dan gunakan AppBar ni dalam Scaffold jika perlu
  // =========================================================================

  // appBar: AppBar(
  //   backgroundColor: Colors.white,
  //   elevation: 0,
  //   leading: IconButton(
  //     icon: Container(
  //       padding: const EdgeInsets.all(8),
  //       decoration: BoxDecoration(
  //         color: const Color(0xFF4DB6AC).withOpacity(0.1),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4DB6AC), size: 20),
  //     ),
  //     onPressed: () => Navigator.pop(context),
  //   ),
  //   title: const Text(
  //     'Tentang Kami',
  //     style: TextStyle(color: Color(0xFF2C3E50), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.3),
  //   ),
  //   centerTitle: false,
  // ),
}
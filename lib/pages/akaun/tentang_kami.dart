import 'package:flutter/material.dart';

class TentangKamiPage extends StatelessWidget {
  const TentangKamiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4DB6AC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4DB6AC), size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tentang Kami',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F7FA),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Logo - simple version
                  Image.asset(
                    'assets/images/waqaf_felda_logo.png',
                    width: 160,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  // Tagline - simple version
                  Text(
                    '" Kejayaan Dalam Keberkatan "',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF4DB6AC),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                children: [
                  // Main About Card
                  _buildMainAboutCard(),
                  const SizedBox(height: 20),

                  // About Waqafer Card
                  _buildWaqaferCard(),
                  const SizedBox(height: 20),

                  // Real-time Notification Feature
                  _buildRealtimeNotificationCard(),
                  const SizedBox(height: 20),

                  // App Info Card
                  _buildAppInfoCard(),
                  const SizedBox(height: 20),

                  // Contact Section
                  _buildContactSection(),
                  
                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4DB6AC),
            const Color(0xFF26A69A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4DB6AC).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_rounded,
            size: 32,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          Text(
            'WAQAF FELDA bertujuan memupuk budaya memberi dan kebersamaan dalam kalangan peneroka, serta mewujudkan kuasa ekonomi ketiga berasaskan kesukarelawanan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.7,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            width: 60,
            color: Colors.white.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Melalui konsep Wakaf Korporat, WAQAF FELDA menyalurkan pelbagai manfaat bukan sahaja untuk kebajikan, malah sedekah jariah yang memberi keberkatan kepada warga FELDA dan masyarakat Malaysia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.7,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeNotificationCard() {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4DB6AC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 28,
              color: Color(0xFF4DB6AC),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pemberitahuan Real-time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update terkini terus ke peranti anda',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildAppInfoCard() {
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
          _buildInfoRow(
            Icons.verified_rounded,
            'Versi Aplikasi',
            '1.0.0',
            const Color(0xFF4DB6AC),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.copyright_rounded,
            'Hak Cipta',
            '© WAQAF FELDA',
            const Color(0xFF26A69A),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.date_range_rounded,
            'Tahun Ditubuhkan',
            '2021',
            const Color(0xFF4DB6AC),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.email_rounded,
            size: 36,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Hubungi Kami',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'waqaf.felda@felda.net.my',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

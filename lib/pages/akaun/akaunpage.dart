import 'package:flutter/material.dart';
import '../../navbar.dart';
import '../homepage/homepage.dart';
import '../program/program_page.dart';
import '../waqaf/waqafpage.dart';
import '../inbox/inboxpage.dart';
import 'tentang_kami.dart';

//test
class AkaunPage extends StatefulWidget {
  const AkaunPage({Key? key}) : super(key: key);

  @override
  _AkaunPageState createState() => _AkaunPageState();
}

class _AkaunPageState extends State<AkaunPage> {
  int _currentIndex = 4; // Tetapkan indeks semasa untuk AkaunPage
  final ScrollController _scrollController = ScrollController();

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    // Logik navigasi yang sama seperti dalam homepage.dart
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, _createPageRoute(const Homepage()));
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          _createPageRoute(const ProgramPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(context, _createPageRoute(const WaqafPage()));
        break;
      case 3:
        Navigator.pushReplacement(context, _createPageRoute(const InboxPage()));
        break;
      case 4:
        // Sudah berada di AkaunPage
        break;
    }
  }

  // Helper untuk mencipta route tanpa animasi
  PageRouteBuilder _createPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Akaun',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Bahagian Profil Pengguna
              _buildProfileHeader(),
              const SizedBox(height: 32),
              // Menu Tetapan
              _buildSettingsList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      // Gunakan BottomNavBar yang sama
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        scrollController: _scrollController,
      ),
    );
  }

  // Widget untuk header profil
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DB6AC), Color(0xFF26A69A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4DB6AC).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mode Tetamu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Menggunakan aplikasi sebagai tetamu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk senarai menu
  Widget _buildSettingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Maklumat Aplikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              letterSpacing: 0.3,
            ),
          ),
        ),
        _buildSettingsItem(
          icon: Icons.info_outline_rounded,
          title: 'Tentang Kami',
          subtitle: 'Ketahui lebih lanjut tentang aplikasi',
        ),
        const SizedBox(height: 24),
        // Version info at bottom
        Center(
          child: Column(
            children: [
              Text(
                'Versi 1.0.2-beta+3',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '© 2025 Waqaf FELDA',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget untuk setiap item dalam senarai menu
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              trailing == null || title == 'Tentang Kami'
                  ? () {
                    if (title == 'Tentang Kami') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TentangKamiPage(),
                        ),
                      );
                    }
                  }
                  : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4DB6AC).withOpacity(0.15),
                        const Color(0xFF4DB6AC).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF4DB6AC), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (title == 'Tentang Kami')
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

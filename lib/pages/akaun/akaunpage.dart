import 'package:flutter/material.dart';
import '../../navbar.dart';
import '../../main.dart';
import '../homepage/homepage.dart';
import '../program/program_page.dart';
import '../waqaf/waqafpage.dart';
import '../kedai/kedai.dart';
import 'tentang_kami.dart';

/// Account/Profile Page
/// Displays user information in guest mode and app information
class AkaunPage extends StatefulWidget {
  const AkaunPage({Key? key}) : super(key: key);

  @override
  _AkaunPageState createState() => _AkaunPageState();
}

class _AkaunPageState extends State<AkaunPage> {
  int _currentIndex = 4; // Set current index for AkaunPage in bottom navigation
  final ScrollController _scrollController = ScrollController();

  /// Handles bottom navigation bar tab taps
  /// Navigates to different pages based on selected index
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

  /// Creates a page route without transition animation
  /// Used for smooth navigation between bottom nav pages
  PageRouteBuilder _createPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Akaun',
          style: TextStyle(
            color: colorScheme.onBackground,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
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
      ),
      // Gunakan BottomNavBar yang sama
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        scrollController: _scrollController,
      ),
    );
  }

  /// Builds the profile header section with gradient background
  /// Displays guest mode icon and user status
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mode Tetamu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Menggunakan aplikasi sebagai tetamu',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the settings/menu list section
  /// Contains app information and version details
  Widget _buildSettingsList() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Maklumat Aplikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
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
                'Versi 1.0.0',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onBackground.withOpacity(0.7),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '© 2025 Waqaf FELDA',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onBackground.withOpacity(0.6),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds individual menu item card with icon, title, and subtitle
  /// Navigates to respective page when tapped
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
                        colorScheme.primary.withOpacity(0.15),
                        colorScheme.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onBackground,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onBackground.withOpacity(0.7),
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
                    color: colorScheme.onBackground.withOpacity(0.4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../navbar.dart'; // Pastikan import ini betul
import '../../homepage/homepage.dart'; // Import untuk navigasi
import '../program/program_page.dart'; // Import untuk navigasi
import '../waqaf/waqafpage.dart'; // Import untuk navigasi
import '../inbox/inboxpage.dart'; // Import untuk navigasi

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
        Navigator.pushReplacement(context, _createPageRoute(const ProgramPage()));
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
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Stack(
          children: [
            // Latar belakang bergradien yang sama seperti Homepage
            Container(
              height: screenHeight * 0.25 + statusBarHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.teal.shade400.withOpacity(0.3),
                    const Color(0xFFFBC02D).withOpacity(0.2),
                    Colors.white,
                  ],
                ),
              ),
            ),
            // Kandungan utama dengan SafeArea
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Bahagian Profil Pengguna
                    _buildProfileHeader(),
                    const SizedBox(height: 30),
                    // Menu Tetapan
                    _buildSettingsList(),
                    const SizedBox(height: 20),
                    // Butang Log Keluar
                    _buildLogoutButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
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
    return Row(
      children: [
        const CircleAvatar(
          radius: 35,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, size: 40, color: Colors.white),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Guest', // Nama Pengguna
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'guest@example.com', // Emel pengguna atau status
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget untuk senarai menu
  Widget _buildSettingsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(icon: Icons.edit_outlined, title: 'Edit Profil'),
          _buildSettingsItem(icon: Icons.favorite_border, title: 'Kegemaran'),
          _buildSettingsItem(icon: Icons.download_outlined, title: 'Muat Turun'),
          _buildSettingsItem(icon: Icons.location_on_outlined, title: 'Lokasi'),
          _buildSettingsItem(icon: Icons.brightness_6_outlined, title: 'Night Mode', isSwitch: true),
          _buildSettingsItem(icon: Icons.delete_outline, title: 'Padam Cache'),
          _buildSettingsItem(icon: Icons.history, title: 'Sejarah'),
        ],
      ),
    );
  }

  // Widget untuk setiap item dalam senarai menu
  Widget _buildSettingsItem({required IconData icon, required String title, bool isSwitch = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Tambah logik untuk setiap item di sini
          print('$title diklik');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade700, size: 24),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              if (isSwitch)
                Switch(
                  value: false, // Anda boleh gantikan dengan state sebenar
                  onChanged: (value) {
                    // Logik untuk menukar night mode
                  },
                  activeColor: Colors.teal,
                )
              else
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk butang Log Keluar
  Widget _buildLogoutButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          // Logik untuk log keluar
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Log Keluar',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        ),
      ),
    );
  }
}
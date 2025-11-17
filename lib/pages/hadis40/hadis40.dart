import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class Hadis40Page extends StatefulWidget {
  const Hadis40Page({Key? key}) : super(key: key);

  @override
  State<Hadis40Page> createState() => _Hadis40PageState();
}

class _Hadis40PageState extends State<Hadis40Page>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> hadisList = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadHadis();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHadis() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/hadis_40_nawawi.json',
      );
      final List<dynamic> data = json.decode(response);
      setState(() {
        hadisList = data.cast<Map<String, dynamic>>();
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print('Error loading hadis: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // Deep Indigo
              Color(0xFF283593),
              Color(0xFF3949AB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Animated Header
              _buildAnimatedHeader(size),

              // Main Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                    child:
                        isLoading
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF1A237E,
                                          ).withOpacity(0.2),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: const CircularProgressIndicator(
                                      color: Color(0xFF1A237E),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Memuatkan hadis...',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  // Stats Cards
                                  _buildStatsSection(),
                                  const SizedBox(height: 16),
                                  // Hadis List
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        0,
                                        20,
                                        20,
                                      ),
                                      itemCount: hadisList.length,
                                      itemBuilder: (context, index) {
                                        return _buildModernHadisCard(
                                          hadisList[index],
                                          index,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(Size size) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        children: [
          Row(
            children: [
              // Back Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBC02D),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFBC02D).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'KOLEKSI PILIHAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hadis 40+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Imam An-Nawawi & Tambahan',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.library_books_rounded,
              value: '${hadisList.length}',
              label: 'Hadis',
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.verified_rounded,
              value: 'Sahih',
              label: 'Status',
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.stars_rounded,
              value: '100%',
              label: 'Lengkap',
              color: const Color(0xFFF57C00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHadisCard(Map<String, dynamic> hadis, int index) {
    final colors = [
      [const Color(0xFF1A237E), const Color(0xFF3949AB)],
      [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
      [const Color(0xFFF57C00), const Color(0xFFFFB74D)],
      [const Color(0xFFC62828), const Color(0xFFEF5350)],
      [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
    ];
    final colorSet = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorSet[0].withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showModernHadisDetail(hadis, colorSet),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Number Badge
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colorSet,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: colorSet[0].withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${hadis['number']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HADIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right side - Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        hadis['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Narrator
                      Row(
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            size: 16,
                            color: colorSet[0].withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hadis['narrator'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Preview Text
                      Text(
                        hadis['translation'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bottom Row
                      Row(
                        children: [
                          // Reference Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorSet[0].withOpacity(0.1),
                                  colorSet[1].withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorSet[0].withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: colorSet[0],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  hadis['reference'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorSet[0],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Arrow Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorSet[0].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: colorSet[0],
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
      ),
    );
  }

  void _showModernHadisDetail(
    Map<String, dynamic> hadis,
    List<Color> colorSet,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colorSet),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24),
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: colorSet,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: colorSet[0].withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${hadis['number']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hadis['title'],
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              hadis['reference'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
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
                          const SizedBox(height: 24),

                          // Narrator
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorSet[0].withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: colorSet),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Perawi Hadis',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: colorSet[0],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hadis['narrator'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Arabic Text
                          _buildSectionHeader('Teks Arab', colorSet[0]),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF8E1), Color(0xFFFFF9C4)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFBC02D).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              hadis['arabic'],
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 22,
                                height: 2.2,
                                color: Colors.black87,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Translation
                          _buildSectionHeader('Terjemahan', colorSet[0]),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorSet[0].withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              hadis['translation'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                height: 1.8,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

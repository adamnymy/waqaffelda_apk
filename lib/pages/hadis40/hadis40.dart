import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'hadis40_detail.dart';

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
  String selectedFilter = 'Semua';
  double fontSize = 1.0; // Font size multiplier

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '40 Hadis',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.text_fields_rounded, color: colorScheme.onSurface),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Saiz Teks'),
                      content: StatefulBuilder(
                        builder:
                            (context, setState) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'A',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    const Text(
                                      'A',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: fontSize,
                                  min: 0.8,
                                  max: 1.5,
                                  divisions: 14,
                                  activeColor: const Color(0xFF00897B),
                                  onChanged: (value) {
                                    setState(() {
                                      this.setState(() {
                                        fontSize = value;
                                      });
                                    });
                                  },
                                ),
                              ],
                            ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),

          // Main Content
          Expanded(child: isLoading ? _buildLoadingState() : _buildHadisList()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', '1-10', '11-20', '21-30', '31-42'];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8, top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF00897B),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              backgroundColor: Colors.grey[100],
              selectedColor: const Color(0xFF00897B),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color:
                    isSelected ? const Color(0xFF00897B) : Colors.grey.shade300,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (selected) {
                setState(() {
                  selectedFilter = filter;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00897B).withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF00897B),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Memuatkan hadis...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHadisList() {
    final filteredList = _getFilteredHadis();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          return _buildGlassMorphicCard(filteredList[index], index);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredHadis() {
    if (selectedFilter == 'Semua') return hadisList;

    final ranges = {
      '1-10': [1, 10],
      '11-20': [11, 20],
      '21-30': [21, 30],
      '31-42': [31, 42],
    };

    final range = ranges[selectedFilter];
    if (range == null) return hadisList;

    return hadisList.where((hadis) {
      final num = hadis['number'] as int;
      return num >= range[0] && num <= range[1];
    }).toList();
  }

  Widget _buildGlassMorphicCard(Map<String, dynamic> hadis, int index) {
    final colors = [
      [const Color(0xFF00897B), const Color(0xFF4DB6AC)],
      [const Color(0xFFFBC02D), const Color(0xFFFDD835)],
      [const Color(0xFF00695C), const Color(0xFF00897B)],
      [const Color(0xFFF57C00), const Color(0xFFFFB74D)],
      [const Color(0xFF00897B), const Color(0xFF80CBC4)],
    ];
    final colorSet = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: colorSet[0].withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          HadisDetailPage(hadis: hadis, colorSet: colorSet),
                ),
              ),
          borderRadius: BorderRadius.circular(20),
          splashColor: colorSet[0].withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Arabic Number Badge
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colorSet,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorSet[0].withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _toArabicNumber(hadis['number']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        hadis['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17 * fontSize,
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
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorSet[0].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: colorSet[0],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hadis['narrator'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12 * fontSize,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                              Icons.menu_book_rounded,
                              size: 12,
                              color: colorSet[0],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hadis['reference'],
                              style: TextStyle(
                                fontSize: 11,
                                color: colorSet[0],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorSet[0].withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicDigits[int.parse(digit)])
        .join();
  }
}

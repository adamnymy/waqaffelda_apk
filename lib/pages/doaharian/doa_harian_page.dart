import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class DoaHarianPage extends StatefulWidget {
  const DoaHarianPage({Key? key}) : super(key: key);

  @override
  _DoaHarianPageState createState() => _DoaHarianPageState();
}

class _DoaHarianPageState extends State<DoaHarianPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  final Set<String> _favorites = {};
  List<Map<String, dynamic>> _doaList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final List<String> _categories = [
    'Semua',
    'Doa Pagi',
    'Doa Petang',
    'Doa Selepas Solat',
    'Doa Lain-lain',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoaData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoaData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Load JSON data from assets
      final String jsonString = await rootBundle.loadString(
        'assets/data/doa_harian.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      // Convert JSON data to the format expected by the UI
      final List<Map<String, dynamic>> loadedDoa =
          jsonData.map((item) {
            return {
              'id': item['id'],
              'title': item['title'],
              'category': item['category'],
              'arabic': item['arabic'],
              'malay': item['malay'],
              'icon': _getIconFromString(item['icon']),
              'color': _getColorFromString(item['color']),
            };
          }).toList();

      setState(() {
        _doaList = loadedDoa;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuatkan data doa: $e';
        _isLoading = false;
      });
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'home':
        return Icons.home;
      case 'door_front_door':
        return Icons.door_front_door;
      case 'restaurant':
        return Icons.restaurant;
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'mosque':
        return Icons.mosque;
      case 'exit_to_app':
        return Icons.exit_to_app;
      case 'nightlight_round':
        return Icons.nightlight_round;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'star':
        return Icons.star;
      default:
        return Icons.book;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'deepPurple':
        return Colors.deepPurple;
      case 'amber':
        return Colors.amber;
      case 'pink':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> get _filteredDoaList {
    return _doaList.where((doa) {
      final matchesCategory =
          _selectedCategory == 'Semua' || doa['category'] == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          doa['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doa['arabic'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doa['malay'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Doa Harian',
          style: TextStyle(
            color: Colors.black87,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: _favorites.isNotEmpty ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              // TODO: Navigate to favorites page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Halaman Kegemaran - Coming Soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              )
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ralat Memuatkan Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadDoaData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cuba Lagi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Search Bar
                  Container(
                    margin: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari doa...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  // Category Tabs
                  Container(
                    height: 50,
                    margin: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.teal : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.teal
                                        : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Doa List
                  Expanded(
                    child:
                        _filteredDoaList.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tiada doa dijumpai',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              itemCount: _filteredDoaList.length,
                              itemBuilder: (context, index) {
                                final doa = _filteredDoaList[index];
                                final isFavorite = _favorites.contains(
                                  doa['id'],
                                );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header with icon and favorite
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: (doa['color'] as Color)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                doa['icon'] as IconData,
                                                color: doa['color'] as Color,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    doa['title'],
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  Text(
                                                    doa['category'],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isFavorite
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color:
                                                    isFavorite
                                                        ? Colors.red
                                                        : Colors.grey,
                                              ),
                                              onPressed:
                                                  () => _toggleFavorite(
                                                    doa['id'],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Arabic Text
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Arab',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.teal,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              doa['arabic'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.black87,
                                                fontFamily: 'Amiri',
                                                height: 1.6,
                                              ),
                                              textAlign: TextAlign.right,
                                              textDirection: TextDirection.rtl,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Melayu',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.teal,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              doa['malay'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                                height: 1.5,
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
                  ),
                ],
              ),
    );
  }
}

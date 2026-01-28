import 'package:flutter/material.dart';
import '../../prayertimes/prayertimes.dart';
import '../../kiblat/kiblat.dart';
import '../../quran/quranpage.dart';
import '../../zikircounter/zikircounter.dart';
import '../../doaharian/doa_harian_page.dart';
import '../../tahlil/tahlil.dart';
import '../../masjid_terdekat/masjid_terdekat.dart';
import '../../hadis40/hadis40.dart';
import '../../kalendar/kalendar_islam.dart';


class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
  
  // Teal theme colors
  static const Color primaryTeal = Color(0xFF00897B);
  static const Color darkTeal = Color(0xFF00695C);
  static const Color lightTeal = Color(0xFFE0F2F1);
  
  final List<IslamicTool> _allTools = [
    // Ibadah
    IslamicTool(
      title: 'Waktu Solat',
      description: 'Jadual waktu solat harian berdasarkan lokasi anda',
      icon: Icons.access_time_rounded,
      iconBgColor: const Color(0xFF00897B),
      category: 'Ibadah',
      keywords: ['solat', 'prayer', 'waktu', 'jadual', 'subuh', 'zohor', 'asar', 'maghrib', 'isyak'],
      page: const PrayerTimesPage(),
    ),
    IslamicTool(
      title: 'Arah Kiblat',
      description: 'Cari arah kiblat dengan mudah menggunakan kompas digital',
      icon: Icons.explore_rounded,
      iconBgColor: const Color(0xFFFF6F00),
      category: 'Ibadah',
      keywords: ['kiblat', 'qiblat', 'kompas', 'arah', 'mekah', 'kaabah'],
      page: const KiblatPage(),
    ),
    IslamicTool(
      title: 'Tasbih Digital',
      description: 'Kira zikir dan tasbih dengan mudah secara digital',
      icon: Icons.touch_app_rounded,
      iconBgColor: const Color(0xFF5E35B1),
      category: 'Ibadah',
      keywords: ['tasbih', 'zikir', 'dzikir', 'counter', 'subhanallah', 'alhamdulillah', 'allahuakbar'],
      page: const ZikirCounterPage(),
    ),
    IslamicTool(
      title: 'Doa Harian',
      description: 'Koleksi doa harian lengkap untuk amalan seharian',
      icon: Icons.auto_stories_rounded,
      iconBgColor: const Color(0xFFE53935),
      category: 'Ibadah',
      keywords: ['doa', 'dua', 'harian', 'makan', 'tidur', 'bangun', 'amalan'],
      page: const DoaHarianPage(),
    ),
    IslamicTool(
      title: 'Bacaan Tahlil',
      description: 'Panduan bacaan tahlil lengkap dengan terjemahan',
      icon: Icons.people_outline_rounded,
      iconBgColor: const Color(0xFF00897B),
      category: 'Ibadah',
      keywords: ['tahlil', 'arwah', 'kenduri', 'yasin', 'bacaan'],
      page: const TahlilPage(),
    ),
    
    // Al-Quran & Ilmu
    IslamicTool(
      title: 'Al-Quran',
      description: 'Baca Al-Quran dengan terjemahan dan tafsir lengkap',
      icon: Icons.menu_book,
      iconBgColor: const Color(0xFF1565C0),
      category: 'Al-Quran & Ilmu',
      keywords: ['quran', 'alquran', 'surah', 'ayat', 'baca', 'tilawah', 'juz'],
      page: const QuranPage(),
    ),
    IslamicTool(
      title: 'Hadith 40',
      description: 'Hadith 40 Imam Nawawi dengan terjemahan Bahasa Melayu',
      icon: Icons.import_contacts_rounded,
      iconBgColor: const Color(0xFF1976D2),
      category: 'Al-Quran & Ilmu',
      keywords: ['hadith', 'hadis', 'nawawi', '40', 'sunnah', 'rasulullah'],
      page: const Hadis40Page(),
    ),
    
    // Kemudahan
    IslamicTool(
      title: 'Masjid Terdekat',
      description: 'Cari masjid atau surau yang berhampiran dengan lokasi anda',
      icon: Icons.mosque,
      iconBgColor: const Color(0xFF43A047),
      category: 'Kemudahan',
      keywords: ['masjid', 'surau', 'mosque', 'lokasi', 'dekat', 'nearby', 'cari'],
      page: const MasjidTerdekatPage(),
    ),
    IslamicTool(
      title: 'Kalendar Islam',
      description: 'Kalendar Hijriah dengan peristiwa penting Islam',
      icon: Icons.calendar_month_rounded,
      iconBgColor: const Color(0xFFFBC02D),
      category: 'Kemudahan',
      keywords: ['kalendar', 'hijriah', 'tarikh', 'islam', 'ramadan', 'syawal', 'bulan'],
      page: const CombinedCalendarPage(),
    ),
  ];

  List<IslamicTool> _filteredTools = [];
  List<String> _recentSearches = ['Waktu Solat', 'Al-Quran', 'Doa'];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredTools = _allTools;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  void _filterTools(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredTools = _allTools;
      } else {
        _filteredTools = _allTools.where((tool) {
          final queryLower = query.toLowerCase();
          return tool.title.toLowerCase().contains(queryLower) ||
              tool.description.toLowerCase().contains(queryLower) ||
              tool.category.toLowerCase().contains(queryLower) ||
              tool.keywords.any((keyword) => keyword.toLowerCase().contains(queryLower));
        }).toList();
      }
    });
  }

  void _onToolTap(IslamicTool tool) {
    // Add to recent searches if not already there
    if (!_recentSearches.contains(tool.title)) {
      setState(() {
        _recentSearches.insert(0, tool.title);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => tool.page),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isSearching || _searchController.text.isNotEmpty
                  ? _buildSearchResults()
                  : _buildDefaultContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryTeal, darkTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Carian',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: primaryTeal,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari Islamic tools...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: _filterTools,
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _filterTools('');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade600,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Recent searches
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carian Terkini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _recentSearches.clear();
                  });
                },
                child: Text(
                  'Padam Semua',
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryTeal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _recentSearches.map((search) => _buildRecentChip(search)).toList(),
          ),
          const SizedBox(height: 28),
        ],
        
        // Quick access - Popular tools
        Text(
          'Popular',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        _buildPopularGrid(),
        
        const SizedBox(height: 28),
        
        // All categories
        Text(
          'Semua Kategori',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        _buildCategoryList(),
      ],
    );
  }

  Widget _buildRecentChip(String search) {
    return GestureDetector(
      onTap: () {
        _searchController.text = search;
        _filterTools(search);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: lightTeal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryTeal.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 16,
              color: primaryTeal,
            ),
            const SizedBox(width: 8),
            Text(
              search,
              style: TextStyle(
                color: darkTeal,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularGrid() {
    final popularTools = _allTools.take(4).toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: popularTools.length,
      itemBuilder: (context, index) {
        final tool = popularTools[index];
        return _buildPopularCard(tool);
      },
    );
  }

  Widget _buildPopularCard(IslamicTool tool) {
    return GestureDetector(
      onTap: () => _onToolTap(tool),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tool.iconBgColor,
              tool.iconBgColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: tool.iconBgColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                tool.icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tool.category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final categories = _allTools.map((t) => t.category).toSet().toList();
    
    return Column(
      children: categories.map((category) {
        final categoryTools = _allTools.where((t) => t.category == category).toList();
        final IconData categoryIcon;
        
        switch (category) {
          case 'Ibadah':
            categoryIcon = Icons.mosque_outlined;
            break;
          case 'Al-Quran & Ilmu':
            categoryIcon = Icons.menu_book_rounded;
            break;
          case 'Kemudahan':
            categoryIcon = Icons.location_on_outlined;
            break;
          default:
            categoryIcon = Icons.apps;
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: lightTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryIcon,
                  color: primaryTeal,
                  size: 22,
                ),
              ),
              title: Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              subtitle: Text(
                '${categoryTools.length} Perkara',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              children: categoryTools.map((tool) => _buildToolListItem(tool)).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToolListItem(IslamicTool tool) {
    return InkWell(
      onTap: () => _onToolTap(tool),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tool.iconBgColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                tool.icon,
                color: tool.iconBgColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                tool.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredTools.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredTools.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${_filteredTools.length} hasil dijumpai',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }
        
        final tool = _filteredTools[index - 1];
        return _buildSearchResultCard(tool, index - 1);
      },
    );
  }

  Widget _buildSearchResultCard(IslamicTool tool, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onToolTap(tool),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tool.iconBgColor,
                          tool.iconBgColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: tool.iconBgColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      tool.icon,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tool.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: lightTeal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tool.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: darkTeal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: lightTeal,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: primaryTeal,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tiada hasil dijumpai',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuba cari dengan kata kunci lain',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              _filterTools('');
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset Carian'),
            style: TextButton.styleFrom(
              foregroundColor: primaryTeal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Model class for Islamic Tool
class IslamicTool {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBgColor;
  final String category;
  final List<String> keywords;
  final Widget page;

  IslamicTool({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBgColor,
    required this.category,
    required this.keywords,
    required this.page,
  });
}
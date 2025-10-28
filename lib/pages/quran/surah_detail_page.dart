import 'package:flutter/material.dart';
import '../../services/quran_service.dart';
import '../../models/quran_models.dart';

class SurahDetailPage extends StatefulWidget {
  final Surah surah;

  const SurahDetailPage({Key? key, required this.surah}) : super(key: key);

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  List<Ayah> ayahs = [];
  bool isLoading = true;
  String errorMessage = '';
  Set<int> bookmarkedAyahs = {}; // Store bookmarked ayah numbers
  double arabicFontSize = 28.0;
  double translationFontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadSurahDetail();
  }

  Future<void> _loadSurahDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final fetchedAyahs = await QuranService.getSurahAyahs(
        widget.surah.number,
      );
      setState(() {
        ayahs = fetchedAyahs;
        isLoading = false;
      });
      print(
        '✅ Loaded ${fetchedAyahs.length} ayahs for ${widget.surah.englishName}',
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuatkan ayat: $e';
        isLoading = false;
      });
      print('❌ Error loading ayahs: $e');
    }
  }

  void _toggleBookmark(int ayahNumber) {
    setState(() {
      if (bookmarkedAyahs.contains(ayahNumber)) {
        bookmarkedAyahs.remove(ayahNumber);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tandabuku dialih keluar'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        bookmarkedAyahs.add(ayahNumber);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ditambah ke tandabuku'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Saiz Tulisan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Arabic font size
                  const Text(
                    'Arab',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: arabicFontSize,
                    min: 20,
                    max: 40,
                    divisions: 10,
                    label: arabicFontSize.round().toString(),
                    onChanged: (value) {
                      setDialogState(() {
                        arabicFontSize = value;
                      });
                      setState(() {});
                    },
                  ),
                  Text('${arabicFontSize.round()}'),
                  const SizedBox(height: 16),
                  // Translation font size
                  const Text(
                    'Terjemahan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: translationFontSize,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    label: translationFontSize.round().toString(),
                    onChanged: (value) {
                      setDialogState(() {
                        translationFontSize = value;
                      });
                      setState(() {});
                    },
                  ),
                  Text('${translationFontSize.round()}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      arabicFontSize = 28.0;
                      translationFontSize = 16.0;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Surah Info
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: colorScheme.primary,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.text_fields, color: colorScheme.onPrimary),
                onPressed: _showFontSizeDialog,
                tooltip: 'Saiz Tulisan',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Arabic Name
                        Text(
                          widget.surah.name,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                            fontFamily: 'Amiri',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        // Transliteration
                        Text(
                          widget.surah.englishName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimary.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Meaning
                        Text(
                          widget.surah.malayTranslation,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Ayat count and revelation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.onPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.surah.numberOfAyahs} Ayat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.onPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.surah.revelationType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          if (isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (errorMessage.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadSurahDetail,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Cuba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  // Show Bismillah before first ayah (except Al-Fatihah and At-Taubah)
                  if (index == 0 &&
                      widget.surah.number != 1 &&
                      widget.surah.number != 9) {
                    return Column(
                      children: [
                        _buildBismillah(colorScheme),
                        const SizedBox(height: 24),
                        _buildAyahCard(ayahs[0], colorScheme),
                      ],
                    );
                  }

                  final ayahIndex =
                      widget.surah.number != 1 &&
                              widget.surah.number != 9 &&
                              index > 0
                          ? index
                          : index;

                  if (ayahIndex >= ayahs.length) return null;

                  return _buildAyahCard(ayahs[ayahIndex], colorScheme);
                }, childCount: ayahs.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBismillah(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        style: TextStyle(
          fontSize: arabicFontSize + 4,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
          fontFamily: 'Amiri',
          height: 2.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAyahCard(Ayah ayah, ColorScheme colorScheme) {
    final isBookmarked = bookmarkedAyahs.contains(ayah.numberInSurah);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayah Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Ayah Number Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${ayah.numberInSurah}',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ayat ${ayah.numberInSurah}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const Spacer(),
                // Bookmark Button
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color:
                        isBookmarked
                            ? colorScheme.secondary
                            : colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () => _toggleBookmark(ayah.numberInSurah),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Ayah Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Arabic Text
                Text(
                  ayah.text,
                  style: TextStyle(
                    fontSize: arabicFontSize,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontFamily: 'Amiri',
                    height: 2.0,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16),
                // Divider
                Container(
                  height: 1,
                  color: colorScheme.primary.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                // Translation
                Text(
                  ayah.translation ?? 'Terjemahan tidak tersedia',
                  style: TextStyle(
                    fontSize: translationFontSize,
                    color: colorScheme.onSurface.withOpacity(0.8),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

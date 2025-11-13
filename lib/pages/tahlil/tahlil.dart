import 'package:flutter/material.dart';
import '../../models/tahlil_model.dart';
import '../../services/tahlil_service.dart';

class TahlilPage extends StatefulWidget {
  const TahlilPage({super.key});

  @override
  State<TahlilPage> createState() => _TahlilPageState();
}

class _TahlilPageState extends State<TahlilPage> {
  TahlilData? _tahlilData;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, int> _zikirCounters =
      {}; // Track zikir counts by section id

  // Navigation & TOC - using PageView for horizontal slide
  final PageController _pageController = PageController();
  final Map<String, GlobalKey> _sectionKeys = {};
  int _currentSectionIndex = 0;
  bool _showTOC = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await TahlilService.loadTahlilData();
      // Create keys for each section
      for (var section in data.sections) {
        _sectionKeys[section.id] = GlobalKey();
      }
      setState(() {
        _tahlilData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _scrollToSection(int index) {
    if (_tahlilData == null ||
        index < 0 ||
        index >= _tahlilData!.sections.length)
      return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );

    setState(() {
      _currentSectionIndex = index;
      _showTOC = false;
    });
  }

  void _navigateSection(bool next) {
    if (_tahlilData == null) return;

    final newIndex =
        next
            ? (_currentSectionIndex + 1) % _tahlilData!.sections.length
            : (_currentSectionIndex - 1 + _tahlilData!.sections.length) %
                _tahlilData!.sections.length;

    _scrollToSection(newIndex);
  }

  void _incrementZikir(String sectionId) {
    setState(() {
      _zikirCounters[sectionId] = (_zikirCounters[sectionId] ?? 0) + 1;
    });
  }

  void _resetZikir(String sectionId) {
    setState(() {
      _zikirCounters[sectionId] = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tahlil Ringkas',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_tahlilData != null) ...[
            IconButton(
              icon: Icon(_showTOC ? Icons.close : Icons.list_rounded),
              tooltip: 'Kandungan',
              onPressed: () {
                setState(() {
                  _showTOC = !_showTOC;
                });
              },
            ),
          ],
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat data',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _loadData();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Cuba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
              : Stack(
                children: [
                  _buildContent(),
                  if (_showTOC) _buildTOCOverlay(),
                  if (!_showTOC && _tahlilData != null)
                    _buildNavigationButtons(),
                ],
              ),
    );
  }

  Widget _buildContent() {
    if (_tahlilData == null) return const SizedBox();

    return PageView.builder(
      controller: _pageController,
      itemCount: _tahlilData!.sections.length,
      onPageChanged: (index) {
        setState(() {
          _currentSectionIndex = index;
        });
      },
      itemBuilder: (context, index) {
        final section = _tahlilData!.sections[index];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: _buildSectionCard(section, index),
        );
      },
    );
  }

  Widget _buildTOCOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showTOC = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00897B),
                          const Color(0xFF4DB6AC),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kandungan',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${_tahlilData!.sections.length} bahagian',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // List
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _tahlilData!.sections.length,
                      itemBuilder: (context, index) {
                        final section = _tahlilData!.sections[index];
                        final isActive = index == _currentSectionIndex;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _scrollToSection(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isActive
                                        ? colorScheme.primaryContainer
                                            .withOpacity(0.5)
                                        : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient:
                                          isActive
                                              ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF00897B),
                                                  Color(0xFF4DB6AC),
                                                ],
                                              )
                                              : null,
                                      color:
                                          isActive
                                              ? null
                                              : colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isActive
                                                  ? Colors.white
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          section.title,
                                          style: TextStyle(
                                            fontWeight:
                                                isActive
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                            color:
                                                isActive
                                                    ? colorScheme.primary
                                                    : colorScheme.onSurface,
                                            fontSize: screenWidth * 0.04,
                                          ),
                                        ),
                                        if (section.subtitle != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            section.subtitle!,
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.032,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isActive)
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildNavigationButtons() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00897B).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateSection(false),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sebelum',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withOpacity(0.3),
            ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateSection(true),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Seterusnya',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 18,
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
    );
  }

  Widget _buildSectionCard(TahlilSection section, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      key: _sectionKeys[section.id],
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, colorScheme.surfaceVariant.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00897B).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern gradient header - without numbering
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                          height: 1.3,
                        ),
                      ),
                      if (section.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          section.subtitle!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.036,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  section.contents
                      .map((content) => _buildContentItem(section, content))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentItem(TahlilSection section, TahlilContent content) {
    switch (content.type) {
      case ContentType.zikir:
        return _buildZikirContent(section, content);
      case ContentType.verse:
        return _buildVerseContent(content);
      case ContentType.simpleText:
        return _buildSimpleTextContent(content);
    }
  }

  Widget _buildSimpleTextContent(TahlilContent content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (content.arabic != null) ...[
            Text(
              content.arabic!,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                height: 2.0,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
          ],
          if (content.transliteration != null) ...[
            Text(
              content.transliteration!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
          ],
          if (content.translation != null) ...[
            Text(
              content.translation!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerseContent(TahlilContent content) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.verseNumber != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${content.verseNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (content.arabic != null) ...[
                  Text(
                    content.arabic!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      height: 2.0,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                ],
                if (content.transliteration != null) ...[
                  Text(
                    content.transliteration!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (content.translation != null) ...[
                  Text(
                    content.translation!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZikirContent(TahlilSection section, TahlilContent content) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = _zikirCounters[section.id] ?? 0;
    final target = content.targetCount ?? 0;
    final isComplete = count >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (content.arabic != null) ...[
          Text(
            content.arabic!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 2.0,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
        ],
        if (content.transliteration != null) ...[
          Text(
            content.transliteration!,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
        ],
        if (content.translation != null) ...[
          Text(
            content.translation!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],

        // Modern counter display with gradient
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isComplete
                      ? [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withOpacity(0.7),
                      ]
                      : [colorScheme.surfaceVariant, colorScheme.surface],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isComplete
                      ? colorScheme.primary.withOpacity(0.3)
                      : colorScheme.outline.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isComplete)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  Text(
                    '$count / $target',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isComplete
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: target > 0 ? count / target : 0,
                  backgroundColor: colorScheme.surface.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? colorScheme.primary : const Color(0xFF00897B),
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Modern counter buttons with gradient
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00897B).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _incrementZikir(section.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Tambah',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: count > 0 ? () => _resetZikir(section.id) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color:
                              count > 0
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reset',
                          style: TextStyle(
                            color:
                                count > 0
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withOpacity(0.3),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
        const SizedBox(height: 16),
      ],
    );
  }
}

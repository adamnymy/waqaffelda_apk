import 'package:flutter/material.dart';
import 'dart:ui';

class HadisDetailPage extends StatefulWidget {
  final Map<String, dynamic> hadis;
  final List<Color> colorSet;

  const HadisDetailPage({Key? key, required this.hadis, required this.colorSet})
    : super(key: key);

  @override
  State<HadisDetailPage> createState() => _HadisDetailPageState();
}

class _HadisDetailPageState extends State<HadisDetailPage> {
  double fontSize = 1.0; // Font size multiplier

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
          'Hadis ${widget.hadis['number']}',
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
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFBC02D), Color(0xFFFDD835)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _toArabicNumber(widget.hadis['number']),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Title Card with Narrator
          _buildTitleCard(),
          const SizedBox(height: 24),
          // Arabic Section
          _buildArabicSection(),
          const SizedBox(height: 24),
          // Translation Section
          _buildTranslationSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTitleCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00897B).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.hadis['title'],
            style: TextStyle(
              fontSize: 26 * fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          // Reference and Narrator
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 15,
                      color: const Color(0xFFFBC02D),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.hadis['reference'],
                        style: TextStyle(
                          fontSize: 13 * fontSize,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: const Color(0xFF00897B),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.hadis['narrator'],
                        style: TextStyle(
                          fontSize: 13 * fontSize,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildArabicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFBC02D), Color(0xFFFDD835)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFBC02D).withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.text_fields_rounded, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'TEKS ARAB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Arabic Text
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF9C4), Color(0xFFFFF59D)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFBC02D).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFBC02D).withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.hadis['arabic'],
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 24 * fontSize,
              height: 2.3,
              color: Colors.black87,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.translate_rounded, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'TERJEMAHAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Translation Text
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00897B).withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.hadis['translation'],
            style: TextStyle(
              fontSize: 16 * fontSize,
              color: Colors.grey[800],
              height: 1.9,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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

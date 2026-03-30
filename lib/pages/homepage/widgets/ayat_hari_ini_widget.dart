import 'package:flutter/material.dart';

class AyatHariIniWidget extends StatefulWidget {
  final PageController pageController;
  final int currentAyatIndex;
  final List<Map<String, String>> ayatList;
  final Function(int) onPageChanged;

  const AyatHariIniWidget({
    Key? key,
    required this.pageController,
    required this.currentAyatIndex,
    required this.ayatList,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  State<AyatHariIniWidget> createState() => _AyatHariIniWidgetState();
}

class _AyatHariIniWidgetState extends State<AyatHariIniWidget> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ayat Hari Ini',
                style: TextStyle(
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '${widget.currentAyatIndex + 1}/${widget.ayatList.length}',
                style: TextStyle(
                  fontSize: screenWidth * 0.028,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          SizedBox(
            height: screenHeight * 0.20,
            child: PageView.builder(
              controller: widget.pageController,
              onPageChanged: widget.onPageChanged,
              itemCount: widget.ayatList.length,
              itemBuilder: (context, index) {
                return _buildAyatCard(
                  context,
                  widget.ayatList[index]['ayat']!,
                  widget.ayatList[index]['source']!,
                  index,
                );
              },
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.ayatList.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: widget.currentAyatIndex == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      widget.currentAyatIndex == index
                          ? _getCardColors(index)['accent']
                          : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCardColors(int index) {
    switch (index) {
      case 0:
        return {
          'bg': const Color(0xFFFEF3C7),
          'accent': const Color(0xFFFCD34D),
          'text': const Color(0xFF78350F),
          'icon': const Color(0xFFD97706),
        };
      case 1:
        return {
          'bg': const Color(0xFFF3E8FF),
          'accent': const Color(0xFFE9D5FF),
          'text': const Color(0xFF4C1D95),
          'icon': const Color(0xFF9333EA),
        };
      case 2:
        return {
          'bg': const Color(0xFFA7F3D0),
          'accent': const Color(0xFF6EE7B7),
          'text': const Color(0xFF064E3B),
          'icon': const Color(0xFF10B981),
        };
      case 3:
        return {
          'bg': const Color(0xFFFFE4E6),
          'accent': const Color(0xFFFBCFCF),
          'text': const Color(0xFF831843),
          'icon': const Color(0xFFEC4899),
        };
      case 4:
        return {
          'bg': const Color(0xFFDCFCE7),
          'accent': const Color(0xFFBBF7D0),
          'text': const Color(0xFF15803D),
          'icon': const Color(0xFF22C55E),
        };
      default:
        return {
          'bg': const Color(0xFFFEF3C7),
          'accent': const Color(0xFFFCD34D),
          'text': const Color(0xFF78350F),
          'icon': const Color(0xFFD97706),
        };
    }
  }

  String _getDecorativeShapeType(int index, {required String position}) {
    final shapePatterns = [
      {
        'topRight': 'circle',
        'bottomLeft': 'square',
        'bottomRight': 'roundedRect',
      },
      {'topRight': 'square', 'bottomLeft': 'circle', 'bottomRight': 'diamond'},
      {
        'topRight': 'roundedRect',
        'bottomLeft': 'diamond',
        'bottomRight': 'circle',
      },
      {
        'topRight': 'diamond',
        'bottomLeft': 'roundedRect',
        'bottomRight': 'square',
      },
      {'topRight': 'circle', 'bottomLeft': 'diamond', 'bottomRight': 'square'},
    ];

    final pattern = shapePatterns[index % shapePatterns.length];
    return pattern[position]!;
  }

  Widget _buildDecorativeShape({
    required String shapeType,
    required Color color,
    required double size,
  }) {
    switch (shapeType) {
      case 'circle':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        );
      case 'square':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.zero,
          ),
        );
      case 'roundedRect':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
        );
      case 'diamond':
        return Transform.rotate(
          angle: 0.785, // 45 degrees
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.zero,
            ),
          ),
        );
      default:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        );
    }
  }

  Widget _buildAyatCard(
    BuildContext context,
    String ayatText,
    String source,
    int cardIndex,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final colors = _getCardColors(cardIndex);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: colors['accent'].withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background color
            Container(color: colors['bg']),
            // Decorative shape - top right
            Positioned(
              top: -20,
              right: -20,
              child: _buildDecorativeShape(
                shapeType: _getDecorativeShapeType(
                  cardIndex,
                  position: 'topRight',
                ),
                color: colors['accent'].withOpacity(0.25),
                size: 120,
              ),
            ),
            // Decorative shape - bottom left
            Positioned(
              bottom: -15,
              left: -15,
              child: _buildDecorativeShape(
                shapeType: _getDecorativeShapeType(
                  cardIndex,
                  position: 'bottomLeft',
                ),
                color: colors['accent'].withOpacity(0.20),
                size: 100,
              ),
            ),
            // Decorative shape - bottom right
            Positioned(
              bottom: -15,
              right: -15,
              child: _buildDecorativeShape(
                shapeType: _getDecorativeShapeType(
                  cardIndex,
                  position: 'bottomRight',
                ),
                color: colors['accent'].withOpacity(0.15),
                size: 90,
              ),
            ),
            // Content with padding
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quote icon
                  Icon(
                    Icons.format_quote_rounded,
                    color: colors['icon'].withOpacity(0.4),
                    size: screenWidth * 0.06,
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  // Ayat text - centered and italic
                  Expanded(
                    child: Center(
                      child: Text(
                        ayatText,
                        style: TextStyle(
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.w700,
                          color: colors['text'],
                          height: 1.5,
                          letterSpacing: 0.2,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  // Source badge at bottom
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.008,
                    ),
                    decoration: BoxDecoration(
                      color: colors['accent'].withOpacity(0.3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: colors['icon'],
                          size: screenWidth * 0.025,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          source,
                          style: TextStyle(
                            fontSize: screenWidth * 0.020,
                            fontWeight: FontWeight.w700,
                            color: colors['text'],
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                ' # Ayat Hari Ini',
                style: TextStyle(
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00897B).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${widget.currentAyatIndex + 1}/${widget.ayatList.length}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00897B),
                  ),
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
                          ? _getCardColors(index)['primary']
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

  Map<String, Color> _getCardColors(int index) {
    switch (index) {
      case 0:
        return {
          'primary': const Color(0xFFFBC02D),
          'gradient1': const Color(0xFFFDD835),
          'gradient2': const Color(0xFFFBC02D),
        };
      case 1:
        return {
          'primary': const Color(0xFF9C27B0),
          'gradient1': const Color(0xFFAB47BC),
          'gradient2': const Color(0xFF8E24AA),
        };
      case 2:
        return {
          'primary': const Color(0xFF00897B),
          'gradient1': const Color(0xFF00BCD4),
          'gradient2': const Color(0xFF00897B),
        };
      case 3:
        return {
          'primary': const Color(0xFFFF5722),
          'gradient1': const Color(0xFFFF6F00),
          'gradient2': const Color(0xFFFF5722),
        };
      case 4:
        return {
          'primary': const Color(0xFF2196F3),
          'gradient1': const Color(0xFF42A5F5),
          'gradient2': const Color(0xFF1976D2),
        };
      default:
        return {
          'primary': const Color(0xFFFBC02D),
          'gradient1': const Color(0xFFFDD835),
          'gradient2': const Color(0xFFFBC02D),
        };
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
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors['gradient1']!, colors['gradient2']!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors['primary']!.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.format_quote_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.05,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: Text(
                  ayatText,
                  style: TextStyle(
                    fontSize: screenWidth * 0.033,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: const Offset(0, 1.5),
                        blurRadius: 3,
                      ),
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Container(
            height: 1.5,
            width: screenWidth * 0.15,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: screenHeight * 0.008),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.028,
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  source,
                  style: TextStyle(
                    fontSize: screenWidth * 0.026,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

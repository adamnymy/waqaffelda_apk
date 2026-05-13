import 'package:flutter/material.dart';

class AyatHariIniWidget extends StatefulWidget {
  final PageController pageController;
  final int currentAyatIndex;
  final List<Map<String, String>> ayatList;
  final Function(int) onPageChanged;

  const AyatHariIniWidget({
    super.key,
    required this.pageController,
    required this.currentAyatIndex,
    required this.ayatList,
    required this.onPageChanged,
  });

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
                  color: const Color(0xFF1A1A2E),
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC49B28).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${widget.currentAyatIndex + 1}/${widget.ayatList.length}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC49B28),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          SizedBox(
            height: screenHeight * 0.22,
            child: PageView.builder(
              controller: widget.pageController,
              onPageChanged: widget.onPageChanged,
              itemCount: widget.ayatList.length,
              itemBuilder: (context, index) {
                return _buildAyatCard(
                  context,
                  widget.ayatList[index]['ayat']!,
                  widget.ayatList[index]['source']!,
                );
              },
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.ayatList.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: widget.currentAyatIndex == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.currentAyatIndex == index
                      ? const Color(0xFFC49B28)
                      : const Color(0xFFE8DCC8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyatCard(BuildContext context, String ayatText, String source) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
      padding: EdgeInsets.all(screenWidth * 0.045),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC49B28).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC49B28).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: const Color(0xFFC49B28).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.format_quote_rounded,
                  color: const Color(0xFFC49B28),
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: Text(
                  ayatText,
                  style: TextStyle(
                    fontSize: screenWidth * 0.034,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A2E1A),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.012),
          Container(
            height: 1,
            width: screenWidth * 0.15,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFC49B28).withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.008),
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: const Color(0xFFC49B28),
                size: screenWidth * 0.03,
              ),
              SizedBox(width: screenWidth * 0.01),
              Text(
                source,
                style: TextStyle(
                  fontSize: screenWidth * 0.028,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC49B28),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

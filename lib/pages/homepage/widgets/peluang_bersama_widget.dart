import 'package:flutter/material.dart';
import '../../../utils/page_transitions.dart';
import '../../program/program_page.dart';

class PeluangBersamaWidget extends StatelessWidget {
  const PeluangBersamaWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> peluangItems = [
      {
        'image': 'assets/images/KP5R3.png',
        'badge': 'TERKINI',
        'badgeColor': const Color(0xFFFF5252),
        'showBadge': true,
      },
      {
        'image': 'assets/images/IST2.png',
        'badge': 'BARU',
        'badgeColor': const Color(0xFF4CAF50),
        'showBadge': false,
      },
      {
        'image': 'assets/images/WQT1.png',
        'badge': 'BARU',
        'badgeColor': const Color(0xFFF9A825),
        'showBadge': false,
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peluang Bersama',
                      style: TextStyle(
                        fontSize: screenWidth * 0.048,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.003),
                    Text(
                      'Jangan lepaskan peluang ini',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                const ProgramPage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Lagi',
                        style: TextStyle(
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w700,
                          fontSize: screenWidth * 0.035,
                          letterSpacing: 0.3,
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF9CA3AF),
                          decorationThickness: 1.5,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.015),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: const Color(0xFF9CA3AF),
                        size: screenWidth * 0.035,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          SizedBox(
            height: screenHeight * 0.20,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: peluangItems.length,
              itemBuilder: (context, index) {
                return _buildCard(
                  context,
                  peluangItems[index]['image'],
                  peluangItems[index]['badge'],
                  peluangItems[index]['badgeColor'],
                  peluangItems[index]['showBadge'],
                  screenWidth,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String imagePath,
    String badge,
    Color badgeColor,
    bool showBadge,
    double screenWidth,
  ) {
    return Container(
      width: screenWidth * 0.7,
      margin: EdgeInsets.only(right: screenWidth * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF00897B).withOpacity(0.3),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: screenWidth * 0.12,
                    ),
                  ),
                );
              },
            ),
            if (showBadge)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.028,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

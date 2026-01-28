import 'package:flutter/material.dart';
import '../../../utils/page_transitions.dart';
import '../../program/program_page.dart';

class AgihanManfaatWidget extends StatelessWidget {
  const AgihanManfaatWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> programItems = [
      {
        'image': 'assets/images/Manfaat/AgihanManfaat1.png',
        'badge': 'POPULAR',
        'badgeColor': const Color(0xFFFF9800),
        'showBadge': false,
      },
      {
        'image': 'assets/images/Manfaat/AgihanManfaat2.png',
        'badge': 'BARU',
        'badgeColor': const Color(0xFF2196F3),
        'showBadge': false,
      },
      {
        'image': 'assets/images/Manfaat/AgihanManfaat3.png',
        'badge': 'BARU',
        'badgeColor': const Color(0xFF9C27B0),
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
                      'Agihan Manfaat',
                      style: TextStyle(
                        fontSize: screenWidth * 0.048,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.003),
                    Text(
                      'Rasai manfaatnya bersama kami',
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
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF00897B).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Material(
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
                    borderRadius: BorderRadius.circular(25),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Lagi',
                            style: TextStyle(
                              color: const Color(0xFF00897B),
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.035,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFF00897B),
                            size: screenWidth * 0.035,
                          ),
                        ],
                      ),
                    ),
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
              itemCount: programItems.length,
              itemBuilder: (context, index) {
                return _buildCard(
                  context,
                  programItems[index]['image'],
                  programItems[index]['badge'],
                  programItems[index]['badgeColor'],
                  programItems[index]['showBadge'],
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
                  color: const Color(0xFFF9A825).withOpacity(0.3),
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

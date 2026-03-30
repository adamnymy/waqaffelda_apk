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
        'title': 'Agihan Manfaat Bulan Ramadan',
        'description': 'Agihan Manfaat Gelandangan di sekitar Kuala Lumpur',
        'badge': 'POPULAR',
        'badgeColor': const Color(0xFFFF9800),
        'showBadge': false,
      },
      {
        'image': 'assets/images/Manfaat/AgihanManfaat2.png',
        'title': 'Ziarah Kasih',
        'description': 'Program Ziarah Kasih bersama Warga peneroka FELDA',
        'badge': 'BARU',
        'badgeColor': const Color(0xFF2196F3),
        'showBadge': false,
      },
      {
        'image': 'assets/images/Manfaat/AgihanManfaat3.png',
        'title': 'Program Anak Kanser Kidz',
        'description': '',
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
          Column(
            children: [
              for (int i = 0; i < programItems.length; i++) ...[
                _buildCard(
                  context,
                  programItems[i]['image'],
                  programItems[i]['title'],
                  programItems[i]['description'],
                  programItems[i]['badge'],
                  programItems[i]['badgeColor'],
                  programItems[i]['showBadge'],
                  screenWidth,
                ),
                if (i < programItems.length - 1)
                  SizedBox(height: screenWidth * 0.08),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String imagePath,
    String title,
    String description,
    String badge,
    Color badgeColor,
    bool showBadge,
    double screenWidth,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Image dimensions: 16:9 aspect ratio
    final imageWidth = screenWidth * 0.45;
    final imageHeight = imageWidth * 9 / 16;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Image on the left (16:9 aspect ratio)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: imageWidth,
                height: imageHeight,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: imageWidth,
                    height: imageHeight,
                    color: const Color(0xFFF9A825).withOpacity(0.2),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: screenWidth * 0.06,
                      ),
                    ),
                  );
                },
              ),
              if (showBadge)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.022,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        // Text content on the right
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.clip,
              ),
              SizedBox(height: screenHeight * 0.006),
              Text(
                description,
                style: TextStyle(
                  fontSize: screenWidth * 0.026,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.1,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

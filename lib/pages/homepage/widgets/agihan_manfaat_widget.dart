import 'package:flutter/material.dart';
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
        'title': 'Ziarah Kasih',
        'description': 'Program Ziarah Kasih bersama Warga peneroka FELDA',
      },
      {
        'image': 'assets/images/Manfaat/AgihanManfaat2.png',
        'title': 'Ziarah Kasih',
        'description': 'Program Ziarah Kasih bersama Warga peneroka FELDA',
      },
      {
        'image': 'assets/images/Manfaat/AgihanManfaat3.png',
        'title': 'Ziarah Kasih',
        'description': 'Program Ziarah Kasih bersama Warga peneroka FELDA',
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
              Text(
                'Agihan Manfaat',
                style: TextStyle(
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A2E),
                  letterSpacing: 0.3,
                ),
              ),
              GestureDetector(
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
                child: Text(
                  'Lihat Lagi',
                  style: TextStyle(
                    color: const Color(0xFFC49B28),
                    fontWeight: FontWeight.w700,
                    fontSize: screenWidth * 0.035,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Column(
            children: programItems
                .map((item) => _buildListItem(
                      context,
                      item['image'] as String,
                      item['title'] as String,
                      item['description'] as String,
                      screenWidth,
                      screenHeight,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    String imagePath,
    String title,
    String description,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.012),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: screenWidth * 0.28,
              height: screenWidth * 0.2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: screenWidth * 0.28,
                  height: screenWidth * 0.2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9A825).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.image_not_supported,
                    color: const Color(0xFFC49B28),
                    size: screenWidth * 0.08,
                  ),
                );
              },
            ),
          ),
          SizedBox(width: screenWidth * 0.035),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.036,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: screenHeight * 0.004),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

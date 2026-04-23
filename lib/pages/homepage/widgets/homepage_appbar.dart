import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../searchpage/search_page.dart';
import 'notifications_page.dart';

class HomepageAppBar extends StatelessWidget {
  final String locationName;

  const HomepageAppBar({Key? key, required this.locationName})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Build date string
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mac',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ogos',
      'Sep',
      'Okt',
      'Nov',
      'Dis',
    ];
    final currentDate = '${now.day} ${months[now.month - 1]} ${now.year}';

    const hijriMonths = [
      'Muharram',
      'Safar',
      "Rabi'ul Awal",
      "Rabi'ul Akhir",
      'Jamadil Awal',
      'Jamadil Akhir',
      'Rejab',
      "Sha'ban",
      'Ramadan',
      'Syawal',
      'Zulkaedah',
      'Zulhijjah',
    ];
    final hijri = HijriCalendar.fromDate(now);
    final hijriDate =
        '${hijri.hDay} ${hijriMonths[hijri.hMonth - 1]} ${hijri.hYear}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.015,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Location + Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: screenWidth * 0.04,
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Flexible(
                      child: Text(
                        locationName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.048,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.003),
                Text(
                  '$currentDate / $hijriDate',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: screenWidth * 0.026,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Buttons
          Row(
            children: [
              _buildIconButton(
                context,
                Icons.notifications_outlined,
                screenWidth,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              _buildIconButton(
                context,
                Icons.search_rounded,
                screenWidth,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    double screenWidth,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.022),
            child: Icon(icon, color: Colors.white, size: screenWidth * 0.052),
          ),
        ),
      ),
    );
  }
}

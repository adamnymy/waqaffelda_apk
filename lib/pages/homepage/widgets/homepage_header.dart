import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

class HomepageHeader extends StatelessWidget {
  final String currentLocationName;
  final String nextPrayerText;
  final Duration countdown;
  final VoidCallback onNotificationPressed;
  final List<Map<String, dynamic>> prayerTimes;
  final bool isLoading;

  const HomepageHeader({
    Key? key,
    required this.currentLocationName,
    required this.nextPrayerText,
    required this.countdown,
    required this.onNotificationPressed,
    required this.prayerTimes,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get current date (Gregorian)
    final now = DateTime.now();
    final months = [
      'Januari',
      'Februari',
      'Mac',
      'April',
      'Mei',
      'Jun',
      'Julai',
      'Ogos',
      'September',
      'Oktober',
      'November',
      'Disember',
    ];
    final currentDate = '${now.day} ${months[now.month - 1]} ${now.year}';

    // Get Hijri date
    const hijriMonths = [
      'Muharram',
      'Safar',
      "Rabi'ulawal",
      "Rabi'ulakhir",
      'Jamadilawwal',
      'Jamadilakhir',
      'Rejab',
      "Sha'ban",
      'Ramadan',
      'Shawwal',
      'Zulkaedah',
      'Zulhijjah',
    ];
    final hijriCalendar = HijriCalendar.fromDate(now);
    final hijriMonthName = hijriMonths[hijriCalendar.hMonth - 1];
    final hijriDate =
        '${hijriCalendar.hDay} $hijriMonthName ${hijriCalendar.hYear}';

    // Parse prayer info
    String nextPrayerName = '';
    String nextPrayerTime = '';
    if (nextPrayerText.contains(':') &&
        nextPrayerText != 'Loading...' &&
        nextPrayerText != 'Tidak dapat memuatkan waktu solat') {
      final cleaned = nextPrayerText.replaceAll('Solat Seterusnya: ', '');
      final parts = cleaned.split(' - ');
      if (parts.length == 2) {
        nextPrayerName = parts[0].trim();
        nextPrayerTime = parts[1].trim();
      }
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          // Content on top
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.016,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Location and Notification button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Location and Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoading)
                          Container(
                            width: screenWidth * 0.3,
                            height: screenWidth * 0.045,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        else
                          Text(
                            currentLocationName,
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              letterSpacing: 0.2,
                            ),
                          ),
                        SizedBox(height: screenHeight * 0.006),
                        if (isLoading)
                          Container(
                            width: screenWidth * 0.4,
                            height: screenWidth * 0.026,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        else
                          Text(
                            '$currentDate / $hijriDate',
                            style: TextStyle(
                              fontSize: screenWidth * 0.026,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                              letterSpacing: 0.1,
                            ),
                          ),
                      ],
                    ),
                    // Right side: Circular notification button
                    Container(
                      width: screenWidth * 0.12,
                      height: screenWidth * 0.12,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onNotificationPressed,
                          customBorder: const CircleBorder(),
                          child: Icon(
                            Icons.notifications_rounded,
                            size: screenWidth * 0.055,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.05),
                // Prayer time display - Time only
                if (isLoading)
                  Center(
                    child: Container(
                      width: screenWidth * 0.4,
                      height: screenWidth * 0.12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else if (nextPrayerName.isNotEmpty && nextPrayerTime.isNotEmpty)
                  Center(
                    child: Text(
                      nextPrayerTime,
                      style: TextStyle(
                        fontSize: screenWidth * 0.12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 0.2,
                        height: 1.0,
                      ),
                    ),
                  )
                else
                  Center(
                    child: Text(
                      '--:--',
                      style: TextStyle(
                        fontSize: screenWidth * 0.12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[500],
                        letterSpacing: 0.2,
                        height: 1.0,
                      ),
                    ),
                  ),
                SizedBox(height: screenHeight * 0.04),
                // Countdown display
                if (isLoading)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: screenWidth * 0.6,
                          height: screenWidth * 0.032,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Container(
                          width: screenWidth * 0.5,
                          height: screenWidth * 0.032,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (nextPrayerName.isNotEmpty && countdown.inSeconds > 0)
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${nextPrayerName[0].toUpperCase()}${nextPrayerName.substring(1).toLowerCase()}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.032,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: 0.2,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' ${countdown.inHours} jam ${countdown.inMinutes % 60} minit ${countdown.inSeconds % 60} saat lagi',
                            style: TextStyle(
                              fontSize: screenWidth * 0.032,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Center(
                    child: Text(
                      'Memuat waktu solat...',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                SizedBox(height: screenHeight * 0.06),
                // Prayer times grid
                if (isLoading)
                  _buildPrayerTimesSkeletonLoader(
                    context,
                    screenWidth,
                    screenHeight,
                  )
                else if (prayerTimes.isNotEmpty)
                  _buildPrayerTimesGrid(context, screenWidth, screenHeight)
                else
                  Center(
                    child: Text(
                      'Waktu solat tidak tersedia',
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesSkeletonLoader(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Column(
      children: [
        // Top row - 4 skeleton items
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: screenWidth * 0.035,
            runSpacing: screenHeight * 0.01,
            children: List.generate(
              4,
              (index) => _buildSkeletonPrayerCard(screenWidth),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        // Bottom row - 2 skeleton items
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: screenWidth * 0.035,
            runSpacing: screenHeight * 0.01,
            children: List.generate(
              2,
              (index) => _buildSkeletonPrayerCard(screenWidth),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonPrayerCard(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.008),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Skeleton icon
          Container(
            width: screenWidth * 0.08,
            height: screenWidth * 0.08,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          // Skeleton time
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.038,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          // Skeleton name
          Container(
            width: screenWidth * 0.1,
            height: screenWidth * 0.032,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesGrid(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: screenWidth * 0.01,
      runSpacing: screenHeight * 0.01,
      children:
          prayerTimes.map((prayer) {
            final name = prayer['name'] ?? '';
            final time = prayer['time'] ?? '';
            final isPassed = prayer['isPassed'] ?? false;

            return _buildPrayerTimeCard(
              name: name,
              time: time,
              isPassed: isPassed,
              screenWidth: screenWidth,
            );
          }).toList(),
    );
  }

  Widget _buildPrayerTimeCard({
    required String name,
    required String time,
    required bool isPassed,
    required double screenWidth,
  }) {
    IconData iconData = _getPrayerIcon(name);
    Color iconColor = _getPrayerColor(name);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.045),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: screenWidth * 0.055,
            color: isPassed ? Colors.grey.withOpacity(0.5) : iconColor,
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            time,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w700,
              color: isPassed ? Colors.grey[400] : Colors.black87,
            ),
          ),
          SizedBox(height: screenWidth * 0.008),
          Text(
            name,
            style: TextStyle(
              fontSize: screenWidth * 0.024,
              fontWeight: FontWeight.w500,
              color: isPassed ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        return Icons.brightness_3_rounded; // Early morning pre-dawn darkness
      case 'syuruk':
        return Icons.flare_rounded; // Sunrise burst of light
      case 'zohor':
        return Icons.wb_sunny_rounded; // Bright midday sun
      case 'asar':
        return Icons.wb_cloudy_rounded; // Afternoon shade/shadows
      case 'maghrib':
        return Icons.wb_twilight_rounded; // Sunset/twilight
      case 'isyak':
        return Icons.nights_stay_rounded; // Night time
      default:
        return Icons.access_time_rounded;
    }
  }

  Color _getPrayerColor(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        return const Color(0xFF4F46E5); // Indigo
      case 'syuruk':
        return const Color(0xFFF59E0B); // Amber
      case 'zohor':
        return const Color(0xFFF59E0B); // Amber
      case 'asar':
        return const Color(0xFF8B5CF6); // Violet
      case 'maghrib':
        return const Color(0xFFEC4899); // Pink
      case 'isyak':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

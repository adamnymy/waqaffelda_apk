import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

class HomepageHeader extends StatelessWidget {
  final String currentLocationName;
  final String nextPrayerText;
  final Duration countdown;
  final VoidCallback onNotificationPressed;

  const HomepageHeader({
    Key? key,
    required this.currentLocationName,
    required this.nextPrayerText,
    required this.countdown,
    required this.onNotificationPressed,
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

    return Padding(
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
                  Text(
                    '$currentDate / $hijriDate',
                    style: TextStyle(
                      fontSize: screenWidth * 0.026,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
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
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.016),
          // Prayer time display - Time only
          if (nextPrayerName.isNotEmpty && nextPrayerTime.isNotEmpty)
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
                  color: Colors.grey,
                  letterSpacing: 0.2,
                  height: 1.0,
                ),
              ),
            ),
          SizedBox(height: screenHeight * 0.018),
          // Countdown display
          if (nextPrayerName.isNotEmpty && countdown.inSeconds > 0)
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${nextPrayerName[0].toUpperCase()}${nextPrayerName.substring(1).toLowerCase()}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withOpacity(0.7),
                        letterSpacing: 0.2,
                      ),
                    ),
                    TextSpan(
                      text: ' ${countdown.inHours} jam ${countdown.inMinutes % 60} minit ${countdown.inSeconds % 60} saat lagi',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.7),
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
                  color: Colors.grey,
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

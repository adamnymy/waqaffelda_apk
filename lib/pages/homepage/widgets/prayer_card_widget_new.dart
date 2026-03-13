import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

class PrayerCardWidget extends StatelessWidget {
  final String nextPrayerText;
  final Duration countdown;
  final String currentLocationName;
  final Function(Duration) formatDuration;

  const PrayerCardWidget({
    Key? key,
    required this.nextPrayerText,
    required this.countdown,
    required this.currentLocationName,
    required this.formatDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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

    // Skeleton loading
    if (nextPrayerText == 'Loading...' || nextPrayerText.isEmpty) {
      return Container(
        height: screenHeight * 0.32,
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.01,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD4A574),
              Color(0xFFE8C394),
              Color(0xFFF5E6D3),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB8860B)),
          ),
        ),
      );
    }

    // Format countdown text
    String countdownText = '';
    if (countdown.inSeconds > 0) {
      final hours = countdown.inHours;
      final minutes = countdown.inMinutes % 60;
      final seconds = countdown.inSeconds % 60;
      countdownText =
          '$nextPrayerName $hours jam $minutes minit $seconds saat lagi';
    }

    // Actual prayer card
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD4A574),
            Color(0xFFE8C394),
            Color(0xFFF5E6D3),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A574).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.018,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Location and Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.wb_cloudy_rounded,
                    size: screenWidth * 0.08,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.018),

              // Large Time Display
              Text(
                nextPrayerTime,
                style: TextStyle(
                  fontSize: screenWidth * 0.18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1.0,
                ),
              ),
              SizedBox(height: screenHeight * 0.008),

              // Countdown Text
              Text(
                countdownText,
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.75),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

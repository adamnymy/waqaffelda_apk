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
      return _buildSkeletonLoading(context);
    }

    // ✅ Clean content layout - no card background
    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth * 0.01,
        right: screenWidth * 0.01,
        top: screenHeight * 0.015, // ✅ Tambah padding top untuk turunkan content
        bottom: screenHeight * 0.005,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date row
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 11,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 5),
              Text(
                '$currentDate / $hijriDate',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: screenWidth * 0.026,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.012),
          
          // Main content - Prayer name with icon
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SOLAT SETERUSNYA',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: screenWidth * 0.025,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    nextPrayerName.isNotEmpty
                        ? nextPrayerName.toUpperCase()
                        : 'MEMUAT...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.052,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.015),
          
          // Bottom row - WAKTU and BAKI MASA
          Row(
            children: [
              // WAKTU
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'WAKTU',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: screenWidth * 0.024,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        nextPrayerTime.isNotEmpty ? nextPrayerTime : '--:--',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // BAKI MASA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BAKI MASA',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: screenWidth * 0.024,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFD4A84B).withOpacity(0.45),
                            const Color(0xFFE8C55B).withOpacity(0.35),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE8C55B).withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        countdown.inSeconds > 0
                            ? formatDuration(countdown)
                            : '--:--:--',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.01),
          
          // Location row - centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 12,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  currentLocationName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: screenWidth * 0.025,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth * 0.01,
        right: screenWidth * 0.01,
        top: screenHeight * 0.015,
        bottom: screenHeight * 0.005,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date skeleton
          Container(
            width: screenWidth * 0.5,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          
          // Main content skeleton
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: screenWidth * 0.28,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: screenWidth * 0.2,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.015),
          
          // Bottom row skeleton
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 55,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.01),
          
          // Location skeleton
          Center(
            child: Container(
              width: screenWidth * 0.35,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
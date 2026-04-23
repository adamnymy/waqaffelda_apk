import 'package:flutter/material.dart';

class PrayerCardWidget extends StatelessWidget {
  final String nextPrayerText;
  final Duration countdown;
  final String currentLocationName;
  final Function(Duration) formatDuration;

  const PrayerCardWidget({
    super.key,
    required this.nextPrayerText,
    required this.countdown,
    required this.currentLocationName,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Parse prayer name and time
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

    // Countdown in natural Malay language
    String countdownText = '';
    if (countdown.inSeconds > 0) {
      final h = countdown.inHours;
      final m = countdown.inMinutes.remainder(60);
      final s = countdown.inSeconds.remainder(60);
      if (h > 0) {
        countdownText = '$h jam $m minit $s saat lagi';
      } else if (m > 0) {
        countdownText = '$m minit $s saat lagi';
      } else {
        countdownText = '$s saat lagi';
      }
    }

    // Loading state
    if (nextPrayerText == 'Loading...' || nextPrayerText.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          children: [
            Container(
              height: screenWidth * 0.18,
              width: screenWidth * 0.55,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(height: screenHeight * 0.012),
            Container(
              height: screenWidth * 0.04,
              width: screenWidth * 0.65,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.015,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          // Large prayer time
          Text(
            nextPrayerTime.isNotEmpty ? nextPrayerTime : '--:--',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.085,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 1.0,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 3),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.008),
          // Prayer name + countdown
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: nextPrayerName.isNotEmpty
                      ? '$nextPrayerName  '
                      : 'Memuat...  ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                TextSpan(
                  text: countdownText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: screenWidth * 0.034,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

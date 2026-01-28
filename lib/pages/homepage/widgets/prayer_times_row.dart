import 'package:flutter/material.dart';
import '../../../services/prayer_times_service.dart';

class PrayerTimesRow extends StatelessWidget {
  final List<Map<String, dynamic>> prayerTimes;
  final Function(String) getPrayerColor;
  final Function(String) getPrayerIcon;
  final Function(Map<String, dynamic>) isPrayerPassed;

  const PrayerTimesRow({
    Key? key,
    required this.prayerTimes,
    required this.getPrayerColor,
    required this.getPrayerIcon,
    required this.isPrayerPassed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (prayerTimes.isEmpty) {
      return _buildSkeletonLoading(context, screenWidth, screenHeight);
    }

    final nextPrayer = PrayerTimesService.getNextPrayer(prayerTimes);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.012,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: screenWidth * 0.038,
                  color: const Color(0xFF00897B),
                ),
                SizedBox(width: screenWidth * 0.015),
                Text(
                  'Waktu Solat Hari Ini',
                  style: TextStyle(
                    fontSize: screenWidth * 0.034,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.015,
              vertical: screenHeight * 0.014,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  prayerTimes.map((prayer) {
                    final bool isNextPrayer =
                        nextPrayer != null &&
                        nextPrayer['name'] == prayer['name'];
                    final bool isPassed = isPrayerPassed(prayer);

                    return _buildCompactPrayerItem(
                      prayer['name'] ?? '',
                      prayer['time'] ?? '--:--',
                      getPrayerIcon(prayer['name'] ?? '') as IconData,
                      getPrayerColor(prayer['name'] ?? '') as Color,
                      isNextPrayer,
                      isPassed,
                      screenWidth,
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPrayerItem(
    String name,
    String time,
    IconData icon,
    Color prayerColor,
    bool isNext,
    bool isPassed,
    double screenWidth,
  ) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.008),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: screenWidth * 0.11,
              height: screenWidth * 0.11,
              decoration: BoxDecoration(
                color:
                    isNext
                        ? prayerColor
                        : isPassed
                        ? Colors.grey.shade200
                        : prayerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    isNext ? Border.all(color: prayerColor, width: 2) : null,
              ),
              child: Icon(
                icon,
                color:
                    isNext
                        ? Colors.white
                        : isPassed
                        ? Colors.grey.shade400
                        : prayerColor,
                size: screenWidth * 0.048,
              ),
            ),
            SizedBox(height: screenWidth * 0.012),
            Text(
              name,
              style: TextStyle(
                fontSize: screenWidth * 0.028,
                fontWeight: isNext ? FontWeight.w900 : FontWeight.w600,
                color:
                    isNext
                        ? prayerColor
                        : isPassed
                        ? Colors.grey.shade500
                        : Colors.black87,
                letterSpacing: 0.1,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: screenWidth * 0.006),
            Text(
              time,
              style: TextStyle(
                fontSize: screenWidth * 0.026,
                fontWeight: FontWeight.w500,
                color:
                    isNext
                        ? prayerColor
                        : isPassed
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            if (isNext) ...[
              SizedBox(height: screenWidth * 0.008),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.016,
                  vertical: screenWidth * 0.004,
                ),
                decoration: BoxDecoration(
                  color: prayerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'NEXT',
                  style: TextStyle(
                    fontSize: screenWidth * 0.018,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      height: screenHeight * 0.15,
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenHeight * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            height: 16,
            width: screenWidth * 0.3,
            margin: EdgeInsets.only(bottom: screenHeight * 0.01),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.005,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: screenHeight * 0.06,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: screenWidth * 0.12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

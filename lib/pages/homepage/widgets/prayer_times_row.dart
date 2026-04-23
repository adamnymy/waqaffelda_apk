import 'package:flutter/material.dart';
import '../../../services/prayer_times_service.dart';

class PrayerTimesRow extends StatelessWidget {
  final List<Map<String, dynamic>> prayerTimes;
  final Function(String) getPrayerColor;
  final Function(String) getPrayerIcon;
  final Function(Map<String, dynamic>) isPrayerPassed;

  const PrayerTimesRow({
    super.key,
    required this.prayerTimes,
    required this.getPrayerColor,
    required this.getPrayerIcon,
    required this.isPrayerPassed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (prayerTimes.isEmpty) {
      return _buildSkeleton(screenWidth, screenHeight);
    }

    final nextPrayer = PrayerTimesService.getNextPrayer(prayerTimes);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.005,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: prayerTimes.map((prayer) {
          final bool isNext =
              nextPrayer != null && nextPrayer['name'] == prayer['name'];
          final bool isPassed = isPrayerPassed(prayer);

          return _buildItem(
            prayer['name'] ?? '',
            prayer['time'] ?? '--:--',
            getPrayerIcon(prayer['name'] ?? '') as IconData,
            isNext,
            isPassed,
            screenWidth,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItem(
    String name,
    String time,
    IconData icon,
    bool isNext,
    bool isPassed,
    double screenWidth,
  ) {
    final double vertPad = screenWidth * 0.022;
    final double horizPad = screenWidth * 0.006;

    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isNext
              ? Colors.white
              : isPassed
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.85),
          size: screenWidth * 0.05,
        ),
        SizedBox(height: screenWidth * 0.01),
        Text(
          name,
          style: TextStyle(
            fontSize: screenWidth * 0.027,
            fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
            color: isNext
                ? Colors.white
                : isPassed
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.9),
            height: 1.1,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: screenWidth * 0.004),
        Text(
          time,
          style: TextStyle(
            fontSize: screenWidth * 0.026,
            fontWeight: FontWeight.w600,
            color: isNext
                ? Colors.white
                : isPassed
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    return Expanded(
      child: isNext
          ? Container(
              padding: EdgeInsets.symmetric(
                vertical: vertPad,
                horizontal: horizPad,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: column,
            )
          : Padding(
              padding: EdgeInsets.symmetric(
                vertical: vertPad,
                horizontal: horizPad,
              ),
              child: column,
            ),
    );
  }

  Widget _buildSkeleton(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.005,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (_) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.07,
                    height: screenWidth * 0.07,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 8,
                    width: screenWidth * 0.09,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../services/prayer_times_service.dart';

class PrayerTimesRowNew extends StatelessWidget {
  final List<Map<String, dynamic>> prayerTimes;
  final Function(String) getPrayerColor;
  final Function(String) getPrayerIcon;
  final Function(Map<String, dynamic>) isPrayerPassed;

  const PrayerTimesRowNew({
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
      return SizedBox(
        height: screenHeight * 0.12,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final nextPrayer = PrayerTimesService.getNextPrayer(prayerTimes);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.008,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.02),
            child: Text(
              'Waktu Solat',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          SizedBox(
            height: screenHeight * 0.08,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: prayerTimes.length,
              separatorBuilder: (_, __) => SizedBox(width: screenWidth * 0.015),
              itemBuilder: (context, index) {
                final prayer = prayerTimes[index];
                final bool isNextPrayer = nextPrayer != null &&
                    nextPrayer['name'] == prayer['name'];
                final bool isPassed = isPrayerPassed(prayer);

                return _buildPrayerTimeCard(
                  context,
                  prayer['name'] ?? '',
                  prayer['time'] ?? '',
                  isNextPrayer,
                  isPassed,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeCard(
    BuildContext context,
    String prayerName,
    String prayerTime,
    bool isNextPrayer,
    bool isPassed,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.18,
      decoration: BoxDecoration(
        color: isNextPrayer
            ? const Color(0xFF00897B)
            : isPassed
                ? Colors.grey.withOpacity(0.15)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            prayerName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.024,
              fontWeight: FontWeight.w600,
              color: isNextPrayer
                  ? Colors.white
                  : isPassed
                      ? Colors.grey
                      : Colors.black87,
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: screenWidth * 0.01),
          Text(
            prayerTime,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.026,
              fontWeight: FontWeight.w700,
              color: isNextPrayer
                  ? Colors.white
                  : isPassed
                      ? Colors.grey
                      : Colors.black87,
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

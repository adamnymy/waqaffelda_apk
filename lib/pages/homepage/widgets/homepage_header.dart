import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:hijri/hijri_calendar.dart';
import '../../../utils/hijri_utils.dart';

// ═════════════════════════════════════════════════════════════════════════════
// HOMEPAGE HEADER
// ═════════════════════════════════════════════════════════════════════════════

// Single source of truth for the header colour
const _kHeaderColor = Color(0xFF0F766E);

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

    // ── Gregorian date ────────────────────────────────────────────────────────
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

    // ── Hijri date ────────────────────────────────────────────────────────────
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
    final hijriCalendar = getMalaysiaHijriCalendar(now);
    final hijriMonthName = hijriMonths[hijriCalendar.hMonth - 1];
    final hijriDate =
        '${hijriCalendar.hDay} $hijriMonthName ${hijriCalendar.hYear}';

    // ── Parse next prayer ─────────────────────────────────────────────────────
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

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        width: double.infinity,
        color: _kHeaderColor,
        child: Stack(
          children: [
            // ── Mosque silhouette — bottom of header ──────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: screenHeight * 0.28,
              child: Opacity(
                opacity: 0.15,
                child: SvgPicture.asset(
                  'assets/icons/menu/mosque_silhouette.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // ── All header content ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.05,
                screenHeight * 0.045,
                screenWidth * 0.05,
                screenHeight * 0.016,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: location + notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLoading)
                            _skeleton(screenWidth * 0.3, screenWidth * 0.045)
                          else
                            Text(
                              currentLocationName,
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          SizedBox(height: screenHeight * 0.006),
                          if (isLoading)
                            _skeleton(screenWidth * 0.4, screenWidth * 0.026)
                          else
                            Text(
                              '$currentDate / $hijriDate',
                              style: TextStyle(
                                fontSize: screenWidth * 0.026,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                                letterSpacing: 0.1,
                              ),
                            ),
                        ],
                      ),
                      Container(
                        width: screenWidth * 0.12,
                        height: screenWidth * 0.12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
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
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // Next prayer time — large
                  if (isLoading)
                    Center(
                      child: _skeleton(
                        screenWidth * 0.4,
                        screenWidth * 0.12,
                        radius: 8,
                      ),
                    )
                  else if (nextPrayerName.isNotEmpty &&
                      nextPrayerTime.isNotEmpty)
                    Center(
                      child: Text(
                        nextPrayerTime,
                        style: TextStyle(
                          fontSize: screenWidth * 0.12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
                          color: Colors.white54,
                          letterSpacing: 0.2,
                          height: 1.0,
                        ),
                      ),
                    ),

                  SizedBox(height: screenHeight * 0.015),

                  // Countdown
                  if (isLoading)
                    Center(
                      child: Column(
                        children: [
                          _skeleton(
                            screenWidth * 0.6,
                            screenWidth * 0.032,
                            radius: 4,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          _skeleton(
                            screenWidth * 0.5,
                            screenWidth * 0.032,
                            radius: 4,
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
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' ${countdown.inHours} jam ${countdown.inMinutes % 60} minit ${countdown.inSeconds % 60} saat lagi',
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
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
                          color: Colors.white70,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                  SizedBox(height: screenHeight * 0.04),

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
                          color: Colors.white70,
                        ),
                      ),
                    ),

                  SizedBox(height: screenHeight * 0.025),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeleton helper ───────────────────────────────────────────────────────

  Widget _skeleton(double w, double h, {double radius = 4}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ── Prayer times skeleton ─────────────────────────────────────────────────

  Widget _buildPrayerTimesSkeletonLoader(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Column(
      children: [
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: screenWidth * 0.035,
            runSpacing: screenHeight * 0.01,
            children: List.generate(
              4,
              (_) => _buildSkeletonPrayerCard(screenWidth),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: screenWidth * 0.035,
            runSpacing: screenHeight * 0.01,
            children: List.generate(
              2,
              (_) => _buildSkeletonPrayerCard(screenWidth),
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
          Container(
            width: screenWidth * 0.08,
            height: screenWidth * 0.08,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          _skeleton(screenWidth * 0.12, screenWidth * 0.038),
          SizedBox(height: screenWidth * 0.01),
          _skeleton(screenWidth * 0.1, screenWidth * 0.032),
        ],
      ),
    );
  }

  // ── Prayer times grid ─────────────────────────────────────────────────────

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
    final iconData = _getPrayerIcon(name);
    final iconColor = _getPrayerColor(name);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.045),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: screenWidth * 0.055,
            color: isPassed ? Colors.white.withOpacity(0.3) : iconColor,
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            time,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w700,
              color: isPassed ? Colors.white38 : Colors.white,
            ),
          ),
          SizedBox(height: screenWidth * 0.008),
          Text(
            name,
            style: TextStyle(
              fontSize: screenWidth * 0.024,
              fontWeight: FontWeight.w500,
              color: isPassed ? Colors.white38 : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        return Icons.brightness_3_rounded;
      case 'syuruk':
        return Icons.flare_rounded;
      case 'zohor':
        return Icons.wb_sunny_rounded;
      case 'asar':
        return Icons.wb_cloudy_rounded;
      case 'maghrib':
        return Icons.wb_twilight_rounded;
      case 'isyak':
        return Icons.nights_stay_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  Color _getPrayerColor(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        return const Color(0xFFB3AAFF);
      case 'syuruk':
        return const Color(0xFFFFD580);
      case 'zohor':
        return const Color(0xFFFFD580);
      case 'asar':
        return const Color(0xFFD4AAFF);
      case 'maghrib':
        return const Color(0xFFFFAACC);
      case 'isyak':
        return const Color(0xFF80EAFF);
      default:
        return Colors.white70;
    }
  }
}

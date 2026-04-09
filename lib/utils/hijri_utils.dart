import 'package:hijri/hijri_calendar.dart';

/// Get Hijri calendar adjusted for Malaysia's official Islamic calendar.
///
/// Malaysia's Islamic calendar is often 1 day ahead of the standard Umm al-Qura
/// calculation used by the hijri package. This function adjusts the calculation
/// by subtracting 1 day to align with Malaysia's official Islamic dates.
///
/// Reference: https://www.e-solat.gov.my/
HijriCalendar getMalaysiaHijriCalendar(DateTime date) {
  // Subtract 1 day to align with Malaysia's official Islamic calendar
  final adjustedDate = date.subtract(const Duration(days: 1));
  return HijriCalendar.fromDate(adjustedDate);
}

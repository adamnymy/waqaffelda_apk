import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hijri/hijri_calendar.dart';
import '../homepage/homepage.dart';
import '../../utils/page_transitions.dart';

// Weekday header widget
class _WeekdayHeader extends StatelessWidget {
  final String text;
  final bool isWeekend;

  const _WeekdayHeader({Key? key, required this.text, this.isWeekend = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        color: isWeekend ? Colors.grey.shade600 : Colors.grey.shade700,
      ),
    );
  }
}

class KalendarIslamPage extends StatefulWidget {
  const KalendarIslamPage({Key? key}) : super(key: key);

  @override
  _KalendarIslamPageState createState() => _KalendarIslamPageState();
}

class _KalendarIslamPageState extends State<KalendarIslamPage> {
  DateTime _displayed = DateTime.now();
  Map<String, List<String>> _events = {}; // key: yyyy-MM-dd
  Map<String, List<String>>? _backupEvents;
  bool _showHijri = true;
  bool _showGregorian = true;

  static const Duration _gridAnimationDuration = Duration(milliseconds: 280);

  // Custom Hijri month names
  static const List<String> _hijriMonths = [
    'Muharram',
    'Safar',
    "Rabi'ulawal",
    "Rabi'ulakhir",
    'Jamadilawwal',
    'Jamadilakhir',
    'Rejab',
    'Sha’ban',
    'Ramadan',
    'Shawwal',
    'Zulkaedah',
    'Zulhijjah',
  ];

  // Whether to show built-in Islamic holidays
  bool _showBuiltInHolidays = true;

  // Hijri-mode (align grid to Hijri months)
  bool _hijriMode = false;

  // Built-in important Islamic events (Hijri month/day)
  // 'month' = Hijri month number (1-12), 'day' = Hijri day
  // If 'range' is true, event covers from 'day' to 'endDay' inclusive
  // 'isHijri' = true for Hijri-based events, false for Gregorian-based events
  final List<Map<String, dynamic>> _importantIslamicEvents = [
    // Islamic Events (Hijri-based)
    {
      'id': 'awal_muharram',
      'name': 'Awal Muharram',
      'name_ms': 'Awal Muharram',
      'details_ms':
          'Tahun Baru Hijrah - permulaan tahun baru dalam kalendar Islam.',
      'month': 1, // Muharram
      'day': 1,
      'range': false,
      'isHijri': true,
      'color': const Color(0xFF5C6BC0),
    },
    {
      'id': 'asyura',
      'name': 'Hari Asyura',
      'name_ms': 'Hari Asyura',
      'details_ms': 'Hari ke-10 Muharram - hari penting dalam sejarah Islam.',
      'month': 1, // Muharram
      'day': 10,
      'range': false,
      'isHijri': true,
      'color': const Color(0xFF7986CB),
    },
    {
      'id': 'maulidur_rasul',
      'name': 'Maulidur Rasul',
      'name_ms': 'Maulidur Rasul',
      'details_ms': 'Hari keputeraan Nabi Muhammad SAW - 12 Rabi\'ulawal.',
      'month': 3, // Rabi'ulawal
      'day': 12,
      'range': false,
      'isHijri': true,
      'color': const Color(0xFF9C27B0),
    },
    {
      'id': 'israk',
      'name': 'Israk & Mikraj',
      'name_ms': 'Israk & Mikraj',
      'details_ms':
          'Peristiwa perjalanan Nabi Muhammad SAW dari Masjid al-Haram ke Masjid al-Aqsa dan naik ke langit.',
      'month': 7, // Rejab
      'day': 27,
      'range': false,
      'isHijri': true,
      'color': const Color(0xFF6A1B9A),
    },
    {
      'id': 'ramadan',
      'name': 'Ramadan (Puasa)',
      'name_ms': 'Bulan Ramadan',
      'details_ms':
          'Bulan puasa yang mulia; masa untuk beribadah dan berpuasa.',
      'month': 9, // Ramadan
      'day': 1,
      'endDay': 30,
      'range': true,
      'isHijri': true,
      'color': const Color(0xFFFFB74D),
    },
    {
      'id': 'nuzul_quran',
      'name': 'Nuzul Quran',
      'name_ms': 'Nuzul Quran',
      'details_ms':
          'Hari turunnya Al-Quran pertama kali kepada Nabi Muhammad SAW - 17 Ramadan.',
      'month': 9, // Ramadan
      'day': 17,
      'range': false,
      'isHijri': true,
      'color': const Color(0xFFFF9800),
    },
    {
      'id': 'lailatul_qadar',
      'name': 'Lailatul Qadar',
      'name_ms': 'Lailatul Qadar',
      'details_ms':
          'Malam yang lebih baik daripada seribu bulan - biasanya pada malam ganjil 10 hari terakhir Ramadan.',
      'month': 9, // Ramadan
      'day': 27,
      'range': false,
      'isHijri': true,
      'color': const Color(0xFFFF6F00),
    },
    {
      'id': 'eid_fitr',
      'name': 'Aidilfitri',
      'name_ms': 'Aidilfitri',
      'details_ms':
          'Perayaan Hari Raya Aidilfitri - hari raya selepas Ramadan.',
      'month': 10, // Shawwal
      'day': 1,
      'range': false,
      'isHijri': true,
      'color': const Color(0xFF66BB6A),
    },
    {
      'id': 'arafah',
      'name': 'Arafah',
      'name_ms': 'Hari Arafah',
      'details_ms': 'Hari 9 Zulhijjah, hari wukuf di Arafah sebelum Aidiladha.',
      'month': 12, // Zulhijjah
      'day': 9,
      'range': false,
      'isHijri': true,
      'color': const Color(0xFFEF5350),
    },
    {
      'id': 'eid_adha',
      'name': 'Aidiladha (Raya Haji)',
      'name_ms': 'Aidiladha',
      'details_ms': 'Perayaan korban pada 10 Zulhijjah.',
      'month': 12,
      'day': 10,
      'range': false,
      'isHijri': true,
      'color': const Color(0xFFE53935),
    },
    {
      'id': 'hajj',
      'name': 'Haji (Musim Haji)',
      'name_ms': 'Musim Haji',
      'details_ms':
          'Musim ibadah Haji yang biasanya melibatkan beberapa hari termasuk 8-13 Zulhijjah.',
      'month': 12,
      'day': 8,
      'endDay': 13,
      'range': true,
      'isHijri': true,
      'color': const Color(0xFFF4511E),
    },
    // Malaysian Holidays (Gregorian-based)
    {
      'id': 'hari_pekerja',
      'name': 'Hari Pekerja',
      'name_ms': 'Hari Pekerja',
      'details_ms': 'Hari Pekerja Antarabangsa - 1 Mei setiap tahun.',
      'month': 5, // Mei
      'day': 1,
      'range': false,
      'isHijri': false,
      'color': const Color(0xFF1976D2),
    },
    {
      'id': 'hari_merdeka',
      'name': 'Hari Merdeka',
      'name_ms': 'Hari Merdeka',
      'details_ms': 'Hari Kemerdekaan Malaysia - 31 Ogos 1957.',
      'month': 8, // Ogos
      'day': 31,
      'range': false,
      'isHijri': false,
      'color': const Color(0xFFD32F2F),
    },
    {
      'id': 'hari_malaysia',
      'name': 'Hari Malaysia',
      'name_ms': 'Hari Malaysia',
      'details_ms': 'Hari penubuhan Malaysia - 16 September 1963.',
      'month': 9, // September
      'day': 16,
      'range': false,
      'isHijri': false,
      'color': const Color(0xFF388E3C),
    },
    {
      'id': 'hari_keputeraan_agong',
      'name': 'Hari Keputeraan Agong',
      'name_ms': 'Hari Keputeraan Agong',
      'details_ms':
          'Hari keputeraan Seri Paduka Baginda Yang di-Pertuan Agong - pertama Sabtu bulan Jun.',
      'month': 6, // Jun (first Saturday)
      'day': 1, // Will be calculated as first Saturday
      'range': false,
      'isHijri': false,
      'isFirstSaturday': true,
      'color': const Color(0xFF7B1FA2),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _clearAllEvents() async {
    final confirm = await _showConfirmationDialog(
      title: 'Reset semua peristiwa',
      content:
          'Anda pasti mahu memadam semua peristiwa? Tindakan ini tidak boleh dipulihkan.',
    );
    if (!confirm) return;

    // Backup for undo
    _backupEvents = Map<String, List<String>>.from(_events);

    setState(() {
      _events.clear();
    });
    await _saveEvents();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Semua peristiwa telah dipadam'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              if (_backupEvents != null) {
                setState(() {
                  _events = Map<String, List<String>>.from(_backupEvents!);
                });
                await _saveEvents();
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _clearMonthEvents() async {
    final confirm = await _showConfirmationDialog(
      title: 'Reset peristiwa bulan ini',
      content:
          'Anda pasti mahu memadam semua peristiwa dalam bulan yang dipaparkan?',
    );
    if (!confirm) return;

    // Backup for undo
    _backupEvents = Map<String, List<String>>.from(_events);

    final prefix =
        '${_displayed.year.toString().padLeft(4, '0')}-${_displayed.month.toString().padLeft(2, '0')}-';
    setState(() {
      _events.removeWhere((key, value) => key.startsWith(prefix));
    });
    await _saveEvents();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Peristiwa bulan ini telah dipadam'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              if (_backupEvents != null) {
                setState(() {
                  _events = Map<String, List<String>>.from(_backupEvents!);
                });
                await _saveEvents();
              }
            },
          ),
        ),
      );
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool?>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00897B),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Padam',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('calendar_events') ?? '{}';
    try {
      final Map<String, dynamic> map = jsonDecode(raw);
      _events = map.map((k, v) => MapEntry(k, List<String>.from(v)));
    } catch (_) {
      _events = {};
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calendar_events', jsonEncode(_events));
  }

  void _prevMonth() {
    setState(() {
      _displayed = DateTime(_displayed.year, _displayed.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayed = DateTime(_displayed.year, _displayed.month + 1, 1);
    });
  }

  void _alignToHijriMonth() {
    // Find Gregorian date which corresponds to hijri day 1 for the hijri month containing _displayed
    final h = HijriCalendar.fromDate(_displayed);
    final targetMonth = h.hMonth;
    final targetYear = h.hYear;

    // search backward up to 60 days
    for (int i = 0; i < 60; i++) {
      final dt = _displayed.subtract(Duration(days: i));
      final hh = HijriCalendar.fromDate(dt);
      if (hh.hMonth == targetMonth && hh.hDay == 1 && hh.hYear == targetYear) {
        setState(() {
          _displayed = DateTime(dt.year, dt.month, 1);
        });
        return;
      }
    }

    // search forward up to 60 days
    for (int i = 1; i < 60; i++) {
      final dt = _displayed.add(Duration(days: i));
      final hh = HijriCalendar.fromDate(dt);
      if (hh.hMonth == targetMonth && hh.hDay == 1 && hh.hYear == targetYear) {
        setState(() {
          _displayed = DateTime(dt.year, dt.month, 1);
        });
        return;
      }
    }
  }

  void _addEvent(DateTime date) async {
    final dateKey = _iso(date);
    final controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tambah Peristiwa',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00897B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}/${date.month}/${date.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Tajuk peristiwa',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF00897B),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        setState(() {
                          _events.putIfAbsent(dateKey, () => []).add(text);
                        });
                        _saveEvents();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Future<void> _addHolidayRangeToCalendar(
    Map<String, dynamic> ev,
    DateTime referenceDate,
  ) async {
    // Backup in case user wants to undo
    _backupEvents = Map<String, List<String>>.from(_events);

    final added = <String>[];
    final daysInMonth = DateTime(_displayed.year, _displayed.month + 1, 0).day;
    final isHijri = ev['isHijri'] ?? true; // Default to Hijri if not specified

    for (int d = 1; d <= daysInMonth; d++) {
      final dt = DateTime(_displayed.year, _displayed.month, d);

      if (isHijri) {
        // Hijri-based events
        final h = HijriCalendar.fromDate(dt);
        if (h.hMonth == ev['month']) {
          if (ev['range'] == true) {
            final start = ev['day'] as int;
            final end = ev['endDay'] as int;
            if (h.hDay >= start && h.hDay <= end) {
              final key = _iso(dt);
              final title = ev['name_ms'] ?? ev['name'];
              final list = _events.putIfAbsent(key, () => []);
              if (!list.contains(title)) {
                list.add(title);
                added.add(key);
              }
            }
          } else {
            if (h.hDay == ev['day']) {
              final key = _iso(dt);
              final title = ev['name_ms'] ?? ev['name'];
              final list = _events.putIfAbsent(key, () => []);
              if (!list.contains(title)) {
                list.add(title);
                added.add(key);
              }
            }
          }
        }
      } else {
        // Gregorian-based events (Malaysian holidays)
        if (dt.month == ev['month']) {
          if (ev['isFirstSaturday'] == true) {
            // Special handling for first Saturday of June
            if (dt.month == 6 && dt.weekday == 6) {
              final firstDayOfMonth = DateTime(dt.year, dt.month, 1);
              final firstDayWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
              int daysToFirstSaturday;
              if (firstDayWeekday == 6) {
                // If 1st is Saturday, first Saturday is day 1
                daysToFirstSaturday = 0;
              } else if (firstDayWeekday == 7) {
                // If 1st is Sunday, first Saturday is day 7
                daysToFirstSaturday = 6;
              } else {
                // Otherwise: (6 - weekday) days
                daysToFirstSaturday = 6 - firstDayWeekday;
              }
              final firstSaturday = firstDayOfMonth.add(
                Duration(days: daysToFirstSaturday),
              );
              if (dt.day == firstSaturday.day) {
                final key = _iso(dt);
                final title = ev['name_ms'] ?? ev['name'];
                final list = _events.putIfAbsent(key, () => []);
                if (!list.contains(title)) {
                  list.add(title);
                  added.add(key);
                }
              }
            }
          } else if (ev['range'] == true) {
            final start = ev['day'] as int;
            final end = ev['endDay'] as int;
            if (dt.day >= start && dt.day <= end) {
              final key = _iso(dt);
              final title = ev['name_ms'] ?? ev['name'];
              final list = _events.putIfAbsent(key, () => []);
              if (!list.contains(title)) {
                list.add(title);
                added.add(key);
              }
            }
          } else {
            if (dt.day == ev['day']) {
              final key = _iso(dt);
              final title = ev['name_ms'] ?? ev['name'];
              final list = _events.putIfAbsent(key, () => []);
              if (!list.contains(title)) {
                list.add(title);
                added.add(key);
              }
            }
          }
        }
      }
    }

    await _saveEvents();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ditambah ${added.length} hari: ${ev['name_ms'] ?? ev['name']}',
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              if (_backupEvents != null) {
                setState(() {
                  _events = Map<String, List<String>>.from(_backupEvents!);
                });
                await _saveEvents();
              }
            },
          ),
        ),
      );
    }
  }

  String _iso(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_displayed.year, _displayed.month + 1, 0).day;
    final startWeekday =
        DateTime(
          _displayed.year,
          _displayed.month,
          1,
        ).weekday; // 1 Mon .. 7 Sun

    // Build list of DateTimes to fill calendar grid (7x6)
    final List<DateTime?> grid = [];
    final leading = (startWeekday) % 7; // make Sunday=0
    for (int i = 0; i < leading; i++) grid.add(null);
    for (int d = 1; d <= daysInMonth; d++)
      grid.add(DateTime(_displayed.year, _displayed.month, d));
    while (grid.length % 7 != 0) grid.add(null);

    // For display, use Gregorian month name
    const gregMonths = [
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

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              SmoothPageRoute(page: const Homepage()),
              (route) => false,
            );
          },
        ),
        title: Row(
          children: [
            Text(
              '${gregMonths[_displayed.month - 1]} ${_displayed.year}',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: colorScheme.onSurface),
            onPressed: () {
              setState(() {
                _displayed = DateTime.now();
              });
            },
            tooltip: 'Hari ini',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'clear_all') {
                _clearAllEvents();
              } else if (value == 'clear_month') {
                _clearMonthEvents();
              } else if (value == 'toggle_holidays') {
                setState(() => _showBuiltInHolidays = !_showBuiltInHolidays);
              } else if (value == 'toggle_hijri_mode') {
                setState(() => _hijriMode = !_hijriMode);
                if (_hijriMode) {
                  _alignToHijriMonth();
                }
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'toggle_holidays',
                    child: Row(
                      children: [
                        Icon(
                          Icons.event,
                          color:
                              _showBuiltInHolidays
                                  ? const Color(0xFF00897B)
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _showBuiltInHolidays
                              ? 'Sembunyikan Hari Islam'
                              : 'Tunjukkan Hari Islam',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_hijri_mode',
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          color:
                              _hijriMode
                                  ? const Color(0xFF00897B)
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _hijriMode
                              ? 'Tunjukkan Bulan Gregorian'
                              : 'Tunjukkan Mengikut Bulan Hijri',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'clear_month',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text('Reset peristiwa bulan ini'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_forever, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text('Reset semua peristiwa'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Month navigation and holiday chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 28),
                  onPressed: _prevMonth,
                  color: colorScheme.onSurface,
                ),
                if (_showBuiltInHolidays)
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children:
                            _importantIslamicEvents.map((ev) {
                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (ev['color'] as Color).withOpacity(
                                    0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: ev['color'] as Color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      ev['name_ms'] ?? ev['name'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: ev['color'] as Color,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 28),
                  onPressed: _nextMonth,
                  color: colorScheme.onSurface,
                ),
              ],
            ),
          ),
          // Weekday headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: const [
                Expanded(child: _WeekdayHeader(text: 'A', isWeekend: true)),
                Expanded(child: _WeekdayHeader(text: 'I')),
                Expanded(child: _WeekdayHeader(text: 'S')),
                Expanded(child: _WeekdayHeader(text: 'R')),
                Expanded(child: _WeekdayHeader(text: 'K')),
                Expanded(child: _WeekdayHeader(text: 'J')),
                Expanded(child: _WeekdayHeader(text: 'S', isWeekend: true)),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          // Calendar grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final rows = (grid.length / 7).ceil();
                final cellHeight = constraints.maxHeight / rows;

                return GridView.builder(
                  padding: const EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: constraints.maxWidth / 7 / cellHeight,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                  ),
                  itemCount: grid.length,
                  itemBuilder: (context, idx) {
                    final dt = grid[idx];
                    if (dt == null) return const SizedBox.shrink();
                    final iso = _iso(dt);
                    final h = HijriCalendar.fromDate(dt);
                    final isToday =
                        DateTime.now().year == dt.year &&
                        DateTime.now().month == dt.month &&
                        DateTime.now().day == dt.day;
                    final hasEvents = _events[iso]?.isNotEmpty ?? false;

                    // collect built-in Islamic holidays and Malaysian holidays for this date
                    final List<Map<String, dynamic>> matchedHolidays = [];
                    for (final ev in _importantIslamicEvents) {
                      final isHijri =
                          ev['isHijri'] ??
                          true; // Default to Hijri if not specified

                      if (isHijri) {
                        // Hijri-based events
                        if (h.hMonth == ev['month']) {
                          if (ev['range'] == true) {
                            final start = ev['day'] as int;
                            final end = ev['endDay'] as int;
                            if (h.hDay >= start && h.hDay <= end)
                              matchedHolidays.add(ev);
                          } else {
                            if (h.hDay == ev['day']) matchedHolidays.add(ev);
                          }
                        }
                      } else {
                        // Gregorian-based events (Malaysian holidays)
                        if (dt.month == ev['month']) {
                          if (ev['isFirstSaturday'] == true) {
                            // Special handling for first Saturday of June (Hari Keputeraan Agong)
                            if (dt.month == 6 && dt.weekday == 6) {
                              // Check if it's the first Saturday of June
                              final firstDayOfMonth = DateTime(
                                dt.year,
                                dt.month,
                                1,
                              );
                              final firstDayWeekday =
                                  firstDayOfMonth.weekday; // 1=Mon, 7=Sun
                              int daysToFirstSaturday;
                              if (firstDayWeekday == 6) {
                                // If 1st is Saturday, first Saturday is day 1
                                daysToFirstSaturday = 0;
                              } else if (firstDayWeekday == 7) {
                                // If 1st is Sunday, first Saturday is day 7
                                daysToFirstSaturday = 6;
                              } else {
                                // Otherwise: (6 - weekday) days
                                daysToFirstSaturday = 6 - firstDayWeekday;
                              }
                              final firstSaturday = firstDayOfMonth.add(
                                Duration(days: daysToFirstSaturday),
                              );
                              if (dt.day == firstSaturday.day) {
                                matchedHolidays.add(ev);
                              }
                            }
                          } else if (ev['range'] == true) {
                            final start = ev['day'] as int;
                            final end = ev['endDay'] as int;
                            if (dt.day >= start && dt.day <= end)
                              matchedHolidays.add(ev);
                          } else {
                            if (dt.day == ev['day']) matchedHolidays.add(ev);
                          }
                        }
                      }
                    }

                    final bool isHoliday = matchedHolidays.isNotEmpty;
                    final isWeekend = dt.weekday == 6 || dt.weekday == 7;

                    return Material(
                      color:
                          isToday
                              ? const Color(0xFF00897B).withOpacity(0.08)
                              : Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDayDialog(dt),
                        onLongPress: () => _addEvent(dt),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Gregorian date
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration:
                                    isToday
                                        ? const BoxDecoration(
                                          color: Color(0xFF00897B),
                                          shape: BoxShape.circle,
                                        )
                                        : null,
                                child: Text(
                                  '${dt.day}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        isToday
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                    color:
                                        isToday
                                            ? Colors.white
                                            : isWeekend
                                            ? Colors.grey.shade600
                                            : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Hijri date
                              Text(
                                '${h.hDay}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const Spacer(),
                              // Event indicators
                              if (hasEvents || isHoliday)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isHoliday)
                                      Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.only(right: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              matchedHolidays.first['color']
                                                  as Color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    if (hasEvents)
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00897B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00897B),
        onPressed: () {
          _addEvent(DateTime.now());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDayDialog(DateTime date) {
    final key = _iso(date);
    final list = _events[key] ?? [];

    // compute matched holidays for this date (both Hijri and Gregorian)
    final h = HijriCalendar.fromDate(date);
    final List<Map<String, dynamic>> holidayObjects = [];
    for (final ev in _importantIslamicEvents) {
      final isHijri =
          ev['isHijri'] ?? true; // Default to Hijri if not specified

      if (isHijri) {
        // Hijri-based events
        if (h.hMonth == ev['month']) {
          if (ev['range'] == true) {
            final start = ev['day'] as int;
            final end = ev['endDay'] as int;
            if (h.hDay >= start && h.hDay <= end) holidayObjects.add(ev);
          } else {
            if (h.hDay == ev['day']) holidayObjects.add(ev);
          }
        }
      } else {
        // Gregorian-based events (Malaysian holidays)
        if (date.month == ev['month']) {
          if (ev['isFirstSaturday'] == true) {
            // Special handling for first Saturday of June (Hari Keputeraan Agong)
            if (date.month == 6 && date.weekday == 6) {
              // Check if it's the first Saturday of June
              final firstDayOfMonth = DateTime(date.year, date.month, 1);
              final firstDayWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
              int daysToFirstSaturday;
              if (firstDayWeekday == 6) {
                // If 1st is Saturday, first Saturday is day 1
                daysToFirstSaturday = 0;
              } else if (firstDayWeekday == 7) {
                // If 1st is Sunday, first Saturday is day 7
                daysToFirstSaturday = 6;
              } else {
                // Otherwise: (6 - weekday) days
                daysToFirstSaturday = 6 - firstDayWeekday;
              }
              final firstSaturday = firstDayOfMonth.add(
                Duration(days: daysToFirstSaturday),
              );
              if (date.day == firstSaturday.day) {
                holidayObjects.add(ev);
              }
            }
          } else if (ev['range'] == true) {
            final start = ev['day'] as int;
            final end = ev['endDay'] as int;
            if (date.day >= start && date.day <= end) holidayObjects.add(ev);
          } else {
            if (date.day == ev['day']) holidayObjects.add(ev);
          }
        }
      }
    }

    Future<void> _showHolidayInfo(Map<String, dynamic> ev) async {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder:
            (ctx) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (ev['color'] as Color),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.celebration,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          ev['name_ms'] ?? ev['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF00897B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (ev['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (ev['color'] as Color).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      ev['details_ms'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          // Add the whole holiday range to displayed month (if range) or just this date
                          if (ev['range'] == true) {
                            _addHolidayRangeToCalendar(ev, date);
                          } else {
                            setState(() {
                              _events
                                  .putIfAbsent(_iso(date), () => [])
                                  .add(ev['name_ms'] ?? ev['name']);
                            });
                            _saveEvents();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (ev['color'] as Color),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Tambahkan ke Kalendar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Peristiwa',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF00897B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}/${date.month}/${date.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (holidayObjects.isNotEmpty && _showBuiltInHolidays) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        holidayObjects.map((ev) {
                          return InkWell(
                            onTap: () => _showHolidayInfo(ev),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: (ev['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (ev['color'] as Color).withOpacity(
                                    0.2,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: ev['color'] as Color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    ev['name_ms'] ?? ev['name'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: ev['color'] as Color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (list.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade400),
                        const SizedBox(width: 12),
                        Text(
                          'Tiada peristiwa.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (list.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00897B).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00897B).withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00897B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  list[index],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Row(
                      children: [
                        if (holidayObjects.isNotEmpty && _showBuiltInHolidays)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _showHolidayInfo(holidayObjects.first);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (holidayObjects.first['color'] as Color),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Maklumat Perayaan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _addEvent(date);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00897B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Tambah',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
    );
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:home_widget/home_widget.dart';
import 'widget_service.dart';

/// WorkManager callback dispatcher - must be a top-level function
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('🔔 WorkManager task started: $task');
      // If this is the daily rescheduler task, attempt to load cached prayer times
      // and re-register notifications from preferences.
      if (task == 'reschedulePrayers' || task == 'daily_rescheduler') {
        debugPrint('🔄 Background rescheduler triggered');
        await _scheduleFromCachedPrayerTimes();
        return Future.value(true);
      }

      // Get notification details from input data
      final title = inputData?['title'] ?? 'Prayer Time';
      final body = inputData?['body'] ?? 'It\'s time for prayer';
      final channelId = inputData?['channelId'] ?? 'prayer_default';

      debugPrint(
        '📝 Notification data: Title=$title, Body=$body, Channel=$channelId',
      );

      // Initialize FlutterLocalNotificationsPlugin
      final notifications = FlutterLocalNotificationsPlugin();

      // Initialize with Android settings
      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettingsIOS = DarwinInitializationSettings();
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await notifications.initialize(initializationSettings);
      debugPrint(
        '✅ FlutterLocalNotificationsPlugin initialized in WorkManager',
      );

      // Create notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        'Prayer Notifications',
        channelDescription: 'Prayer time notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification with unique ID
      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
      await notifications.show(notificationId, title, body, details);

      // Update widget to reflect new prayer state
      try {
        await NotificationService._updateWidgetAfterNotification(title);
        debugPrint('🔄 Widget updated after WorkManager notification: $title');
      } catch (e) {
        debugPrint(
          '⚠️ Failed to update widget after WorkManager notification: $e',
        );
      }

      // Persist execution timestamp and compare with scheduled time (if provided)
      try {
        final prefs = await SharedPreferences.getInstance();
        final scheduledAtStr = inputData?['scheduledAt'] as String?;
        final keyBase =
            (title ?? 'prayer').toString().replaceAll(' ', '_').toLowerCase();
        if (scheduledAtStr != null) {
          await prefs.setString('scheduled_${keyBase}', scheduledAtStr);
          final scheduledAt = DateTime.parse(scheduledAtStr);
          final executedAt = DateTime.now().toUtc();
          await prefs.setString(
            'executed_${keyBase}',
            executedAt.toIso8601String(),
          );
          final elapsed = executedAt.difference(scheduledAt.toUtc()).inSeconds;
          debugPrint(
            '⏱️ Notification executed for $title. Scheduled: $scheduledAtStr, Executed: ${executedAt.toIso8601String()}, Elapsed: ${elapsed}s',
          );
        } else {
          final executedAt = DateTime.now().toUtc();
          await prefs.setString(
            'executed_${keyBase}',
            executedAt.toIso8601String(),
          );
          debugPrint(
            '⏱️ Notification executed for $title. Executed: ${executedAt.toIso8601String()} (no scheduled timestamp)',
          );
        }
      } catch (e) {
        debugPrint('⚠️ Failed to persist execution timestamp: $e');
      }

      debugPrint(
        '✅ WorkManager notification shown: $title (ID: $notificationId)',
      );
      return Future.value(true); // Success
    } catch (e, stackTrace) {
      debugPrint('❌ WorkManager task failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return Future.value(false); // Failure
    }
  });
}

/// Fetch fresh prayer times from API and schedule WorkManager tasks.
@pragma('vm:entry-point')
Future<void> _scheduleFromCachedPrayerTimes() async {
  try {
    debugPrint('🔄 [BG] Starting background reschedule with fresh API fetch');

    final prefs = await SharedPreferences.getInstance();
    List<dynamic> list;

    // Try to fetch fresh prayer times from API
    try {
      debugPrint('🌐 [BG] Attempting to fetch fresh prayer times from API...');

      // Get last known location from SharedPreferences
      final lastLat = prefs.getDouble('last_known_lat');
      final lastLng = prefs.getDouble('last_known_lng');

      // Only proceed with API if we have valid location
      if (lastLat == null || lastLng == null) {
        debugPrint(
          '⚠️ [BG] No saved location found. Please open app to set location.',
        );

        // Fall back to cached prayer times
        final cached = prefs.getString('cached_prayer_times');
        if (cached == null) {
          debugPrint('❌ [BG] No cached prayer times found');
          return;
        }

        list = jsonDecode(cached);
        if (list.isEmpty) {
          debugPrint('❌ [BG] Cached prayer times list is empty');
          return;
        }

        debugPrint('📋 [BG] Using ${list.length} cached prayer times');
      } else {
        debugPrint('📍 [BG] Using saved location: $lastLat, $lastLng');

        // Fetch tomorrow's prayer times
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final url =
            'https://www.e-solat.gov.my/index.php?r=esolatApi/TakwimSolat&period=month&zone=WLY01&year=${tomorrow.year}&month=${tomorrow.month.toString().padLeft(2, '0')}';

        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'OK' &&
              data['prayerTime'] != null &&
              data['prayerTime'].isNotEmpty) {
            // Find tomorrow's prayer times
            final tomorrowDateStr = tomorrow.day.toString().padLeft(2, '0');
            final tomorrowData = (data['prayerTime'] as List).firstWhere(
              (day) =>
                  day['date'].toString().split('-').last == tomorrowDateStr,
              orElse: () => null,
            );

            if (tomorrowData != null) {
              // Convert to our format
              list = [
                {'name': 'Subuh', 'time': tomorrowData['fajr']},
                {'name': 'Zohor', 'time': tomorrowData['dhuhr']},
                {'name': 'Asar', 'time': tomorrowData['asr']},
                {'name': 'Maghrib', 'time': tomorrowData['maghrib']},
                {'name': 'Isyak', 'time': tomorrowData['isha']},
              ];

              // Save fresh data to cache
              await prefs.setString('cached_prayer_times', jsonEncode(list));
              debugPrint(
                '✅ [BG] Successfully fetched and cached fresh prayer times from API',
              );
            } else {
              throw Exception('Tomorrow\'s data not found in API response');
            }
          } else {
            throw Exception('Invalid API response format');
          }
        } else {
          throw Exception('API returned status code: ${response.statusCode}');
        }
      }
    } catch (apiError) {
      debugPrint(
        '⚠️ [BG] API fetch failed: $apiError. Falling back to cache...',
      );

      // Fall back to cached prayer times
      final cached = prefs.getString('cached_prayer_times');
      if (cached == null) {
        debugPrint('❌ [BG] No cached prayer times found for fallback');
        return;
      }

      list = jsonDecode(cached);
      if (list.isEmpty) {
        debugPrint('❌ [BG] Cached prayer times list is empty');
        return;
      }

      debugPrint(
        '📋 [BG] Using ${list.length} cached prayer times as fallback',
      );
    }

    debugPrint('📋 [BG] Processing ${list.length} prayer times for scheduling');

    // Parse times for tomorrow (since this runs at night after all today's prayers passed)
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    int scheduledCount = 0;

    // Each item should be {name: '', time: ''}
    for (var item in list) {
      try {
        final prayerName = item['name'] as String;
        final timeString = item['time'] as String;

        // Skip Syuruk as it's not a prayer time
        if (prayerName == 'Syuruk') {
          debugPrint('⏭️ [BG] Skipping $prayerName (not a prayer time)');
          continue;
        }

        debugPrint('🕐 [BG] Processing $prayerName: $timeString');

        // Parse time string manually (can't use instance method in isolate)
        final parsedTime = _parseTimeStringStatic(timeString, tomorrow);
        if (parsedTime == null) {
          debugPrint(
            '❌ [BG] Failed to parse time for $prayerName: $timeString',
          );
          continue;
        }

        // Calculate delay from now
        final delaySeconds = parsedTime.difference(now).inSeconds;

        if (delaySeconds <= 0) {
          debugPrint(
            '⚠️ [BG] Skipping $prayerName - time already passed (delay: ${delaySeconds}s)',
          );
          continue;
        }

        debugPrint(
          '✅ [BG] Scheduling $prayerName for $parsedTime (delay: ${delaySeconds}s / ${(delaySeconds / 3600).toStringAsFixed(1)}h)',
        );

        final bgTitle = 'Waktu Solat $prayerName';
        final bgBody =
            'Telah masuk waktu solat fardhu $prayerName pada $timeString';

        await Workmanager().registerOneOffTask(
          'bg_prayer_${prayerName.toLowerCase()}_${now.millisecondsSinceEpoch}',
          'showPrayerNotification',
          inputData: {
            'title': bgTitle,
            'body': bgBody,
            'channelId':
                NotificationService.prayerConfig[prayerName]?['channelId'] ??
                'prayer_default',
            'scheduledAt': parsedTime.toUtc().toIso8601String(),
          },
          initialDelay: Duration(seconds: delaySeconds),
          constraints: Constraints(
            networkType: NetworkType.not_required,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresBatteryNotLow: false,
            requiresStorageNotLow: false,
          ),
          backoffPolicy: BackoffPolicy.linear,
          backoffPolicyDelay: const Duration(seconds: 10),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );

        scheduledCount++;
      } catch (e) {
        debugPrint('❌ [BG] Error scheduling from cache: $e');
      }
    }

    // Update the last_scheduled_date to tomorrow's date
    final tomorrowDate = DateFormat('yyyy-MM-dd').format(tomorrow);
    await prefs.setString('last_scheduled_date', tomorrowDate);
    debugPrint('💾 [BG] Updated last_scheduled_date to: $tomorrowDate');

    // Update widget with the fresh prayer times data
    try {
      await WidgetService.updateWidget();
      debugPrint('🔄 [BG] Widget updated with fresh prayer times');
    } catch (e) {
      debugPrint('⚠️ [BG] Widget update failed: $e');
    }

    debugPrint(
      '✅ [BG] Background reschedule complete - scheduled $scheduledCount prayers for tomorrow',
    );
  } catch (e) {
    debugPrint('❌ [BG] _scheduleFromCachedPrayerTimes failed: $e');
  }
}

/// Static time parser for use in background isolate (can't access instance methods)
DateTime? _parseTimeStringStatic(String timeStr, DateTime baseDate) {
  try {
    timeStr = timeStr.trim();
    final parts = timeStr.split(' ');

    if (parts.length == 2) {
      // 12-hour format: "HH:MM AM/PM"
      final timePart = parts[0];
      final period = parts[1].toUpperCase();

      final timeComponents = timePart.split(':');
      if (timeComponents.length != 2) return null;

      int hour = int.parse(timeComponents[0]);
      final minute = int.parse(timeComponents[1]);

      // Convert to 24-hour format
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        hour,
        minute,
      );
    } else if (parts.length == 1) {
      // 24-hour format: "HH:MM"
      final timeComponents = timeStr.split(':');
      if (timeComponents.length != 2) return null;

      final hour = int.parse(timeComponents[0]);
      final minute = int.parse(timeComponents[1]);

      return DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        hour,
        minute,
      );
    }

    return null;
  } catch (e) {
    debugPrint('❌ [BG] Error parsing time string "$timeStr": $e');
    return null;
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Callback for navigation when notification is tapped
  static void Function()? onNotificationTapped;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Sky-themed colors for each prayer time
  static const Map<String, Map<String, dynamic>> prayerConfig = {
    'Subuh': {
      'color': 0xFF2196F3, // Blue - langit pagi
      'icon': '@mipmap/ic_launcher',
      'channelId': 'prayer_subuh',
      'channelName': 'Waktu Subuh',
      'title': 'Waktu Solat Subuh',
      'body': 'Sudah tiba waktu untuk menunaikan solat Subuh.',
    },
    'Zohor': {
      'color': 0xFFFFC107, // Yellow - matahari tengahari
      'icon': '@mipmap/ic_launcher',
      'channelId': 'prayer_zohor',
      'channelName': 'Waktu Zohor',
      'title': 'Waktu Solat Zohor',
      'body': 'Sudah tiba waktu untuk menunaikan solat Zohor.',
    },
    'Asar': {
      'color': 0xFFFF9800, // Orange - petang
      'icon': '@mipmap/ic_launcher',
      'channelId': 'prayer_asar',
      'channelName': 'Waktu Asar',
      'title': 'Waktu Solat Asar',
      'body': 'Sudah tiba waktu untuk menunaikan solat Asar.',
    },
    'Maghrib': {
      'color': 0xFFFF5722, // Deep Orange - senja
      'icon': '@mipmap/ic_launcher',
      'channelId': 'prayer_maghrib',
      'channelName': 'Waktu Maghrib',
      'title': 'Waktu Solat Maghrib',
      'body': 'Sudah tiba waktu untuk menunaikan solat Maghrib.',
    },
    'Isyak': {
      'color': 0xFF3F51B5, // Indigo - malam
      'icon': '@mipmap/ic_launcher',
      'channelId': 'prayer_isyak',
      'channelName': 'Waktu Isyak',
      'title': 'Waktu Solat Isyak',
      'body': 'Sudah tiba waktu untuk menunaikan solat Isyak.',
    },
  };

  /// Calculate initial delay to run background task at 11:50 PM
  Duration _calculateInitialDelay() {
    final now = DateTime.now();
    var targetTime = DateTime(now.year, now.month, now.day, 23, 50); // 11:50 PM

    // If it's already past 11:50 PM today, schedule for tomorrow
    if (now.isAfter(targetTime)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }

    final delay = targetTime.difference(now);
    debugPrint(
      '⏰ Background reschedule will first run at $targetTime (in ${delay.inHours}h ${delay.inMinutes % 60}m)',
    );
    return delay;
  }

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    // Initialize WorkManager for background tasks
    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: false, // Production mode - no debug notifications
    );

    // Register daily background task to auto-reschedule prayer times
    // This runs every 24 hours to schedule tomorrow's notifications
    await Workmanager().registerPeriodicTask(
      'daily_rescheduler', // Unique task name
      'daily_rescheduler', // Task type (matches callback dispatcher)
      frequency: const Duration(hours: 24), // Run every 24 hours
      initialDelay: _calculateInitialDelay(), // Run at 11:50 PM
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    debugPrint(
      '✅ Daily auto-reschedule enabled - runs every 24 hours at 11:50 PM',
    );

    _isInitialized = true;
    debugPrint('✅ Notification service initialized');

    // Check if exact alarm scheduling is available (Android 12+). If not available,
    // automatically request the permission for precise notifications.
    try {
      final can = await canScheduleExactAlarms();
      if (!can) {
        debugPrint('⚠️ Exact alarm permission not granted - requesting now...');
        final granted = await requestExactAlarmPermission();
        if (granted) {
          debugPrint('✅ Exact alarm permission granted by user');
        } else {
          debugPrint(
            '⚠️ Exact alarm permission denied - notifications may not be precise',
          );
        }
      } else {
        debugPrint('✅ Exact alarm permission already granted');
      }
    } catch (e) {
      debugPrint('⚠️ Error checking/requesting exact alarm capability: $e');
    }
  }

  // Platform channel helper to check if the device allows scheduling exact alarms
  static const MethodChannel _exactAlarmChannel = MethodChannel(
    'waqaffelda/exact_alarm',
  );

  /// Returns true if app can schedule exact alarms (Android 12+), or true on older
  /// platforms where the permission is not required.
  Future<bool> canScheduleExactAlarms() async {
    try {
      final res = await _exactAlarmChannel.invokeMethod(
        'canScheduleExactAlarms',
      );
      return res == true;
    } catch (e) {
      debugPrint('⚠️ canScheduleExactAlarms call failed: $e');
      return true; // assume allowed if platform call fails
    }
  }

  /// Open system UI to request exact-alarm permission (Android 12+).
  Future<bool> requestExactAlarmPermission() async {
    try {
      final res = await _exactAlarmChannel.invokeMethod(
        'requestExactAlarmPermission',
      );
      return res == true;
    } catch (e) {
      debugPrint('⚠️ requestExactAlarmPermission call failed: $e');
      return false;
    }
  }

  /// Open battery optimization settings (so user can exempt the app)
  Future<bool> openBatteryOptimizationSettings() async {
    try {
      final res = await _exactAlarmChannel.invokeMethod(
        'openBatteryOptimizationSettings',
      );
      return res == true;
    } catch (e) {
      debugPrint('⚠️ openBatteryOptimizationSettings call failed: $e');
      return false;
    }
  }

  /// Request user to ignore battery optimizations for this app (opens system dialog)
  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final res = await _exactAlarmChannel.invokeMethod(
        'requestIgnoreBatteryOptimizations',
      );
      return res == true;
    } catch (e) {
      debugPrint('⚠️ requestIgnoreBatteryOptimizations call failed: $e');
      return false;
    }
  }

  /// Schedule native exact alarm using AlarmManager (guaranteed exact timing)
  Future<bool> _scheduleNativeExactAlarm(
    int notificationId,
    DateTime scheduledTime,
    String prayerName,
    String title,
    String body,
    String channelId,
  ) async {
    try {
      final triggerAtMillis = scheduledTime.millisecondsSinceEpoch;
      final res = await _exactAlarmChannel.invokeMethod('scheduleExactAlarm', {
        'notificationId': notificationId,
        'triggerAtMillis': triggerAtMillis,
        'prayerName': prayerName,
        'title': title,
        'body': body,
        'channelId': channelId,
      });
      return res == true;
    } catch (e) {
      debugPrint('⚠️ Failed to schedule native exact alarm: $e');
      return false;
    }
  }

  /// Cancel native exact alarm
  Future<bool> _cancelNativeExactAlarm(int notificationId) async {
    try {
      final res = await _exactAlarmChannel.invokeMethod('cancelExactAlarm', {
        'notificationId': notificationId,
      });
      return res == true;
    } catch (e) {
      debugPrint('⚠️ Failed to cancel native exact alarm: $e');
      return false;
    }
  }

  /// Cancel native widget update alarm (uses separate action on Android)
  Future<bool> _cancelWidgetUpdateAlarm(int widgetUpdateId) async {
    try {
      final res = await _exactAlarmChannel.invokeMethod(
        'cancelWidgetUpdateAlarm',
        {'widgetUpdateId': widgetUpdateId},
      );
      return res == true;
    } catch (e) {
      debugPrint('⚠️ Failed to cancel native widget update alarm: $e');
      return false;
    }
  }

  /// Cancel all native exact alarms
  Future<bool> cancelAllNativeExactAlarms() async {
    try {
      final res = await _exactAlarmChannel.invokeMethod('cancelAllExactAlarms');
      return res == true;
    } catch (e) {
      debugPrint('⚠️ Failed to cancel all native exact alarms: $e');
      return false;
    }
  }

  /// Schedule widget-only update at exact prayer time (independent of notifications)
  Future<bool> _scheduleWidgetUpdateAlarm(
    int widgetUpdateId,
    DateTime scheduledTime,
    String prayerName,
  ) async {
    try {
      final triggerAtMillis = scheduledTime.millisecondsSinceEpoch;
      final res = await _exactAlarmChannel
          .invokeMethod('scheduleWidgetUpdateAlarm', {
            'widgetUpdateId': widgetUpdateId,
            'triggerAtMillis': triggerAtMillis,
            'prayerName': prayerName,
          });
      return res == true;
    } catch (e) {
      debugPrint('⚠️ Failed to schedule widget update alarm: $e');
      return false;
    }
  }

  /// Public wrapper for parsing time strings so background isolate can use it
  tz.TZDateTime? parseTimeString(String timeStr) {
    return _parseTimeString(timeStr);
  }

  /// Create separate notification channels for each prayer
  Future<void> _createNotificationChannels() async {
    for (var entry in prayerConfig.entries) {
      final config = entry.value;
      final androidChannel = AndroidNotificationChannel(
        config['channelId'],
        config['channelName'],
        description: 'Notifikasi untuk ${config['channelName']}',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }
    // Create a test channel used by scheduled test notifications
    final testChannel = AndroidNotificationChannel(
      'test_channel',
      'Test Notifications',
      description: 'Untuk test scheduled notifications',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(testChannel);
    debugPrint('✅ Notification channels created');
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    // iOS
    final iosImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    final iosGranted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android 13+
    final androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    final androidGranted =
        await androidImplementation?.requestNotificationsPermission();

    debugPrint(
      '📱 Permission granted: iOS: $iosGranted, Android: $androidGranted',
    );
    return iosGranted ?? androidGranted ?? true;
  }

  /// Parse time string to TZDateTime (handles both 24-hour and 12-hour format with AM/PM)
  tz.TZDateTime? _parseTimeString(String timeStr) {
    try {
      final now = tz.TZDateTime.now(tz.local);

      // Remove any extra spaces
      timeStr = timeStr.trim();

      // Check if it's 12-hour format (contains AM/PM) or 24-hour format
      final parts = timeStr.split(' ');

      if (parts.length == 2) {
        // 12-hour format: "HH:MM AM/PM" or "H:MM AM/PM"
        final timePart = parts[0];
        final period = parts[1].toUpperCase();

        final timeComponents = timePart.split(':');
        if (timeComponents.length != 2) return null;

        int hour = int.parse(timeComponents[0]);
        final minute = int.parse(timeComponents[1]);

        // Convert to 24-hour format
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
      } else if (parts.length == 1) {
        // 24-hour format: "HH:MM" or "HH:MM:SS" or "H:MM"
        final timeComponents = timeStr.split(':');

        // Handle both "HH:MM" and "HH:MM:SS" formats
        if (timeComponents.length < 2 || timeComponents.length > 3) return null;

        final hour = int.parse(timeComponents[0]);
        final minute = int.parse(timeComponents[1]);
        // Ignore seconds if present (timeComponents[2])

        final result = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        debugPrint('✅ Parsed time "$timeStr" → ${result.toString()}');
        return result;
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ Error parsing time "$timeStr": $e');
      return null;
    }
  }

  /// Get unique notification ID for each prayer
  int _getNotificationId(String prayerName) {
    switch (prayerName) {
      case 'Subuh':
        return 1001;
      case 'Zohor':
        return 1002;
      case 'Asar':
        return 1003;
      case 'Maghrib':
        return 1004;
      case 'Isyak':
        return 1005;
      default:
        return 1000;
    }
  }

  /// Enable/disable notification for a specific prayer
  Future<void> setNotificationEnabled(String prayerName, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_$prayerName', enabled);
    debugPrint('💾 Saved: notification_$prayerName = $enabled');
  }

  /// Cancel all prayer notifications
  Future<void> cancelAllPrayerNotifications() async {
    for (var prayerName in prayerConfig.keys) {
      final id = _getNotificationId(prayerName);
      await _notifications.cancel(id);
    }
    debugPrint('🗑️ Cancelled all prayer notifications');
  }

  /// Cancel notification for a specific prayer
  Future<void> cancelPrayerNotification(String prayerName) async {
    final id = _getNotificationId(prayerName);
    await _notifications.cancel(id);
    debugPrint('🗑️ Cancelled notification for $prayerName');
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Show immediate test notification
  Future<void> showTestNotification(String prayerName) async {
    final config = prayerConfig[prayerName];
    if (config == null) return;

    final notificationId = _getNotificationId(prayerName);

    final androidDetails = AndroidNotificationDetails(
      config['channelId'],
      config['channelName'],
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notifications.show(
      notificationId,
      'Test - Waktu $prayerName',
      'Ini adalah notifikasi percubaan untuk waktu $prayerName',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );

    debugPrint('🔔 Test notification shown for $prayerName');
  }

  /// Schedule test notification using WorkManager (MIUI-compatible)
  Future<void> scheduleTestNotificationWorkManager() async {
    if (!_isInitialized) {
      await initialize();
    }

    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 10));

    debugPrint(
      '🔧 Scheduling WorkManager test notification for: ${scheduledTime.toString()}',
    );
    debugPrint('📱 You will receive WorkManager notification in ~10 seconds');

    // Calculate delay in minutes (WorkManager minimum is 15 minutes, but we can use seconds for testing)
    final delaySeconds = scheduledTime.difference(now).inSeconds;

    await Workmanager().registerOneOffTask(
      'test_notification_${now.millisecondsSinceEpoch}', // Unique task name
      'showPrayerNotification', // Task identifier
      inputData: {
        'title': '🧪 WorkManager Test Notification',
        'body':
            'Jika anda nampak notifikasi ini, WorkManager berfungsi dengan baik pada MIUI!',
        'channelId': 'test_channel',
        'scheduledAt': scheduledTime.toUtc().toIso8601String(),
      },
      initialDelay: Duration(seconds: delaySeconds),
      constraints: Constraints(
        networkType: NetworkType.not_required, // No network needed
        requiresCharging: false, // Can run when not charging
        requiresDeviceIdle: false, // Can run when device is active
        requiresBatteryNotLow: false, // Can run when battery is low
        requiresStorageNotLow: false, // Can run when storage is low
      ),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(seconds: 10),
      existingWorkPolicy: ExistingWorkPolicy.replace, // Replace if exists
    );

    debugPrint('✅ WorkManager task registered successfully');
  }

  /// Schedule prayer notifications using WorkManager (MIUI-compatible)
  Future<void> schedulePrayerNotificationsWorkManager(
    List<Map<String, dynamic>> prayerTimes,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    debugPrint(
      '🔧 Scheduling prayer notifications with WorkManager for $today',
    );

    // Cancel ALL existing alarms first to prevent duplicates
    try {
      await cancelAllNativeExactAlarms();
      await Workmanager().cancelAll();
      debugPrint('🗑️ Cancelled all existing alarms (native + WorkManager)');
    } catch (e) {
      debugPrint('⚠️ Error cancelling existing alarms: $e');
    }

    // Schedule for 7 days ahead
    int totalScheduled = 0;
    int totalSkipped = 0;

    debugPrint('📅 Scheduling for next 7 days...\n');

    for (int day = 0; day < 7; day++) {
      final targetDate = now.add(Duration(days: day));
      final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
      int dayScheduled = 0;
      int daySkipped = 0;

      debugPrint('📆 Day +$day ($dateStr):');

      for (var prayer in prayerTimes) {
        final prayerName = prayer['name'] as String;
        // Use time24 if available, fallback to time (12-hour format)
        final prayerTimeString = (prayer['time24'] ?? prayer['time']) as String;

        // Skip Syuruk as requested
        if (prayerName.toLowerCase() == 'syuruk') {
          daySkipped++;
          continue;
        }

        try {
          await _scheduleSinglePrayerWorkManager(
            prayerName,
            prayerTimeString,
            daysFromNow: day,
          );
          dayScheduled++;
        } catch (e) {
          debugPrint('❌ Error scheduling $prayerName for day +$day: $e');
          daySkipped++;
        }
      }

      debugPrint('  ✅ $dayScheduled scheduled, $daySkipped skipped\n');
      totalScheduled += dayScheduled;
      totalSkipped += daySkipped;
    }

    debugPrint(
      '🎉 7-day scheduling complete: $totalScheduled total prayers scheduled, $totalSkipped skipped',
    );

    // Store the scheduled date and expiry
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_scheduled_date', today);
    final expiryDate = now.add(const Duration(days: 7));
    await prefs.setString(
      'schedule_expires_at',
      DateFormat('yyyy-MM-dd').format(expiryDate),
    );
    debugPrint(
      '💾 Schedule valid until: ${DateFormat('yyyy-MM-dd').format(expiryDate)}',
    );
  }

  /// Schedule a single prayer notification using NATIVE EXACT ALARMS (primary)
  /// with WorkManager as backup for devices without exact alarm permission
  Future<void> _scheduleSinglePrayerWorkManager(
    String prayerName,
    String timeString, {
    int daysFromNow = 0,
  }) async {
    final config = prayerConfig[prayerName];
    if (config == null) {
      throw Exception('Unknown prayer: $prayerName');
    }

    final now = DateTime.now();
    final parsedTime = _parseTimeString(timeString);
    if (parsedTime == null) {
      debugPrint('❌ Failed to parse time string: $timeString for $prayerName');
      throw Exception('Invalid time string: $timeString');
    }

    var scheduledTime = parsedTime;

    // (Debug logs removed)

    // Add days if scheduling for future
    if (daysFromNow > 0) {
      scheduledTime = scheduledTime.add(Duration(days: daysFromNow));
    }

    // If the prayer time has already passed today (and daysFromNow=0), schedule for tomorrow
    if (daysFromNow == 0 && scheduledTime.isBefore(now)) {
      debugPrint(
        '⏰ $prayerName time has passed today, scheduling for tomorrow',
      );
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final delaySeconds = scheduledTime.difference(now).inSeconds;
    // Use unique ID for each day: base ID + (day * 100)
    final notificationId = _getNotificationId(prayerName) + (daysFromNow * 100);

    // Format time in 12-hour format for display
    final timeLabel12h = DateFormat(
      'h:mm a',
    ).format(scheduledTime); // e.g., "6:58 PM"
    final dynamicTitle = 'Waktu Solat $prayerName';
    final locationName = await _getCurrentLocationName();
    final locationText = locationName != null ? '($locationName)' : '';
    final dynamicBody =
        'Telah masuk waktu solat fardhu $prayerName pada $timeLabel12h $locationText';

    debugPrint(
      '🔧 Scheduling $prayerName (ID:$notificationId) for ${scheduledTime.toString()} (day +$daysFromNow, delay: ${delaySeconds}s / ${(delaySeconds / 3600).toStringAsFixed(1)}h)',
    );

    // PRIMARY METHOD: Use native AlarmManager.setExactAndAllowWhileIdle for ALL prayers
    bool nativeScheduleSuccess = false;
    try {
      // Ensure any existing alarms for this exact ID are cancelled first
      try {
        await _cancelNativeExactAlarm(notificationId);
        // Also cancel widget update alarm if any
        await _cancelWidgetUpdateAlarm(notificationId + 10000);
        debugPrint('🗑️ Cleared existing native alarms for id $notificationId');
      } catch (e) {
        debugPrint(
          '⚠️ Failed to clear existing alarms for id $notificationId: $e',
        );
      }
      final success = await _scheduleNativeExactAlarm(
        notificationId,
        scheduledTime,
        prayerName,
        dynamicTitle,
        dynamicBody,
        config['channelId'],
      );

      if (success) {
        debugPrint(
          '✅ Native exact alarm scheduled for $prayerName (id:$notificationId) at $scheduledTime',
        );
        nativeScheduleSuccess = true;
      } else {
        debugPrint(
          '⚠️ Native exact alarm scheduling returned false for $prayerName - will use WorkManager as fallback',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to schedule native exact alarm for $prayerName: $e');
    }

    // Also schedule widget update at the same time (independent of notification success)
    try {
      final widgetUpdateId =
          notificationId + 10000; // Use different ID range for widget updates
      final widgetSuccess = await _scheduleWidgetUpdateAlarm(
        widgetUpdateId,
        scheduledTime,
        prayerName,
      );

      if (widgetSuccess) {
        debugPrint(
          '✅ Widget update alarm scheduled for $prayerName (id:$widgetUpdateId) at $scheduledTime',
        );
      } else {
        debugPrint('⚠️ Widget update alarm scheduling failed for $prayerName');
      }
    } catch (e) {
      debugPrint(
        '❌ Failed to schedule widget update alarm for $prayerName: $e',
      );
    }

    // FALLBACK: Use WorkManager if native alarms fail
    if (!nativeScheduleSuccess) {
      debugPrint('🔄 Using WorkManager as fallback for $prayerName');

      await Workmanager().registerOneOffTask(
        'prayer_${prayerName.toLowerCase()}_${daysFromNow}_${notificationId}',
        'showPrayerNotification',
        inputData: {
          'title': dynamicTitle,
          'body': dynamicBody,
          'channelId': config['channelId'],
          'scheduledAt': scheduledTime.toUtc().toIso8601String(),
        },
        initialDelay: Duration(seconds: delaySeconds),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresBatteryNotLow: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(seconds: 10),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      debugPrint('✅ WorkManager fallback scheduled for $prayerName');
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');

    // Call the static callback if set
    if (NotificationService.onNotificationTapped != null) {
      NotificationService.onNotificationTapped!();
    } else {
      debugPrint('⚠️ No navigation callback set for notification tap');
    }
  }

  // ============= PHASE 2: Auto-Reschedule =============

  /// Check if we need to reschedule
  /// Now checks if schedule expires within 2 days (7-day scheduling)
  Future<bool> shouldReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    final lastScheduledDate = prefs.getString('last_scheduled_date');
    final scheduleExpiresAt = prefs.getString('schedule_expires_at');

    // If never scheduled, need to reschedule
    if (lastScheduledDate == null) {
      debugPrint('🔄 Never scheduled before - rescheduling needed');
      return true;
    }

    // If no expiry date set (old version), need to reschedule
    if (scheduleExpiresAt == null) {
      debugPrint('🔄 No expiry date found - rescheduling needed');
      return true;
    }

    // Check if schedule expires within 2 days
    try {
      final expiryDate = DateFormat('yyyy-MM-dd').parse(scheduleExpiresAt);
      final now = DateTime.now();
      final daysUntilExpiry = expiryDate.difference(now).inDays;

      if (daysUntilExpiry <= 2) {
        debugPrint(
          '🔄 Schedule expires in $daysUntilExpiry days - rescheduling needed',
        );
        return true;
      }

      debugPrint(
        '✅ Schedule valid for $daysUntilExpiry more days - no reschedule needed',
      );
      return false;
    } catch (e) {
      debugPrint('❌ Error checking expiry date: $e - rescheduling to be safe');
      return true;
    }
  }

  /// Save last scheduled date
  Future<void> _saveScheduledDate() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('last_scheduled_date', today);
    debugPrint('💾 Saved scheduled date: $today');
  }

  /// Cache minimal prayer times (name + time) for background rescheduler
  Future<void> cachePrayerTimesMinimal(
    List<Map<String, dynamic>> prayerTimes,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, String>> simple =
          prayerTimes.map((p) {
            return {
              'name': p['name']?.toString() ?? '',
              'time': p['time']?.toString() ?? '',
            };
          }).toList();
      await prefs.setString('cached_prayer_times', jsonEncode(simple));
      debugPrint(
        '💾 Cached ${simple.length} prayer times for background reschedule',
      );
    } catch (e) {
      debugPrint('❌ Failed to cache prayer times: $e');
    }
  }

  /// Enhanced schedule with date tracking (WorkManager version)
  Future<void> schedulePrayerNotificationsWithTracking(
    List<Map<String, dynamic>> prayerTimes, {
    String? locationName,
  }) async {
    // Save location name if provided
    if (locationName != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_location_name', locationName);
      // Also save as last scheduled location to track changes
      await prefs.setString('last_scheduled_location', locationName);
      debugPrint('💾 Saved location name: $locationName');
    }

    // Schedule notifications using WorkManager
    await schedulePrayerNotificationsWorkManager(prayerTimes);

    // Save today's date
    await _saveScheduledDate();
  }

  /// NEW: Schedule 7 days of prayers with ACCURATE times for each day
  /// This receives prayer times for all 7 days with correct times per day
  Future<void> schedule7DaysPrayerNotifications(
    List<Map<String, dynamic>> allPrayerTimes, {
    String? locationName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Save location name if provided
    if (locationName != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_location_name', locationName);
      await prefs.setString('last_scheduled_location', locationName);
      debugPrint('💾 Saved location name: $locationName');
    }

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    debugPrint(
      '🔧 Scheduling 7-day prayer notifications with ACCURATE daily times',
    );

    // Cancel ALL existing alarms first to prevent duplicates
    try {
      await cancelAllNativeExactAlarms();
      await Workmanager().cancelAll();
      debugPrint('🗑️ Cancelled all existing alarms');
    } catch (e) {
      debugPrint('⚠️ Error cancelling existing alarms: $e');
    }

    int totalScheduled = 0;
    int totalSkipped = 0;

    // Group prayers by day
    Map<int, List<Map<String, dynamic>>> prayersByDay = {};
    for (var prayer in allPrayerTimes) {
      final dayOffset = prayer['dayOffset'] ?? 0;
      if (!prayersByDay.containsKey(dayOffset)) {
        prayersByDay[dayOffset] = [];
      }
      prayersByDay[dayOffset]!.add(prayer);
    }

    debugPrint('📊 Grouped prayers: ${prayersByDay.keys.length} days\n');

    // Schedule each day's prayers
    for (var dayOffset in prayersByDay.keys) {
      final dayPrayers = prayersByDay[dayOffset]!;
      final targetDate = now.add(Duration(days: dayOffset));
      final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

      debugPrint('📆 Scheduling day +$dayOffset ($dateStr):');
      int dayScheduled = 0;
      int daySkipped = 0;

      for (var prayer in dayPrayers) {
        final prayerName = prayer['name'];
        final timeString = prayer['time24'] ?? prayer['time'] ?? '--:--';

        // Skip Syuruk
        if (prayerName == 'Syuruk') {
          daySkipped++;
          continue;
        }

        // Skip invalid times
        if (timeString == '--:--' ||
            timeString.isEmpty ||
            !timeString.contains(':')) {
          debugPrint('  ⚠️ Skipping $prayerName (invalid time: $timeString)');
          daySkipped++;
          continue;
        }

        try {
          await _scheduleSinglePrayerWorkManager(
            prayerName,
            timeString,
            daysFromNow: dayOffset,
          );
          dayScheduled++;
          debugPrint('  ✓ $prayerName at $timeString');
        } catch (e) {
          debugPrint('  ❌ Failed to schedule $prayerName: $e');
          daySkipped++;
        }
      }

      debugPrint(
        '  ✅ Day complete: $dayScheduled scheduled, $daySkipped skipped\n',
      );
      totalScheduled += dayScheduled;
      totalSkipped += daySkipped;
    }

    debugPrint(
      '🎉 7-day accurate scheduling complete: $totalScheduled prayers scheduled, $totalSkipped skipped',
    );

    // Store the scheduled date and expiry
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_scheduled_date', today);
    final expiryDate = now.add(const Duration(days: 7));
    await prefs.setString(
      'schedule_expires_at',
      DateFormat('yyyy-MM-dd').format(expiryDate),
    );
    debugPrint(
      '💾 Schedule valid until: ${DateFormat('yyyy-MM-dd').format(expiryDate)}',
    );
  }

  /// Auto-reschedule if needed (call this on app start/resume)
  Future<bool> autoRescheduleIfNeeded(
    List<Map<String, dynamic>> prayerTimes, {
    String? locationName,
  }) async {
    if (await shouldReschedule()) {
      debugPrint('🔄 Auto-rescheduling notifications for new day...');
      await schedulePrayerNotificationsWithTracking(
        prayerTimes,
        locationName: locationName,
      );
      return true;
    }
    return false;
  }

  /// Get last scheduled date (for debugging)
  Future<String?> getLastScheduledDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_scheduled_date');
  }

  /// Get current location name from SharedPreferences
  Future<String?> _getCurrentLocationName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_location_name');
    } catch (e) {
      debugPrint('❌ Failed to get current location name: $e');
      return null;
    }
  }

  /// Force clear schedule and reschedule (for testing)
  Future<void> forceReschedule(
    List<Map<String, dynamic>> prayerTimes, {
    String? locationName,
  }) async {
    debugPrint('🔄 Force rescheduling notifications...');

    // Clear last scheduled date
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_scheduled_date');
    debugPrint('🗑️ Cleared last scheduled date');

    // Cancel all native exact alarms
    try {
      await cancelAllNativeExactAlarms();
      debugPrint('🗑️ Cancelled all native exact alarms');
    } catch (e) {
      debugPrint('⚠️ Failed to cancel native alarms: $e');
    }

    // Cancel all existing WorkManager tasks
    await Workmanager().cancelAll();
    debugPrint('🗑️ Cancelled all WorkManager tasks');

    // Save location if provided
    if (locationName != null) {
      await prefs.setString('current_location_name', locationName);
      await prefs.setString('last_scheduled_location', locationName);
      debugPrint('💾 Saved location name: $locationName');
    }

    // Reschedule
    await schedulePrayerNotificationsWithTracking(
      prayerTimes,
      locationName: locationName,
    );
    debugPrint('✅ Force reschedule complete');

    // Update widget with new prayer times
    try {
      await WidgetService.forceRefreshWidget();
      debugPrint('🔄 Widget updated after force reschedule');
    } catch (e) {
      debugPrint('⚠️ Failed to update widget after reschedule: $e');
    }
  }

  /// Get detailed schedule info (for debugging)
  Future<Map<String, dynamic>> getScheduleInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final lastScheduledDate = prefs.getString('last_scheduled_date');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return {
      'lastScheduledDate': lastScheduledDate,
      'today': today,
      'isScheduledForToday': lastScheduledDate == today,
      'needsReschedule':
          lastScheduledDate == null || lastScheduledDate != today,
    };
  }

  /// Update widget after notification is shown
  static Future<void> _updateWidgetAfterNotification(String title) async {
    try {
      // Extract prayer name from title (e.g., "Waktu Solat Subuh" -> "Subuh")
      final prayerName = _extractPrayerNameFromTitle(title);
      if (prayerName == null) return;

      // Get cached prayer times
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_prayer_times');
      if (cachedData == null) return;

      final List<dynamic> prayerTimes = jsonDecode(cachedData);
      if (prayerTimes.isEmpty) return;

      // Find the next prayer after the current one
      final prayerOrder = ['Subuh', 'Zohor', 'Asar', 'Maghrib', 'Isyak'];
      final currentIndex = prayerOrder.indexOf(prayerName);

      String nextPrayerName = 'Subuh';
      String nextPrayerTime = '--:--';
      String countdown = 'sedang berlaku';

      if (currentIndex >= 0 && currentIndex < prayerOrder.length - 1) {
        // Set next prayer to the following one
        nextPrayerName = prayerOrder[currentIndex + 1];

        // Find the time for the next prayer
        for (var prayer in prayerTimes) {
          if (prayer['name'] == nextPrayerName) {
            nextPrayerTime = prayer['time'] as String;
            break;
          }
        }

        // Calculate countdown to next prayer
        final nextPrayerDateTime = _parseTimeStringForWidget(nextPrayerTime);
        if (nextPrayerDateTime != null) {
          final now = DateTime.now();
          var targetTime = nextPrayerDateTime;

          // If next prayer time has passed today, it's for tomorrow
          if (targetTime.isBefore(now)) {
            targetTime = targetTime.add(const Duration(days: 1));
          }

          final difference = targetTime.difference(now);
          if (difference.inSeconds > 0) {
            final hours = difference.inHours;
            final minutes = difference.inMinutes % 60;
            countdown = 'dalam ${hours}j ${minutes}m';
          }
        }
      } else {
        // Last prayer of the day, next is Subuh tomorrow
        for (var prayer in prayerTimes) {
          if (prayer['name'] == 'Subuh') {
            nextPrayerTime = prayer['time'] as String;
            break;
          }
        }
        countdown = 'esok';
      }

      // Update widget data
      await HomeWidget.saveWidgetData('next_prayer_name', nextPrayerName);
      await HomeWidget.saveWidgetData('next_prayer_time', nextPrayerTime);
      await HomeWidget.saveWidgetData('countdown', countdown);

      // Update widget
      await HomeWidget.updateWidget(
        androidName: 'PrayerTimesWidgetProvider',
        iOSName: 'PrayerTimesWidgetProvider',
      );

      debugPrint(
        '✅ Widget updated after notification: next=$nextPrayerName at $nextPrayerTime ($countdown)',
      );
    } catch (e) {
      debugPrint('❌ Failed to update widget after notification: $e');
    }
  }

  /// Extract prayer name from notification title
  static String? _extractPrayerNameFromTitle(String title) {
    // Handle different title formats
    if (title.contains('Subuh')) return 'Subuh';
    if (title.contains('Zohor')) return 'Zohor';
    if (title.contains('Asar')) return 'Asar';
    if (title.contains('Maghrib')) return 'Maghrib';
    if (title.contains('Isyak')) return 'Isyak';
    return null;
  }

  /// Parse time string for widget updates (simplified version)
  static DateTime? _parseTimeStringForWidget(String timeStr) {
    try {
      final now = DateTime.now();
      timeStr = timeStr.trim();

      // Handle 12-hour format with AM/PM
      if (timeStr.contains('AM') || timeStr.contains('PM')) {
        final parts = timeStr.split(' ');
        if (parts.length == 2) {
          final timePart = parts[0];
          final period = parts[1].toUpperCase();
          final timeComponents = timePart.split(':');

          if (timeComponents.length == 2) {
            int hour = int.parse(timeComponents[0]);
            final minute = int.parse(timeComponents[1]);

            if (period == 'PM' && hour != 12) {
              hour += 12;
            } else if (period == 'AM' && hour == 12) {
              hour = 0;
            }

            return DateTime(now.year, now.month, now.day, hour, minute);
          }
        }
      } else {
        // 24-hour format
        final timeComponents = timeStr.split(':');
        if (timeComponents.length == 2) {
          final hour = int.parse(timeComponents[0]);
          final minute = int.parse(timeComponents[1]);
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

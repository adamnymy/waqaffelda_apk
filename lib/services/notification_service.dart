import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';

/// WorkManager callback dispatcher - must be a top-level function
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('🔔 WorkManager task started: $task');
      // If this is the daily rescheduler task, attempt to load cached prayer times
      // and re-register notifications from preferences.
      if (task == 'reschedulePrayers' || task == 'daily_rescheduler') {
        print('🔄 Background rescheduler triggered');
        await _scheduleFromCachedPrayerTimes();
        return Future.value(true);
      }

      // Get notification details from input data
      final title = inputData?['title'] ?? 'Prayer Time';
      final body = inputData?['body'] ?? 'It\'s time for prayer';
      final channelId = inputData?['channelId'] ?? 'prayer_default';

      print(
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
      print('✅ FlutterLocalNotificationsPlugin initialized in WorkManager');

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
          print(
            '⏱️ Notification executed for $title. Scheduled: $scheduledAtStr, Executed: ${executedAt.toIso8601String()}, Elapsed: ${elapsed}s',
          );
        } else {
          final executedAt = DateTime.now().toUtc();
          await prefs.setString(
            'executed_${keyBase}',
            executedAt.toIso8601String(),
          );
          print(
            '⏱️ Notification executed for $title. Executed: ${executedAt.toIso8601String()} (no scheduled timestamp)',
          );
        }
      } catch (e) {
        print('⚠️ Failed to persist execution timestamp: $e');
      }

      print('✅ WorkManager notification shown: $title (ID: $notificationId)');
      return Future.value(true); // Success
    } catch (e, stackTrace) {
      print('❌ WorkManager task failed: $e');
      print('Stack trace: $stackTrace');
      return Future.value(false); // Failure
    }
  });
}

/// Read cached prayer times from SharedPreferences and schedule WorkManager tasks.
@pragma('vm:entry-point')
Future<void> _scheduleFromCachedPrayerTimes() async {
  try {
    print('🔄 [BG] Starting background reschedule from cached prayer times');

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_prayer_times');
    if (cached == null) {
      print('❌ [BG] No cached prayer times found for background reschedule');
      return;
    }

    final List<dynamic> list = jsonDecode(cached);
    if (list.isEmpty) {
      print('❌ [BG] Cached prayer times list is empty');
      return;
    }

    print('📋 [BG] Found ${list.length} cached prayer times');

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
          print('⏭️ [BG] Skipping $prayerName (not a prayer time)');
          continue;
        }

        print('🕐 [BG] Processing $prayerName: $timeString');

        // Parse time string manually (can't use instance method in isolate)
        final parsedTime = _parseTimeStringStatic(timeString, tomorrow);
        if (parsedTime == null) {
          print('❌ [BG] Failed to parse time for $prayerName: $timeString');
          continue;
        }

        // Calculate delay from now
        final delaySeconds = parsedTime.difference(now).inSeconds;

        if (delaySeconds <= 0) {
          print(
            '⚠️ [BG] Skipping $prayerName - time already passed (delay: ${delaySeconds}s)',
          );
          continue;
        }

        print(
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
        print('❌ [BG] Error scheduling from cache: $e');
      }
    }

    // Update the last_scheduled_date to tomorrow's date
    final tomorrowDate = DateFormat('yyyy-MM-dd').format(tomorrow);
    await prefs.setString('last_scheduled_date', tomorrowDate);
    print('💾 [BG] Updated last_scheduled_date to: $tomorrowDate');

    print(
      '✅ [BG] Background reschedule complete - scheduled $scheduledCount prayers for tomorrow',
    );
  } catch (e) {
    print('❌ [BG] _scheduleFromCachedPrayerTimes failed: $e');
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
    print('❌ [BG] Error parsing time string "$timeStr": $e');
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

    // Daily rescheduler disabled - app will reschedule on next launch
    // Users should open app daily to ensure notifications are scheduled
    print('ℹ️ Daily auto-reschedule disabled - app will reschedule on launch');

    _isInitialized = true;
    print('✅ Notification service initialized');

    // Check if exact alarm scheduling is available (Android 12+). If not available,
    // automatically request the permission for precise notifications.
    try {
      final can = await canScheduleExactAlarms();
      if (!can) {
        print('⚠️ Exact alarm permission not granted - requesting now...');
        final granted = await requestExactAlarmPermission();
        if (granted) {
          print('✅ Exact alarm permission granted by user');
        } else {
          print(
            '⚠️ Exact alarm permission denied - notifications may not be precise',
          );
        }
      } else {
        print('✅ Exact alarm permission already granted');
      }
    } catch (e) {
      print('⚠️ Error checking/requesting exact alarm capability: $e');
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
      print('⚠️ canScheduleExactAlarms call failed: $e');
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
      print('⚠️ requestExactAlarmPermission call failed: $e');
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
      print('⚠️ openBatteryOptimizationSettings call failed: $e');
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
      print('⚠️ requestIgnoreBatteryOptimizations call failed: $e');
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
      print('⚠️ Failed to schedule native exact alarm: $e');
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
      print('⚠️ Failed to cancel native exact alarm: $e');
      return false;
    }
  }

  /// Cancel all native exact alarms
  Future<bool> cancelAllNativeExactAlarms() async {
    try {
      final res = await _exactAlarmChannel.invokeMethod('cancelAllExactAlarms');
      return res == true;
    } catch (e) {
      print('⚠️ Failed to cancel all native exact alarms: $e');
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
    print('✅ Notification channels created');
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

    print('📱 Permission granted: iOS: $iosGranted, Android: $androidGranted');
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

        print('✅ Parsed time "$timeStr" → ${result.toString()}');
        return result;
      }

      return null;
    } catch (e) {
      print('⚠️ Error parsing time "$timeStr": $e');
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
    print('💾 Saved: notification_$prayerName = $enabled');
  }

  /// Cancel all prayer notifications
  Future<void> cancelAllPrayerNotifications() async {
    for (var prayerName in prayerConfig.keys) {
      final id = _getNotificationId(prayerName);
      await _notifications.cancel(id);
    }
    print('🗑️ Cancelled all prayer notifications');
  }

  /// Cancel notification for a specific prayer
  Future<void> cancelPrayerNotification(String prayerName) async {
    final id = _getNotificationId(prayerName);
    await _notifications.cancel(id);
    print('🗑️ Cancelled notification for $prayerName');
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

    print('🔔 Test notification shown for $prayerName');
  }

  /// Schedule test notification using WorkManager (MIUI-compatible)
  Future<void> scheduleTestNotificationWorkManager() async {
    if (!_isInitialized) {
      await initialize();
    }

    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 10));

    print(
      '🔧 Scheduling WorkManager test notification for: ${scheduledTime.toString()}',
    );
    print('📱 You will receive WorkManager notification in ~10 seconds');

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

    print('✅ WorkManager task registered successfully');
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

    print('🔧 Scheduling prayer notifications with WorkManager for $today');

    // Cancel ALL existing alarms first to prevent duplicates
    try {
      await cancelAllNativeExactAlarms();
      await Workmanager().cancelAll();
      print('🗑️ Cancelled all existing alarms (native + WorkManager)');
    } catch (e) {
      print('⚠️ Error cancelling existing alarms: $e');
    }

    int successCount = 0;
    int skippedCount = 0;

    for (var prayer in prayerTimes) {
      final prayerName = prayer['name'] as String;
      // Use time24 if available, fallback to time (12-hour format)
      final prayerTimeString = (prayer['time24'] ?? prayer['time']) as String;

      print(
        '📋 Processing $prayerName: time24=${prayer['time24']}, time=${prayer['time']}, using=$prayerTimeString',
      );

      // Skip Syuruk as requested
      if (prayerName.toLowerCase() == 'syuruk') {
        skippedCount++;
        continue;
      }

      try {
        await _scheduleSinglePrayerWorkManager(prayerName, prayerTimeString);
        successCount++;
      } catch (e) {
        print('❌ Error scheduling $prayerName with WorkManager: $e');
      }
    }

    print(
      '✅ Scheduled $successCount prayers with WorkManager, skipped $skippedCount',
    );

    // Store the scheduled date
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_scheduled_date', today);
  }

  /// Schedule a single prayer notification using NATIVE EXACT ALARMS (primary)
  /// with WorkManager as backup for devices without exact alarm permission
  Future<void> _scheduleSinglePrayerWorkManager(
    String prayerName,
    String timeString,
  ) async {
    final config = prayerConfig[prayerName];
    if (config == null) {
      throw Exception('Unknown prayer: $prayerName');
    }

    final now = DateTime.now();
    final parsedTime = _parseTimeString(timeString);
    if (parsedTime == null) {
      print('❌ Failed to parse time string: $timeString for $prayerName');
      throw Exception('Invalid time string: $timeString');
    }

    var scheduledTime = parsedTime;

    // If the prayer time has already passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      print('⏰ $prayerName time has passed today, scheduling for tomorrow');
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final delaySeconds = scheduledTime.difference(now).inSeconds;
    final notificationId = _getNotificationId(prayerName);

    // Format time in 12-hour format for display
    final timeLabel12h = DateFormat(
      'h:mm a',
    ).format(scheduledTime); // e.g., "6:58 PM"
    final dynamicTitle = 'Waktu Solat $prayerName';
    final locationName = await _getCurrentLocationName();
    final locationText = locationName != null ? ' ($locationName)' : '';
    final dynamicBody =
        'Telah masuk waktu solat fardhu $prayerName pada $timeLabel12h $locationText';

    print(
      '🔧 Scheduling $prayerName (ID:$notificationId) for ${scheduledTime.toString()} (delay: ${delaySeconds}s / ${(delaySeconds / 3600).toStringAsFixed(1)}h)',
    );

    // PRIMARY METHOD: Use native AlarmManager.setExactAndAllowWhileIdle for ALL prayers
    bool nativeScheduleSuccess = false;
    try {
      final success = await _scheduleNativeExactAlarm(
        notificationId,
        scheduledTime,
        prayerName,
        dynamicTitle,
        dynamicBody,
        config['channelId'],
      );

      if (success) {
        print(
          '✅ Native exact alarm scheduled for $prayerName (id:$notificationId) at $scheduledTime',
        );
        nativeScheduleSuccess = true;
      } else {
        print(
          '⚠️ Native exact alarm scheduling returned false for $prayerName - will use WorkManager as fallback',
        );
      }
    } catch (e) {
      print('❌ Failed to schedule native exact alarm for $prayerName: $e');
    }

    // Only native alarms are used - no WorkManager fallback to prevent duplicates
    if (!nativeScheduleSuccess) {
      print(
        '⚠️ Failed to schedule $prayerName - native alarm scheduling failed. User may need to grant exact alarm permission.',
      );
      throw Exception('Native alarm scheduling failed for $prayerName');
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');

    // Call the static callback if set
    if (NotificationService.onNotificationTapped != null) {
      NotificationService.onNotificationTapped!();
    } else {
      print('⚠️ No navigation callback set for notification tap');
    }
  }

  // ============= PHASE 2: Auto-Reschedule =============

  /// Check if we need to reschedule (date has changed)
  Future<bool> shouldReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    final lastScheduledDate = prefs.getString('last_scheduled_date');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastScheduledDate == null || lastScheduledDate != today) {
      print('📅 Date changed or first time - need to reschedule');
      return true;
    }

    print('✅ Already scheduled for today');
    return false;
  }

  /// Save last scheduled date
  Future<void> _saveScheduledDate() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('last_scheduled_date', today);
    print('💾 Saved scheduled date: $today');
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
      print(
        '💾 Cached ${simple.length} prayer times for background reschedule',
      );
    } catch (e) {
      print('❌ Failed to cache prayer times: $e');
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
      print('💾 Saved location name: $locationName');
    }

    // Schedule notifications using WorkManager
    await schedulePrayerNotificationsWorkManager(prayerTimes);

    // Save today's date
    await _saveScheduledDate();
  }

  /// Auto-reschedule if needed (call this on app start/resume)
  Future<bool> autoRescheduleIfNeeded(
    List<Map<String, dynamic>> prayerTimes, {
    String? locationName,
  }) async {
    if (await shouldReschedule()) {
      print('🔄 Auto-rescheduling notifications for new day...');
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
      print('❌ Failed to get current location name: $e');
      return null;
    }
  }

  /// Force clear schedule and reschedule (for testing)
  Future<void> forceReschedule(
    List<Map<String, dynamic>> prayerTimes, {
    String? locationName,
  }) async {
    print('🔄 Force rescheduling notifications...');

    // Clear last scheduled date
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_scheduled_date');
    print('🗑️ Cleared last scheduled date');

    // Cancel all native exact alarms
    try {
      await cancelAllNativeExactAlarms();
      print('🗑️ Cancelled all native exact alarms');
    } catch (e) {
      print('⚠️ Failed to cancel native alarms: $e');
    }

    // Cancel all existing WorkManager tasks
    await Workmanager().cancelAll();
    print('🗑️ Cancelled all WorkManager tasks');

    // Reschedule
    await schedulePrayerNotificationsWithTracking(
      prayerTimes,
      locationName: locationName,
    );
    print('✅ Force reschedule complete');
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
}

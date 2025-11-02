import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
    },
    'Zohor': {
      'color': 0xFFFFC107, // Yellow - matahari tengahari
      'icon': '@mipmap/ic_launcher',
      'channelId': 'prayer_zohor',
      'channelName': 'Waktu Zohor',
    },
    'Asar': {
      'color': 0xFFFF9800, // Orange - petang
      'icon': '@mipmap/ic_launcher',
      'channelId': 'prayer_asar',
      'channelName': 'Waktu Asar',
    },
    'Maghrib': {
      'color': 0xFFFF5722, // Deep Orange - senja
      'icon': '@mipmap/ic_launcher',
      'channelId': 'prayer_maghrib',
      'channelName': 'Waktu Maghrib',
    },
    'Isyak': {
      'color': 0xFF3F51B5, // Indigo - malam
      'icon': '@mipmap/ic_launcher',
      'channelId': 'prayer_isyak',
      'channelName': 'Waktu Isyak',
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

    _isInitialized = true;
    print('✅ Notification service initialized');
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

  /// Schedule notifications for all prayer times
  Future<void> schedulePrayerNotifications(
    List<Map<String, dynamic>> prayerTimes,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Cancel all existing prayer notifications
    await cancelAllPrayerNotifications();

    int successCount = 0;
    int skippedCount = 0;

    for (var prayer in prayerTimes) {
      final prayerName = prayer['name'] as String;
      final prayerTime = prayer['time'] as String;

      // Skip Syuruk - only 5 waktu
      if (prayerName == 'Syuruk') {
        skippedCount++;
        continue;
      }

      // Check if notification is enabled for this prayer
      final isEnabled = await _isNotificationEnabled(prayerName);
      if (!isEnabled) {
        print('⏭️ Skipped $prayerName - disabled by user');
        skippedCount++;
        continue;
      }

      try {
        await _scheduleSinglePrayer(prayerName, prayerTime);
        successCount++;
      } catch (e) {
        print('❌ Error scheduling $prayerName: $e');
      }
    }

    print('✅ Scheduled $successCount prayers, skipped $skippedCount');
  }

  /// Schedule notification for a single prayer time
  Future<void> _scheduleSinglePrayer(
    String prayerName,
    String prayerTime,
  ) async {
    final config = prayerConfig[prayerName];
    if (config == null) {
      print('⚠️ No config found for $prayerName');
      return;
    }

    // Parse prayer time (format: "HH:MM AM/PM")
    final scheduledTime = _parseTimeString(prayerTime);
    if (scheduledTime == null) {
      print('⚠️ Invalid time format for $prayerName: $prayerTime');
      return;
    }

    // Skip if time has already passed today
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledTime.isBefore(now)) {
      print('⏭️ Skipped $prayerName - time already passed');
      return;
    }

    // Generate unique notification ID based on prayer name
    final notificationId = _getNotificationId(prayerName);

    // Notification details
    final androidDetails = AndroidNotificationDetails(
      config['channelId'],
      config['channelName'],
      channelDescription: 'Notifikasi untuk ${config['channelName']}',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        'Waktu solat $prayerName telah masuk ($prayerTime)',
        htmlFormatBigText: true,
        contentTitle: 'Waktu $prayerName',
        htmlFormatContentTitle: true,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification
    await _notifications.zonedSchedule(
      notificationId,
      'Waktu $prayerName',
      'Waktu solat $prayerName telah masuk ($prayerTime)',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('🔔 Scheduled: $prayerName at ${scheduledTime.toString()}');
  }

  /// Parse time string to TZDateTime (handles 12-hour format with AM/PM)
  tz.TZDateTime? _parseTimeString(String timeStr) {
    try {
      final now = tz.TZDateTime.now(tz.local);

      // Remove any extra spaces
      timeStr = timeStr.trim();

      // Parse format: "HH:MM AM/PM" or "H:MM AM/PM"
      final parts = timeStr.split(' ');
      if (parts.length != 2) return null;

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

  /// Check if notification is enabled for a specific prayer
  Future<bool> _isNotificationEnabled(String prayerName) async {
    final prefs = await SharedPreferences.getInstance();
    // Default: all prayers enabled
    return prefs.getBool('notification_$prayerName') ?? true;
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

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    // TODO: Navigate to prayer times page or specific prayer details
  }
}

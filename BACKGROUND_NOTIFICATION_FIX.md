# Background Notification Reschedule Fix

## Problem Identified

The background worker (`daily_rescheduler`) was running successfully (as shown in logs), but notifications were **not being scheduled for the next day**. Users had to manually open the app to trigger the reschedule.

### Root Causes

1. **Instance Method in Static Context**: The background worker tried to call `NotificationService().parseTimeString()` which doesn't work properly in the WorkManager isolate
2. **Wrong Date Reference**: The worker was using TODAY's cached prayer times and trying to schedule them, but they had already passed
3. **Missing Date Update**: After successful background reschedule, the `last_scheduled_date` was not being updated, causing the system to think reschedule was still needed
4. **No Syuruk Filtering**: Syuruk (sunrise) is not a prayer time but was being scheduled

## Solution Implemented

### 1. Created Static Time Parser
```dart
DateTime? _parseTimeStringStatic(String timeStr, DateTime baseDate)
```
- Works in background isolate (no instance dependencies)
- Handles both 12-hour (AM/PM) and 24-hour formats
- Uses provided base date (tomorrow) for proper scheduling

### 2. Schedule for Tomorrow
```dart
final tomorrow = now.add(const Duration(days: 1));
final parsedTime = _parseTimeStringStatic(timeString, tomorrow);
```
- Background worker now explicitly schedules for TOMORROW
- Properly handles the date transition

### 3. Update Scheduled Date
```dart
final tomorrowDate = DateFormat('yyyy-MM-dd').format(tomorrow);
await prefs.setString('last_scheduled_date', tomorrowDate);
```
- After successful reschedule, update the tracking date to tomorrow
- Prevents duplicate scheduling attempts

### 4. Filter Syuruk
```dart
if (prayerName == 'Syuruk') {
  print('⏭️ [BG] Skipping $prayerName (not a prayer time)');
  continue;
}
```
- Only schedule actual prayer times (Subuh, Zohor, Asar, Maghrib, Isyak)

### 5. Enhanced Logging
Added comprehensive logging to track:
- Number of cached prayer times found
- Each prayer being processed
- Scheduled times with delays in both seconds and hours
- Final count of successfully scheduled prayers
- Date updates

## Expected Behavior

### Before Fix
```
09/11/2025 20:10:11
Task: daily_rescheduler
Result: ✅ (but no notifications scheduled)
Next day: ❌ No notifications (need to open app)
```

### After Fix
```
09/11/2025 20:10:11
Task: daily_rescheduler
Result: ✅
Processing: Subuh, Zohor, Asar, Maghrib, Isyak
Scheduled: 5 prayers for 10/11/2025
Updated: last_scheduled_date = 2025-11-10
Next day: ✅ Notifications fire automatically!
```

## Testing Instructions

1. **Install the updated app**
2. **Open Prayer Times page** to ensure notifications are scheduled
3. **Wait for background worker** (runs every 24 hours, or manually trigger using WorkManager)
4. **Check logs** for:
   ```
   🔄 [BG] Starting background reschedule from cached prayer times
   📋 [BG] Found 6 cached prayer times
   ✅ [BG] Scheduling Subuh for 2025-11-10 05:45:00
   ✅ [BG] Background reschedule complete - scheduled 5 prayers for tomorrow
   💾 [BG] Updated last_scheduled_date to: 2025-11-10
   ```
5. **Next day**: Verify notifications appear without opening the app

## Key Improvements

✅ **No app opening required** - Background worker handles everything  
✅ **Proper date handling** - Schedules for tomorrow, not today  
✅ **Static parsing** - Works reliably in background isolate  
✅ **Date tracking** - Prevents duplicate schedules  
✅ **Better logging** - Easy to debug and verify  
✅ **Syuruk filtering** - Only prayer times get notifications  

## Files Modified

- `lib/services/notification_service.dart`
  - Fixed `_scheduleFromCachedPrayerTimes()` function
  - Added `_parseTimeStringStatic()` static helper
  - Enhanced logging throughout background worker
  - Added date update after successful reschedule

## Notes

- The WorkManager periodic task runs every 24 hours
- Initial delay is 1 hour after app initialization
- Cached prayer times are saved whenever prayer times are loaded in the app
- The system is resilient - if background fails, app opening will still reschedule

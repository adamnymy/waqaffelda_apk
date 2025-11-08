# Notification Diagnostic Steps

Since notifications aren't showing up, let's diagnose the issue step by step.

## Step 1: Check App Logs

When you run the app with `flutter run`, look for these messages in the console:

### Expected on App Start:
```
🔔 Initializing notification service...
✅ Notification service initialized
✅ Exact alarm permission already granted (or request dialog)
✅ Notification permission granted
```

### Expected when loading prayer times:
```
🔔 Starting notification scheduling process...
📋 Prayer times to schedule: Subuh: 06:00, Zohor: 13:05, ...
🆕 First time scheduling notifications (or 🔄 Checking if reschedule is needed)
🔧 Scheduling prayer notifications with WorkManager for 2025-11-07
📋 Processing Subuh: time24=06:00, time=6:00 AM, using=06:00
🔧 Scheduling Subuh (ID:1001) for 2025-11-07 06:00:00.000 (delay: XXXs / X.Xh)
✅ Native exact alarm scheduled for Subuh (id:1001) at 2025-11-07 06:00:00
```

## Step 2: What to Check in Logs

**If you see:**
- ❌ `Failed to parse time string` → Time parsing issue
- ⚠️ `Exact alarm permission not granted` → Permission issue
- ⚠️ `Cannot schedule exact alarm - permission not granted` → Need to grant permission
- ❌ `Error scheduling` → Scheduling failed

**If you DON'T see:**
- Missing `✅ Native exact alarm scheduled` → Alarms not being registered
- Missing `🔔 Starting notification scheduling process` → Scheduling not triggered

## Step 3: Manual Permission Check

Go to Android Settings:
1. **Settings → Apps → Waqaf FELDA**
2. Check **Notifications** → Should be ON
3. Check **Special app access** (or "Additional settings")
4. Find **Alarms & reminders** → Should be ALLOWED
5. Check **Battery** → Should be "Unrestricted" or "Optimized" (NOT "Restricted")

## Step 4: Check if Prayer Times Loaded

In the app, verify:
- Prayer times are showing (Subuh, Zohor, Asar, Maghrib, Isyak)
- Times are correct for your location
- Location is detected correctly

## Step 5: Test with Immediate Notification

Can you add this temporary test button to see if notifications work at all?

Add to `prayertimes.dart` temporarily (in the actions of AppBar):

```dart
IconButton(
  icon: const Icon(Icons.notifications_active, color: Colors.white),
  onPressed: () async {
    try {
      final service = NotificationService();
      await service.showTestNotification('Zohor');
      print('✅ Test notification triggered');
    } catch (e) {
      print('❌ Test notification failed: $e');
    }
  },
),
```

This will show an immediate test notification when you tap it.

## Step 6: Common Issues

### Issue 1: Time24 field is null
**Symptom:** Logs show `time24=null`
**Fix:** Prayer times service not providing time24

### Issue 2: Exact alarm permission not granted
**Symptom:** Logs show "Cannot schedule exact alarms"
**Fix:** Manually go to Settings → Apps → Waqaf FELDA → Special access → Alarms & reminders → Allow

### Issue 3: Notifications permission denied
**Symptom:** No permission request dialog appears
**Fix:** Manually enable in Settings → Apps → Waqaf FELDA → Notifications

### Issue 4: Alarms scheduled but not firing
**Symptom:** Logs show "✅ Native exact alarm scheduled" but notification never appears
**Possible causes:**
- Battery optimization is restricting the app
- Device manufacturer's battery saver killing alarms
- Wrong timezone

## Step 7: Share Debug Info

Please share the following from your Flutter console:

1. **Initialization logs** (when app starts)
2. **Scheduling logs** (when prayer times load)
3. **Any error messages**

Look for anything with these emojis: 🔔 ✅ ❌ ⚠️ 📋 🔧

## Quick Debug Commands

If you have Android Studio or VS Code with Flutter extension:

**View Flutter logs:**
- VS Code: DEBUG CONSOLE tab
- Android Studio: Run/Logcat tab

**Filter for important logs:**
Look for lines containing:
- "NotificationService"
- "Scheduling"
- "prayer"
- Emoji indicators (🔔 ✅ ❌)

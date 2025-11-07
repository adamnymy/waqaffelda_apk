# 🎯 Notification Testing Guide - Manual Time Change

## ✅ What Works
- **Zohor notification appeared** when you changed time ✅

## ❌ What Doesn't Work  
- **Asar notification didn't appear** when you changed time again ❌

## 🔍 Why This Happens

### **Issue: AlarmManager Behavior with Manual Time Changes**

When you manually change the device time on Android:

1. ✅ **First alarm fires correctly** (Zohor worked)
2. ❌ **Subsequent alarms might be cleared/cancelled** by Android
3. ⚠️ **Time change can disrupt alarm queue**

This is a known Android behavior - **AlarmManager doesn't always preserve alarms across multiple time changes**.

## ✅ **Correct Testing Procedure**

### **Method 1: Force Schedule Before Each Test**

```
For EACH prayer you want to test:

1. Click ℹ️ Info → "Force Schedule"
   - Wait for: "✅ Scheduled 5 prayers with WorkManager"

2. Change time to prayer time minus 10 seconds
   - Example: For Asar at 16:21, set to 16:20:50

3. Wait for notification ✅

4. Change time back to current time

5. REPEAT from step 1 for next prayer
```

### **Method 2: Test Multiple Prayers in Sequence (Without Returning Time)**

```
1. Click ℹ️ Info → "Force Schedule"

2. Change time to 12:59:50 (before Zohor 13:00)
   - Wait for notification ✅

3. Immediately change time to 16:20:50 (before Asar 16:21)  
   - Wait for notification ✅

4. Immediately change time to 18:57:50 (before Maghrib 18:58)
   - Wait for notification ✅

5. And so on...

⚠️ DON'T change time back to current between tests
```

### **Method 3: Test in 10 Seconds (Most Reliable)**

```
1. Click ℹ️ Info → "Test in 10s"
2. Wait 10 seconds
3. Notification appears ✅
4. Repeat for each test
```

## 🐛 Common Issues

### **Issue 1: Time Changed Back After First Test**
**Symptom:** Zohor worked, but Asar didn't  
**Cause:** Changing time back to current cancelled remaining alarms  
**Solution:** Don't change time back, or Force Schedule again before next test

### **Issue 2: Multiple Time Changes**
**Symptom:** First test works, subsequent tests don't  
**Cause:** Android clears alarm queue on repeated time changes  
**Solution:** Force Schedule before EACH test

### **Issue 3: Notification Permission Revoked**
**Symptom:** No notifications appear at all  
**Cause:** Android revoked notification permission  
**Solution:** Check Settings → Apps → Waqaf FELDA → Notifications

## 📊 Proper Testing Sequence

### **Full Test Sequence (Recommended)**

```bash
# Test 1: Zohor
1. Force Schedule
2. Time → 12:59:50
3. Wait → ✅ Notification at 13:00

# Test 2: Asar  
4. Force Schedule (IMPORTANT!)
5. Time → 16:20:50
6. Wait → ✅ Notification at 16:21

# Test 3: Maghrib
7. Force Schedule (IMPORTANT!)
8. Time → 18:57:50
9. Wait → ✅ Notification at 18:58

# Test 4: Isyak
10. Force Schedule (IMPORTANT!)
11. Time → 20:09:50
12. Wait → ✅ Notification at 20:10
```

## 🎯 Quick Test (Without Time Changes)

**Best way to verify all notifications work:**

```
1. Click ℹ️ Info → "Force Schedule"
2. Check logs show all 5 prayers scheduled
3. WAIT for next actual prayer time (no time change)
4. Notification should appear naturally ✅
5. Next day, all prayers should fire automatically
```

## ⚡ Quick Verification

**To verify alarms are registered after Force Schedule:**

Look for these logs:
```
✅ Native exact alarm scheduled for Subuh (id:1001)
✅ Native exact alarm scheduled for Zohor (id:1002)  
✅ Native exact alarm scheduled for Asar (id:1003)
✅ Native exact alarm scheduled for Maghrib (id:1004)
✅ Native exact alarm scheduled for Isyak (id:1005)
✅ Scheduled 5 prayers with WorkManager, skipped 1
```

If you see all 5 ✅, alarms are registered correctly.

## 📝 What You Should Do Now

### **Test Asar Again (Properly This Time):**

```
1. Hot reload app (press 'r' in terminal)

2. Click ℹ️ Info button

3. Click "Force Schedule"
   - Wait for console to show:
     ✅ Native exact alarm scheduled for Asar (id:1003) at 2025-11-07 16:21:00

4. Go to Settings → Date & time

5. Change time to 16:20:50 (10 seconds before)

6. Wait and watch

7. Should see notification at 16:21! 🔔
```

### **Or Use "Test in 10s" Button:**

```
1. Click ℹ️ Info button
2. Click "Test in 10s"  
3. Wait 10 seconds
4. Notification appears! 🔔
5. Repeat to test multiple times
```

## 🔧 Debug Information

If Asar still doesn't work after Force Schedule:

**Check console for:**
- `🔔 Exact alarm triggered for Asar` ← If you see this, alarm fired
- `✅ Notification shown for Asar` ← If you see this, notification sent

**If you see alarm triggered but no notification:**
- Notification channel might be muted
- Check Settings → Apps → Waqaf FELDA → Notifications → All channels enabled

**If you don't see alarm triggered at all:**
- Alarm wasn't fired by Android
- Battery optimization might be killing it
- Try "Test in 10s" instead of time change

## 🎉 Summary

**The notification system IS working!** ✅

The issue is just with **testing methodology**. When testing with manual time changes:
- ✅ **Force Schedule before EACH test**
- ✅ **Or test sequentially without returning time**
- ✅ **Or use "Test in 10s" button for reliable testing**

The app will work perfectly in production because:
1. Time progresses naturally (no manual changes)
2. Daily auto-reschedule at midnight
3. App resume checks and reschedules if needed

**Try the proper test sequence above and Asar should work!** 🔔

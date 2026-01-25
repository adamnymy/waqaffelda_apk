# Notification Sound Integration

## Overview
This document explains how the notification sound mode system works in the Waqafer prayer times app.

## Components Modified

### 1. NotificationService (`lib/services/notification_service.dart`)

#### Channel Creation (`createNotificationChannels()`)
- **Purpose**: Creates Android notification channels based on user's sound mode preference
- **Sound Modes**:
  - **Azan**: Plays custom azan audio from `res/raw/azan.mp3`
  - **Beep**: Uses default system notification sound
  - **Vibrate**: Vibration only, no sound
  - **Silent**: No sound or vibration, visual notification only

- **Implementation**: For each prayer time (Subuh, Zohor, Asar, Maghrib, Isyak), creates a channel with the format: `{baseChannelId}_{soundMode}`
  - Example: `prayer_subuh_azan`, `prayer_zohor_beep`, etc.

#### Notification Scheduling (`_scheduleFromCachedPrayerTimes()`)
- Reads user's `notification_sound_mode` from SharedPreferences
- Appends the sound mode suffix to the base channelId
- Passes the complete channelId (e.g., `prayer_subuh_azan`) to WorkManager

#### WorkManager Callback
- Receives the channelId with sound mode suffix
- Uses the correct channel when displaying the notification
- The channel's sound/vibration settings are automatically applied by Android

### 2. Notification Settings Page (`lib/pages/settings/notification_settings_page.dart`)

#### Sound Mode Selection
- Provides UI with 4 options: Azan, Beep, Vibrate, Silent
- Saves selection to SharedPreferences with key: `notification_sound_mode`
- When mode changes:
  1. Saves new mode to SharedPreferences
  2. Recreates notification channels with new settings
  3. Shows confirmation snackbar

### 3. Prayer Times Page (`lib/pages/prayertimes/prayertimes.dart`)
- Displays sound icon on each prayer card
- Clicking the icon navigates to NotificationSettingsPage
- Users can change sound mode from prayer times screen

## Audio File Setup

### Location
- **Source**: `assets/audio/azan.mp3` (77KB)
- **Android Resource**: `android/app/src/main/res/raw/azan.mp3`

### Usage
- Referenced in channel creation as: `RawResourceAndroidNotificationSound('azan')`
- Android automatically plays this audio when notification fires on "Azan" mode

## How It Works - User Flow

1. **User Changes Sound Mode**:
   - Opens Settings → Notification Settings
   - Selects desired mode (Azan/Beep/Vibrate/Silent)
   - Setting saved to SharedPreferences
   - Channels recreated with new sound configuration

2. **Prayer Time Notification**:
   - WorkManager triggers at scheduled time
   - Reads channelId from input data (includes sound mode suffix)
   - Creates notification using mode-specific channel
   - Android applies channel's sound/vibration settings automatically

3. **Background Rescheduling**:
   - Daily background task reads current sound mode
   - Schedules 7 days of prayers with correct channelIds
   - Each prayer uses the user's current preference

## Technical Notes

### Android Notification Channels
- Once created, channels are cached by Android system
- Changing channel settings requires recreating the channel
- Each sound mode uses a separate channel to avoid conflicts
- Total channels: 5 prayers × 4 modes = 20 channels (+ 1 test channel)

### SharedPreferences Keys
- `notification_sound_mode`: Current sound mode (azan/beep/vibrate/silent)
- Default value: `'beep'` if not set

### Channel Naming Convention
```
Format: {prayer}_{mode}
Examples:
- prayer_subuh_azan
- prayer_zohor_beep
- prayer_asar_vibrate
- prayer_maghrib_silent
```

## Testing

### Verify Integration
1. Change sound mode in settings
2. Check debug logs for: "Creating notification channels with mode: {mode}"
3. Trigger a test notification
4. Verify correct sound plays based on selected mode

### Debug Logs
- `🔔 Creating notification channels with mode:` - Channel creation started
- `✅ Created channel:` - Individual channel created successfully
- `🔄 Recreating notification channels for mode:` - Settings changed, recreating

## Future Enhancements
- Allow custom azan audio selection
- Per-prayer sound customization
- Volume control for azan playback
- Preview sound before saving

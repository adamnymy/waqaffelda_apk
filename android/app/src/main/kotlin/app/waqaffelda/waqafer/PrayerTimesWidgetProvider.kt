package app.waqaffelda.waqafer

// Wrapper provider to satisfy HomeWidget / other callers that expect the
// AppWidgetProvider to live under the `app.waqaffelda.waqafer` package.
// Delegates functionality to the actual implementation in
// `com.example.waqaffelda_apk.PrayerTimesWidgetProvider`.

class PrayerTimesWidgetProvider : com.example.waqaffelda_apk.PrayerTimesWidgetProvider()

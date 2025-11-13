# Masjid Terdekat Setup Guide

## ✅ What's Been Created

A modern, user-friendly "Masjid Terdekat" (Nearest Mosque) page with:

### Features:
- 🗺️ **Dual View**: Toggle between List View and Map View
- 📍 **Location-Based**: Auto-detects user location
- 🔍 **Radius Search**: Filter mosques by distance (2km, 5km, 10km, 20km)
- ⭐ **Ratings**: Shows Google ratings for each mosque
- 🕌 **Status**: Shows if mosque is open or closed
- 🧭 **Navigation**: Direct Google Maps navigation
- 🎨 **Modern UI**: Clean pink-themed design matching your app

### Design Highlights:
- Material Design 3 principles
- Smooth animations and interactions
- Responsive layout
- Accessible and intuitive

## 🔧 Setup Required

### 1. Install Dependencies
Run this command in your terminal:
```bash
flutter pub get
```

### 2. Get Google Maps API Key (REQUIRED!)

**Step-by-Step Guide:**

#### A. Create/Get API Key:
1. Go to: https://console.cloud.google.com/
2. Create a new project (or select existing)
3. Go to "APIs & Services" → "Credentials"
4. Click "Create Credentials" → "API Key"
5. Copy your API key

#### B. Enable Required APIs:
In Google Cloud Console, enable these APIs:
- ✅ **Places API** (REQUIRED for mosque search)
- ✅ **Maps SDK for Android** (for Android map display)
- ✅ **Maps SDK for iOS** (for iOS map display)
- ✅ **Geocoding API** (recommended)

**Enable APIs here:** https://console.cloud.google.com/apis/library

#### C. Restrict API Key (Recommended):
1. Go to API Key settings
2. Under "Application restrictions": Select "Android apps" or "iOS apps"
3. Add your package name: `com.example.Waqafer` (or your actual package name)
4. Under "API restrictions": Select "Restrict key" and choose the APIs above

### 3. Configure API Key in Your App

#### Step 1: In the Code (masjid_terdekat.dart)
Find line ~97 and replace with your actual API key:
```dart
const String apiKey = 'AIzaSy...YOUR_ACTUAL_KEY_HERE';
```

#### Step 2: For Android (AndroidManifest.xml)
Add to `android/app/src/main/AndroidManifest.xml` (inside `<application>` tag):
```xml
<application>
    ...
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="AIzaSy...YOUR_ACTUAL_KEY_HERE"/>
</application>
```

#### Step 3: For iOS (AppDelegate.swift)
Add to `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import GoogleMaps  // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Add this line with your API key
    GMSServices.provideAPIKey("AIzaSy...YOUR_ACTUAL_KEY_HERE")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 4. Update Navigation

Add the page to your navigation/navbar. Example:
```dart
import 'package:Waqafer/pages/masjid_terdekat/masjid_terdekat.dart';

// In your navigation:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const MasjidTerdekatPage()),
);
```

## 📱 How It Works

### User Flow:
1. User opens "Masjid Terdekat"
2. App requests location permission
3. App searches for mosques within selected radius (default 5km)
4. Results shown in list or map view
5. User can:
   - View mosque details
   - Get directions via Google Maps
   - Change search radius
   - Toggle between list/map view

### Data Retrieved:
- Mosque name
- Distance from user
- Address
- Google rating
- Open/Closed status
- GPS coordinates

## 🎨 Current Design (Design #1)

**Style:** Clean & Minimal Card-Based Layout

**Features:**
- Mosque cards with icon, name, distance, rating
- Floating action button for location refresh
- Bottom sheet for mosque details
- Direct navigation buttons
- List/Map toggle

**Color Scheme:**
- Primary Pink: #F59AC6
- Light Pink: #F9C4DD
- Accent: Pink gradients

## 📝 Notes for CEO

This is **Design Option #1** - a modern, functional implementation.

**Advantages:**
- Clean and professional
- Easy to use
- Fast and responsive
- Familiar UI patterns

**Next Steps:**
- Test with real API key
- Get feedback
- Request 2 more design variations if needed

## 🐛 Troubleshooting

### ❌ "REQUEST_DENIED" Error
**This is the most common error!**

**Causes:**
- API key not configured (still using placeholder)
- Places API not enabled in Google Cloud Console
- API key restrictions blocking the request
- Billing not enabled on Google Cloud (required for Places API)

**Solutions:**
1. ✅ Replace `'YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE'` in code with real API key
2. ✅ Enable **Places API** at: https://console.cloud.google.com/apis/library/places-backend.googleapis.com
3. ✅ Enable billing on your Google Cloud project (Places API requires billing)
4. ✅ Check API key restrictions aren't too strict
5. ✅ Wait 5-10 minutes after enabling APIs for changes to propagate

### ❌ "OVER_QUERY_LIMIT" Error
- You've exceeded free tier limit (check Google Cloud Console)
- Wait for quota reset or upgrade billing plan

### ❌ No mosques found?
- Check internet connection
- Verify API key is working (check error message)
- Try increasing search radius (2km → 5km → 10km)
- Try different location (some areas have fewer registered mosques)

### ❌ Map not showing?
- Verify Google Maps SDK for Android/iOS is enabled
- Check API key in AndroidManifest.xml matches the one in code
- Run `flutter clean` and rebuild

### ❌ Location permission denied?
- App will show error with retry button
- User must enable location in device settings
- On Android: Settings → Apps → Waqafer → Permissions → Location
- On iOS: Settings → Privacy → Location Services → Waqafer

### 💡 Testing API Key
Test your API key with this URL in browser (replace with your key and coordinates):
```
https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=3.139,101.687&radius=5000&type=mosque&key=YOUR_API_KEY
```
Should return JSON with mosque data, not an error.

## 📞 Support

If you need the other 2 design variations, just let me know and I'll create them!

# Waqafer - Muslim Prayer Companion App

<div align="center">
  <img src="assets/images/app_icon.png" alt="Waqafer Logo" width="120" height="120">

  # 🕌 Waqafer

  **Your Complete Muslim Prayer Companion**

  test

  *Accurate Prayer Times • Qiblah Direction • Nearby Mosques • Islamic Content*

  [![Flutter](https://img.shields.io/badge/Flutter-3.7.2-blue.svg)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.7.2-blue.svg)](https://dart.dev/)
  [![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://play.google.com/store)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## 📱 Features

### 🕐 **Prayer Times**
- **Accurate prayer times** from JAKIM e-solat.gov.my API
- **Real-time countdown** to next prayer
- **Prayer notifications** with customizable alerts
- **Background service** for reliable notifications

### 🧭 **Qiblah Compass**
- **Precise Qiblah direction** using device sensors
- **Interactive compass** with Kaaba indicator
- **Location-based accuracy** for better precision

### 🕌 **Nearby Mosques**
- **Google Maps integration** for mosque discovery
- **Location-based search** with radius control
- **Interactive map** with navigation options
- **Mosque details** and directions

### 📖 **Islamic Content**
- **Complete Quran** with Arabic text and translations
- **40 Hadith Nawawi** - essential prophetic traditions
- **Daily Prayers (Doa Harian)** - comprehensive collection
- **Tahlil & Yasin** - remembrance and recitation
- **Islamic Calendar** with Hijri dates

### 🧮 **Tasbih Counter**
- **Digital tasbih** for dhikr counting
- **Multiple counters** for different prayers
- **Persistent storage** of counts

### 🎨 **Beautiful UI**
- **Modern Material Design** with Islamic aesthetics
- **Dark/Light theme** support
- **Smooth animations** and transitions
- **Arabic & Malay** language support

---

## 🚀 Installation

### From Google Play Store (Beta)
1. Join our [beta testing program](https://play.google.com/store/apps/tester)
2. Download and install the app
3. Grant necessary permissions for location and notifications

### From GitHub Releases
1. Go to [Releases](https://github.com/adamnymy/waqafer/releases)   
2. Download the latest `waqafer-1.0.2-beta+3.apk`
3. Install on your Android device
4. Enable "Install from unknown sources" if prompted

### Build from Source
```bash
# Clone the repository
git clone https://github.com/adamnymy/waqafer.git
cd waqafer

# Install dependencies
flutter pub get

# Build APK
flutter build apk --release

# Build App Bundle (AAB)
flutter build appbundle --release
```

---

## 📋 Requirements

- **Android**: 5.0 (API level 21) or higher
- **Internet connection** for prayer times and maps
- **Location permission** for Qiblah and mosque finder
- **Notification permission** for prayer alerts

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.7.2
- **Language**: Dart 3.7.2
- **State Management**: Provider pattern
- **Maps**: Google Maps Flutter
- **Prayer Times**: JAKIM e-solat.gov.my API
- **Notifications**: Flutter Local Notifications
- **Storage**: Shared Preferences
- **Icons**: Custom SVG icons

### Key Dependencies
- `google_maps_flutter` - Maps integration
- `flutter_compass` - Qiblah direction
- `geolocator` - Location services
- `flutter_local_notifications` - Prayer alerts
- `quran` - Quran content
- `adhan_dart` - Prayer calculations
- `hijri` - Islamic calendar

---

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry point
├── navbar.dart              # Bottom navigation
├── splash_screen.dart       # Splash screen
├── auth/                    # Authentication (future)
├── models/                  # Data models
├── pages/                   # App screens
│   ├── homepage/           # Main dashboard
│   ├── prayertimes/        # Prayer times page
│   ├── kiblat/             # Qiblah compass
│   ├── masjid_terdekat/    # Nearby mosques
│   ├── quran/              # Quran reader
│   ├── hadis40/            # Hadith collection
│   ├── doaharian/          # Daily prayers
│   ├── tahlil/             # Tahlil & Yasin
│   ├── program/            # Islamic programs
│   ├── inbox/              # Notifications
│   ├── akaun/              # Account/Profile
│   ├── setting/            # Settings
│   └── zikircounter/       # Tasbih counter
├── services/                # Business logic
│   ├── prayer_times_service.dart
│   ├── notification_service.dart
│   ├── quran_service.dart
│   └── location_service.dart
├── utils/                   # Utilities
├── widgets/                 # Reusable components
└── data/                    # Static data
```

---

## 🔧 Configuration

### Google Maps Setup
1. Get API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY"/>
   ```
3. Restrict API key to your app's SHA-1 fingerprint

### App Signing
1. Create production keystore:
   ```bash
   keytool -genkey -v -keystore waqafer-production-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias waqafer
   ```
2. Update `android/key.properties` with keystore details
3. Build signed release: `flutter build appbundle --release`

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### Development Setup
```bash
# Clone and setup
git clone https://github.com/adamnymy/waqafer.git
cd waqafer
flutter pub get

# Run analysis
flutter analyze

# Run tests
flutter test

# Build debug APK
flutter build apk --debug
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **JAKIM** for providing accurate prayer times API
- **Google Maps** for mosque location services
- **Flutter Community** for amazing packages
- **Islamic content** sourced from authentic references

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/adamnymy/waqafer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/adamnymy/waqafer/discussions)
- **Email**: adamhjumain@gmail.com

---

<div align="center">

NICE

</div> 

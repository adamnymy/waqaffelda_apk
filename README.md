# Waqafer - Muslim Prayer Companion App

<div align="center">
  <img src="assets/icons/Logo_QAF.png" alt="Waqafer Logo" width="120" height="120">

  # 🕌 Waqafer

  **Your Complete Muslim Prayer Companion**

  *Accurate Prayer Times • Qiblah Direction • Nearby Mosques • Islamic Content*

  [![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-blue.svg)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.7.2+-blue.svg)](https://dart.dev/)
  [![Version](https://img.shields.io/badge/Version-1.2.0-brightgreen.svg)](https://github.com/adamnymy/waqafer/releases)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg)](https://flutter.dev/)
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

### 💰 **Waqf & Donations**
- **Waqf programs** - contribute to Islamic causes
- **Donation tracking** and receipt management
- **Trusted partner integration** for secure donations

### 📅 **Programs & Events**
- **Islamic programs** and event listings
- **Community activities** and schedules
- **Program reminders** and notifications

### 🏪 **Islamic Store**
- **Browse Islamic products** and merchandise
- **Integrated shopping** experience
- **Support Islamic businesses**

### 🧮 **Tasbih Counter**
- **Digital tasbih** for dhikr counting
- **Multiple counters** for different prayers
- **Persistent storage** of counts

### 🎨 **Beautiful UI**
- **Modern Material Design** with Islamic aesthetics
- **Dark/Light theme** support
- **Smooth animations** and transitions
- **Arabic & Malay** language support
- **Custom Inter font** for better readability
- **Home screen widgets** for quick prayer time access

---

## 🚀 Installation

### From Google Play Store (Beta)
1. Join our [beta testing program](https://play.google.com/store/apps/tester)
2. Download and install the app
3. Grant necessary permissions for location and notifications

### From GitHub Releases
1. Go to [Releases](https://github.com/adamnymy/waqafer/releases)   
2. Download the latest `waqafer-1.2.0+6.apk`
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
- **iOS**: iOS 11.0 or higher (planned)
- **Internet connection** for prayer times, maps, and content updates
- **Location permission** for Qiblah direction and nearby mosque finder
- **Notification permission** for prayer time alerts
- **Background service permission** for reliable prayer notifications
- **Storage permission** for caching Quran and Islamic content

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.7.2+
- **Language**: Dart 3.7.2+
- **State Management**: Provider pattern
- **Maps**: Google Maps Flutter & Flutter Map (OSM)
- **Prayer Times**: JAKIM e-solat.gov.my API & Adhan calculations
- **Notifications**: Flutter Local Notifications with background service
- **Storage**: Shared Preferences
- **Icons**: Custom SVG icons
- **Widgets**: Home screen widgets support

### Key Dependencies
- `google_maps_flutter: ^2.5.0` - Maps integration
- `flutter_map: ^6.1.0` - OpenStreetMap support
- `flutter_compass: ^0.8.0` - Qiblah direction
- `geolocator: ^10.1.0` - Location services
- `flutter_local_notifications: ^17.2.3` - Prayer alerts
- `quran: ^1.3.3` - Quran content
- `adhan_dart: ^1.1.2` - Prayer time calculations
- `hijri: ^3.0.0` - Islamic calendar
- `workmanager: ^0.6.0` - Background tasks
- `home_widget: ^0.6.0` - Home screen widgets
- `webview_flutter: ^4.13.0` - In-app web content
- `share_plus: ^12.0.1` - Content sharing
- `url_launcher: ^6.2.1` - External links

---

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry point
├── navbar.dart              # Bottom navigation
├── splash_screen.dart       # Splash screen
├── auth/                    # Authentication
│   └── login_page.dart     # Login screen
├── models/                  # Data models
│   ├── quran_models.dart   # Quran data structures
│   └── tahlil_model.dart   # Tahlil/Yasin models
├── pages/                   # App screens
│   ├── homepage/           # Main dashboard
│   ├── prayertimes/        # Prayer times page
│   ├── kiblat/             # Qiblah compass
│   ├── masjid_terdekat/    # Nearby mosques
│   ├── quran/              # Quran reader
│   ├── hadis40/            # 40 Hadith Nawawi
│   ├── doaharian/          # Daily prayers (Doa)
│   ├── tahlil/             # Tahlil & Yasin
│   ├── program/            # Islamic programs & events
│   ├── waqaf/              # Waqf donations
│   ├── kedai/              # Store/Shop
│   ├── kalendar/           # Islamic calendar
│   ├── akaun/              # Account/Profile
│   ├── settings/           # App settings
│   └── zikircounter/       # Digital tasbih counter
├── services/                # Business logic
│   ├── prayer_times_service.dart
│   ├── notification_service.dart
│   ├── quran_service.dart
│   ├── tahlil_service.dart
│   └── widget_service.dart  # Home widget service
├── utils/                   # Utilities
│   └── page_transitions.dart
├── widgets/                 # Reusable components
│   └── google_maps_location_picker.dart
└── assets/                  # Static assets
    ├── data/               # JSON data files
    ├── icons/              # SVG icons
    ├── images/             # Images
    ├── fonts/              # Custom fonts (Inter)
    ├── audio/              # Audio files
    └── quran/              # Quran metadata
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

**Made with ❤️ for the Muslim Community**

*May Allah accept this effort and make it beneficial for all*

---

**Version 1.2.0+6** | Updated February 2026

</div> 

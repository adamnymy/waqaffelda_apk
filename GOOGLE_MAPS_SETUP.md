# Google Maps Setup Guide for Waqaf FELDA App

## Step 1: Create Google Cloud Project

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Sign in with your Google account

2. **Create a New Project**
   - Click "Select a project" dropdown at the top
   - Click "New Project"
   - Enter project name: `Waqaf FELDA App`
   - Click "Create"

## Step 2: Enable Required APIs

1. **Navigate to APIs & Services**
   - In the left sidebar, click "APIs & Services" > "Library"

2. **Enable Maps SDK for Android**
   - Search for "Maps SDK for Android"
   - Click on it and press "Enable"

3. **Enable Geocoding API**
   - Search for "Geocoding API"
   - Click on it and press "Enable"

## Step 3: Create API Key

1. **Go to Credentials**
   - In the left sidebar, click "APIs & Services" > "Credentials"

2. **Create API Key**
   - Click "+ CREATE CREDENTIALS"
   - Select "API key"
   - Copy the generated API key (save it somewhere safe!)

3. **Restrict API Key (Recommended)**
   - Click "Restrict Key" or edit the key
   - Under "Application restrictions":
     - Select "Android apps"
     - Click "Add an item"
     - Package name: `com.example.waqaffelda_apk`
     - SHA-1 certificate fingerprint: (see Step 4 below)
   - Under "API restrictions":
     - Select "Restrict key"
     - Choose: "Maps SDK for Android" and "Geocoding API"
   - Click "Save"

## Step 4: Get SHA-1 Fingerprint (For Production)

### For Debug/Development:
```bash
cd android
./gradlew signingReport
```
Look for the SHA1 fingerprint under "Variant: debug"

### For Release:
You'll need your release keystore SHA-1 fingerprint.

## Step 5: Configure Android App

1. **Update AndroidManifest.xml**
   - Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key
   - File location: `android/app/src/main/AndroidManifest.xml`

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

## Step 6: Test the Integration

1. **Run the app**
   ```bash
   flutter run
   ```

2. **Test Google Maps**
   - Navigate to Prayer Times page
   - Tap the location icon
   - Select "Pick from Map"
   - Verify the map loads and you can select locations

## Troubleshooting

### Common Issues:

1. **Map shows gray screen**
   - Check if API key is correct
   - Ensure Maps SDK for Android is enabled
   - Verify package name matches in restrictions

2. **"This app isn't authorized to use Google Maps"**
   - Check SHA-1 fingerprint is correct
   - Verify package name in API restrictions

3. **Geocoding not working**
   - Ensure Geocoding API is enabled
   - Check API key has Geocoding API access

### Debug Commands:
```bash
# Check package name
flutter run --verbose

# Get debug SHA-1
cd android && ./gradlew signingReport

# Clean and rebuild
flutter clean && flutter pub get && flutter run
```

## Cost Information

- **Maps SDK for Android**: $7 per 1,000 map loads (first 28,000 free monthly)
- **Geocoding API**: $5 per 1,000 requests (first 40,000 free monthly)

For a typical prayer app usage, you should stay within free limits.

## Security Best Practices

1. **Restrict API Key**: Always restrict by package name and SHA-1
2. **Monitor Usage**: Check Google Cloud Console for API usage
3. **Set Quotas**: Set daily quotas to prevent unexpected charges
4. **Environment Variables**: Consider using environment variables for API keys in production

---

**Next Steps After Setup:**
1. Replace the API key in AndroidManifest.xml
2. Run `flutter pub get`
3. Test the Google Maps location picker
4. Verify prayer times update with selected locations

# Build Instructions — ValoCheck

## Prerequisites
- **Flutter SDK**: `^3.11.5`
- **Dart SDK**: `^3.11.5`
- **Android Studio / Xcode**: Platform build tools and SDK components
- **Java**: JDK 17+
- **System Requirements**: Windows / macOS / Linux with 8GB+ RAM

---

## Build Steps

### 1. Install Dependencies
```bash
cd mobile
flutter pub get
```

### 2. Run Static Analysis & Verification
```bash
flutter analyze
```

### 3. Run Unit and Widget Tests
```bash
flutter test
```

### 4. Build Android Release Artifacts
```bash
# App Bundle for Google Play Store upload (.aab)
flutter build appbundle --release

# Direct Install APK (.apk)
flutter build apk --release
```

### 5. Build iOS Release Artifacts (macOS only)
```bash
flutter build ipa --release
```

---

## Signing Configuration

1. For Android release builds with production keys:
   - Generate keystore: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
   - Configure `mobile/android/key.properties` with keystore password and path.
2. For local debugging:
   - Fallback debug signing runs automatically when `key.properties` is absent.

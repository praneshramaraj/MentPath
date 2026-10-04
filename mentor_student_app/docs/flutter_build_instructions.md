# Flutter Mobile Application Build & Testing Instructions

This document provides step-by-step instructions to analyze, unit test, build, and package the Flutter mobile application (`mobile/`) for Android and iOS devices.

---

## 🛠 Prerequisites

* **Flutter SDK:** 3.19.0 or higher
* **Dart SDK:** 3.3.0 or higher
* **Android Studio:** Android SDK 34, Build-Tools 34.0.0
* **Xcode:** 15.0+ (Required for iOS builds on macOS)
* **CocoaPods:** 1.14.0+ (For iOS native dependencies)

---

## 🚀 Development Mode Execution

Navigate to the `mobile/` directory:

```bash
cd mobile
flutter pub get
```

### Run on Connected Device / Simulator
```bash
# List available target devices
flutter devices

# Run in debug mode
flutter run

# Run on specific target
flutter run -d chrome            # Web
flutter run -d macos             # macOS Desktop
flutter run -d <emulator_id>     # Android/iOS Emulator
```

---

## 🧪 Quality Assurance & Static Verification

Before packaging release builds, always execute static code analysis and the test suite:

### 1. Static Analysis
```bash
flutter analyze
```
*Expected Result:* `No issues found!`

### 2. Unit & Widget Test Suite
```bash
flutter test
```
*Expected Result:* `All tests passed!`

---

## 🤖 Android Production Build Instructions

### Step 1: Generate Release Keystore (If not existing)
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload -storepass YourStorePassword -keypass YourKeyPassword
```

### Step 2: Configure `android/key.properties`
Create `android/key.properties` with the credentials:
```properties
storePassword=YourStorePassword
keyPassword=YourKeyPassword
keyAlias=upload
storeFile=upload-keystore.jks
```

### Step 3: Build APK / App Bundle

#### A. Build Split Release APKs (For direct distribution / testing)
```bash
flutter build apk --release --split-per-abi
```
Outputs are generated in: `mobile/build/app/outputs/flutter-apk/`
- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`

#### B. Build Android App Bundle (AAB for Google Play Store)
```bash
flutter build appbundle --release
```
Output location: `mobile/build/app/outputs/bundle/release/app-release.aab`

---

## 🍎 iOS Production Build Instructions (macOS Only)

### Step 1: Configure Signing in Xcode
1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Under **Runner Target > Signing & Capabilities**:
   - Select your **Development Team**.
   - Ensure **Bundle Identifier** matches your Apple Developer portal entry (e.g. `edu.college.mentorapp`).

### Step 2: Export Production IPA
```bash
flutter build ipa --release
```
Output location: `mobile/build/ios/archive/Runner.xcarchive` and `mobile/build/ios/ipa/`

---

## 📱 UI & Screen Size Responsiveness Verification

The app UI is constructed with adaptive Material 3 widgets:

1. **Responsive Layout Grid:** `LayoutBuilder` and `MediaQuery` dynamically adapt padding and multi-column display across small phones (320px width), standard phones, and tablets (768px+).
2. **Loading States:** `CircularProgressIndicator` centered overlays are displayed during async backend transactions.
3. **Empty States:** When database records (marks, attendance, leave requests, achievements, notes) are absent, custom `EmptyStateWidget` renders with explicit helpful microcopy.
4. **Error & Network Failure States:** Network timeout / offline failures trigger user-friendly Snackbar notifications with a "Retry" CTA button.

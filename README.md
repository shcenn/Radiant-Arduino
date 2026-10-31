# Radiant

Flutter dashboard for the Uno + ESP8266 streetlight prototype.
Firebase project: radiant-3bc0d. Supported targets: Android and web.

## Run on this computer

The Firebase packages have been resolved in this checkout. From this directory:

```powershell
flutter run -d chrome --no-pub
```

For an Android phone with USB debugging enabled:

```powershell
flutter devices
flutter run -d YOUR_ANDROID_DEVICE_ID --no-pub
```

The Android client is registered as com.example.radiant. Public client options
are in lib/firebase_options.dart; no device or dashboard passwords are in app
source. Initialization uses explicit FirebaseOptions, so google-services.json
is not required for the current Auth/Realtime Database integration. Other
Firebase services may require additional native configuration later.

## Dashboard access

The read-only dashboard UID has been filled into the prepared database rules:
qe7EC6hwUNQe4IF2E8zlU9GzEjs1. Publish radiant-dashboard.rules.json from the
Codex outputs in Realtime Database -> Rules. The device's existing write UID
is unchanged. Sign in using the dashboard account's email and password.
No passwords are embedded in the app, and the Flutter app never writes telemetry.

## Data and behavior

- Listens at gateways/uno-01/latest for the version 1 snapshot.
- Supports one to four physical pairs; list IDs match array indices plus one.
- Shows darkness, PIR state, commanded LED state and observation age.
- Reporting means recent telemetry, not proof of bulb health.
- Marks readings offline after 30 seconds without a fresh source observation.
- Uses Firebase server-time offset so a phone clock error does not make old
  readings appear current. App disconnects are also indicated.
- Detail pages keep updating while open, and identify stale values as last
  reported states. Invalid snapshots show an error instead of invented values.
- Energy and bulb health are explicitly shown as not measured.
- Sign-out tears down subscriptions; dark mode remains an in-session preference.
- The Streetlights tab is a live list, not a geographic map.
- Earlier sample alerts and nonfunctional notification/refresh switches are no
  longer displayed as if they represented working hardware features.

## Dependencies and checks

Firebase Core 5.1.0, Auth 7.0.1 and Realtime Database 13.0.1 are locked in
pubspec.lock. Existing platform folders are preserved, but iOS/macOS/Windows
Firebase configuration has not been added.

```powershell
flutter analyze
flutter test --no-pub
```

Windows may ask for Developer Mode when pub get creates desktop plugin links.
That is a local tooling requirement, not a Firebase permission. The --no-pub
commands above use the already resolved dependencies for Android/web. On a
fresh checkout, run flutter pub get first and follow Flutter's system setup
instructions if it requests symlink support.

To run on another computer, fetch dependencies there; package cache paths in
.dart_tool are generated local files and must not be committed.

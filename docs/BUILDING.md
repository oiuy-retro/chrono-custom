# Building Chrono Custom

## Requirements

- Flutter 3.22.2 (the version upstream uses in its CI)
- JDK 17
- Android SDK with platform 34 and build tools (Gradle downloads missing parts if the licenses are accepted)

Set `JAVA_HOME` to the JDK 17 folder and `ANDROID_HOME` to the SDK folder.

## Check the code

```
flutter pub get
flutter analyze
flutter test
```

`flutter analyze` shows many info and warning messages from upstream code and two errors in an unused upstream file (`lib/settings/screens/list_filter_settings_screen.dart`). No other errors should appear.

## Screenshots

To render the redesigned screens to PNG files:

```
FLUTTER_ROOT=/path/to/flutter flutter test --update-goldens test/screenshots
```

The files are written to `test/screenshots/goldens/`, which is not committed.

## Debug build

```
flutter build apk --debug --flavor prod
```

## Release signing

Use a dedicated key for this app. Do not use the Android debug key and do not reuse a key from another app.

1. Create a keystore outside the repository:

   ```
   keytool -genkeypair -keystore /secure/path/chrono-custom-release.jks \
     -alias chrono-custom -keyalg RSA -keysize 4096 -validity 10000
   chmod 600 /secure/path/chrono-custom-release.jks
   ```

2. Copy `android/keystore.properties.example` to a private location, fill in the keystore path, alias and passwords, and run `chmod 600` on it. The file names `keystore.properties` and `android/keystore.properties` are in `.gitignore`.

3. Build:

   ```
   CHRONO_KEYSTORE_PROPERTIES=/secure/path/keystore.properties \
     flutter build apk --release --flavor prod
   ```

   If the variable is not set, the build looks for `android/keystore.properties`. If neither exists, the release APK is unsigned.

4. Check the signature and checksum:

   ```
   apksigner verify --print-certs build/app/outputs/flutter-apk/app-prod-release.apk
   sha256sum build/app/outputs/flutter-apk/app-prod-release.apk
   ```

Keep the keystore and its passwords backed up. Updates to an installed app must be signed with the same key.

## Output

`build/app/outputs/flutter-apk/app-prod-release.apk`. Built files are never committed to git; they are attached to GitHub Releases together with a `SHA256SUMS` file.

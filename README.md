# Chrono Custom

An Android alarm, world clock, stopwatch and timer app with a redesigned interface that mixes the look of Samsung Clock (One UI) and Apple Clock (iOS).

> This is an unofficial custom build based on [Chrono](https://github.com/vicolo-dev/chrono) by [Vicolo and its contributors](https://github.com/vicolo-dev/chrono/graphs/contributors), licensed under the [GNU General Public License v3.0](LICENSE). It is not affiliated with or supported by the Chrono developers. Please do not report problems with this build to the upstream project. For a plain description of the original app, see [docs/ABOUT_CHRONO.md](docs/ABOUT_CHRONO.md).

- Upstream base: `vicolo-dev/chrono` branch `master`, commit `9e30f243271a27e79573e2b2d3da10159419eb8e` (four commits after tag `v0.6.0`)
- App version: `0.6.0-custom.1`, versionCode `29`
- Application ID: `com.oiuyretro.chrono` (upstream is `com.vicolo.chrono`)
- Build flavor: `prod`, release build type
- Change history: [CHANGELOG.md](CHANGELOG.md)

## What's different from upstream

All upstream features and settings are kept. The changes are to layout and navigation. Details are in [docs/CUSTOM_CHANGES.md](docs/CUSTOM_CHANGES.md).

### 1. Large collapsing headers

Each tab has a large title at the top. On the Alarm tab it also shows how long until the next alarm (for example "Alarm in 8 hours 12 minutes") or "All alarms are off". On the Clock tab it shows today's date. When you scroll the list, the header shrinks to a normal toolbar.

### 2. Bottom navigation

The tabs are in the order Alarm, Clock, Stopwatch, Timer, and every tab always shows its label.

### 3. Alarm list

Each alarm shows a large time, then its label and schedule, with the on/off switch on the right. The menu next to the switch still has Skip, Duplicate and Delete.

### 4. Add and edit alarm screen

Tapping the add button opens the alarm screen straight away, with a large scroll-wheel time picker at the top. Below it, the settings are grouped into plain sections: Label, Repeat, Sound, Vibration, Snooze and Dismiss task. Less common options (random melody start position, volume while doing a task, snooze rules, tags) are in a collapsed Advanced section. Any alarm setting that is not placed in a named section is added to Advanced automatically, so no setting is hidden.

### 5. Alarm reliability setup

A setup screen lists every system setting that can stop alarms from ringing, each with a green check or a red "Needs fixing" status and a Fix button. One "Fix all" button opens the unmet ones in order, and the status is re-checked each time you return to the app. On Samsung phones the screen is called "Set up for Samsung" and adds two items that Android cannot check (battery usage set to Unrestricted, and Never sleeping apps); you open them from the screen and tick Done yourself. The screen opens by itself on first launch, a warning banner appears on the Alarm tab while any item is not OK, and it is always available under Settings, General, Reliability.

New installs also have the foreground notification and the background service turned on by default, which help keep alarms scheduled. Existing saved settings are not changed.

### 6. Installs alongside the official app

The application ID is `com.oiuyretro.chrono` and the app is named "Chrono Custom", so it can be installed next to the official Chrono. The two apps do not share alarms or settings.

## Install

1. Download the APK and the `SHA256SUMS` file from the [Releases page](https://github.com/oiuy-retro/chrono-custom/releases).
2. Check the file: `sha256sum -c SHA256SUMS`
3. Open the APK on your phone and allow installing from this source when Android asks.

## Run

Open "Chrono Custom" from the app drawer. After the first-start screens the alarm reliability setup opens. Tap "Fix all" and allow each setting it opens. On a Samsung phone, also follow the two "Check manually" items and tick Done. The setup can be opened again from Settings, General, Reliability.

## Building from source

Short version (full steps in [docs/BUILDING.md](docs/BUILDING.md)):

1. Install Flutter 3.22.2, JDK 17 and the Android SDK (platform 34).
2. `flutter pub get`
3. `flutter analyze` and `flutter test`
4. Create a release keystore and a `keystore.properties` file outside the repository, using [android/keystore.properties.example](android/keystore.properties.example) as the template.
5. `CHRONO_KEYSTORE_PROPERTIES=/path/to/keystore.properties flutter build apk --release --flavor prod`

Without a `keystore.properties` file the release APK is built unsigned. The debug key is never used for release builds.

## Known limitations

- Only the English text for the new labels (Repeat, Advanced, Dismiss task, the header lines) exists. Other languages show these few labels in English until they are translated. All other text uses the existing translations.
- The scroll-wheel picker replaces the add-alarm time dialog. The "Time picker" style setting still applies to the other time dialogs in the app.
- Screens other than the alarm list and alarm editor (timer, stopwatch, clock, settings) keep their upstream layout apart from the new header and navigation bar.
- Samsung's own battery settings (Unrestricted battery usage, Never sleeping apps, Put unused apps to sleep) cannot be read or changed by an app. The setup screen opens the right Samsung screen where possible (falling back to App info or Android's battery settings) and relies on you to tick Done.
- The foreground notification that is now on by default stays in the notification shade. It can be turned off in Settings, General, Reliability.
- `flutter analyze` reports two errors in `lib/settings/screens/list_filter_settings_screen.dart`. They come from upstream; the file is not used by the app and the build is not affected.
- The Android build uses a newer D8/R8 than the one bundled with Android Gradle Plugin 7.4.2, because the bundled one fails on current AndroidX libraries. See [docs/CUSTOM_CHANGES.md](docs/CUSTOM_CHANGES.md).

## Staying in sync with upstream

This repository keeps the upstream history. `origin` is this fork and `upstream` is `vicolo-dev/chrono`. Steps for pulling in new upstream versions are in [docs/UPDATING_FROM_UPSTREAM.md](docs/UPDATING_FROM_UPSTREAM.md).

## More documentation

- [CHANGELOG.md](CHANGELOG.md)
- [docs/BUILDING.md](docs/BUILDING.md)
- [docs/CUSTOM_CHANGES.md](docs/CUSTOM_CHANGES.md)
- [docs/UPDATING_FROM_UPSTREAM.md](docs/UPDATING_FROM_UPSTREAM.md)
- [docs/ABOUT_CHRONO.md](docs/ABOUT_CHRONO.md)

## License and credits

Chrono Custom is licensed under the [GNU General Public License v3.0](LICENSE), the same license as upstream. The original app, its features and nearly all of its code are the work of the [Chrono developers and contributors](https://github.com/vicolo-dev/chrono/graphs/contributors). Translations come from the [Chrono Weblate project](https://hosted.weblate.org/projects/chrono/). The scroll-wheel time picker is adapted from [flutter_time_picker_spinner](https://github.com/icemanbsi/flutter_time_picker_spinner) (BSD license, notice kept in the source file), as it already was upstream.

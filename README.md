# Chrono Custom

An Android alarm, world clock, stopwatch and timer app with an interface redesigned to look and feel like Samsung Clock (One UI), including Samsung-style vibration feedback.

> This is an unofficial custom build based on [Chrono](https://github.com/vicolo-dev/chrono) by [Vicolo and its contributors](https://github.com/vicolo-dev/chrono/graphs/contributors), licensed under the [GNU General Public License v3.0](LICENSE). It is not affiliated with or supported by the Chrono developers. Please do not report problems with this build to the upstream project. For a plain description of the original app, see [docs/ABOUT_CHRONO.md](docs/ABOUT_CHRONO.md).

- Upstream base: `vicolo-dev/chrono` branch `master`, commit `9e30f243271a27e79573e2b2d3da10159419eb8e` (four commits after tag `v0.6.0`)
- App version: `0.6.0-custom.1`, versionCode `32`
- Application ID: `com.oiuyretro.chrono` (upstream is `com.vicolo.chrono`)
- Build flavor: `prod`, release build type
- Change history: [CHANGELOG.md](CHANGELOG.md)

## What's different from upstream

All upstream features and settings are kept, and saved alarms and backups still work. The changes are to layout, navigation and touch feedback. Details are in [docs/CUSTOM_CHANGES.md](docs/CUSTOM_CHANGES.md).

### 1. Samsung-style headers and tabs

Each tab opens with a large centred title that takes up about the top third of the screen, as in Samsung Clock. On the Alarm tab it also shows how long until the next alarm (for example "Alarm in 8 hours 12 minutes") or "All alarms are off". On the Clock tab it shows today's date. When you scroll, the title shrinks into a normal toolbar. The tabs (Alarm, Clock, Stopwatch, Timer) sit in a rounded bar at the bottom, with the current tab highlighted. On new installs, swiping left or right switches tabs. The Material navigation bar is still available under the "Use Material Style" setting.

### 2. Alarm list

Alarms are always listed by time of day, earliest first, as in Samsung Clock. The order updates by itself when you add or change an alarm. The other orders (time remaining, name, latest first, or "Default", the order you added them in) are still in the Sort button above the list. Existing installs that were on upstream's "Default" order are switched to time of day once; a different order you had picked is kept. Turning off "Show Sort" in the alarm settings only hides the button; the list stays sorted.

Each alarm is a rounded card showing the label, a large time with a smaller AM/PM, and the repeat days as the letters S M T W T F S with the active days in blue. One-time alarms show their date instead. The on/off switch is on the right and the menu next to it still has Skip, Duplicate and Delete. Press and hold an alarm to enter select mode: round check boxes appear, the add button hides, and a bar at the bottom offers All, Delete and Cancel.

### 3. Add and edit alarm screen

Tapping the add button opens the alarm screen straight away. At the top is a scroll-wheel time picker with an AM/PM wheel. Below it, in rounded cards: the repeat summary with a calendar button for other repeat types (dates, ranges, intervals), the day buttons S M T W T F S, and an Alarm name field; then rows for Alarm sound, Vibration and Snooze, each with a short summary and a switch where it applies (tap a row for its full settings); then the dismiss task. Every other alarm setting is in a collapsed Advanced section, so nothing was removed. Cancel and Save are at the bottom of the screen.

Two sound switches sit under Alarm sound. "Start at random point" (on for new alarms) starts the sound somewhere in the middle instead of at the beginning, never in the last 15 seconds or last 20%. "Also ring on phone speaker" (off by default) plays the alarm on the phone's own speaker as well as on connected Bluetooth headphones or a Bluetooth speaker.

### 4. Stopwatch, timer and world clock

The stopwatch shows large digits in the Samsung format (00:00.00) with wide round buttons at the bottom: Start, then Lap and Stop, then Reset and Resume. Each timer shows a circular progress ring with the time inside and round play/pause and reset buttons. World clock cities show the city name and time in larger type.

### 5. Vibration feedback

Like Samsung Clock, the app gives a short vibration when you turn the time wheels, flip a switch, tap a day button, press and hold to select, switch tabs, press stopwatch and timer buttons, add an alarm, or swipe to delete. It follows Android's "Touch feedback" setting, and it can be turned off in the app under Settings, Accessibility, Vibration feedback (on by default).

### 6. One UI colours and dark mode

The first item in Settings is Theme, with System default, Light and Dark. System default (the default) follows the phone's dark mode, so the app turns dark when you switch on dark mode in the phone's quick settings. Dark mode uses the "One UI Dark" colours: a black background with dark grey cards, white text and a light blue accent. Light mode uses "One UI": a light grey background, white cards and a blue accent.

Theme works the same with and without Material You (Settings, Appearance, Colors). With Material You the cards are given a slightly lighter shade than the page so they stay visible. Other colour schemes can still be picked under Settings, Appearance, Colors, Color Scheme and Dark Color Scheme.

On existing installs, the dark colours are set to One UI Dark once, unless you had turned on the old "System Dark Mode" switch and picked your own dark scheme. The old "System Dark Mode" and "Brightness" switches are gone from the screen (Theme replaces them) but are still read from backups.

### 7. Alarm reliability setup

A setup screen lists every system setting that can stop alarms from ringing, each with a green check or a red "Needs fixing" status and a Fix button. One "Fix all" button opens the unmet ones in order, and the status is re-checked each time you return to the app. On Samsung phones the screen is called "Set up for Samsung" and adds two items that Android cannot check (battery usage set to Unrestricted, and Never sleeping apps); you open them from the screen and tick Done yourself. The screen opens by itself on first launch, a warning banner appears on the Alarm tab while any item is not OK, and it is always available under Settings, General, Reliability.

New installs also have the foreground notification and the background service turned on by default, which help keep alarms scheduled. Existing saved settings are not changed.

### 8. Installs alongside the official app

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

- Only English text exists for the new labels (for example Repeat, Advanced, Alarm sound, Select all, the stopwatch buttons and the header lines). Other languages show these labels in English until they are translated. All other text uses the existing translations.
- The scroll-wheel picker replaces the add-alarm time dialog. The "Time picker" style setting still applies to the other time dialogs in the app.
- The settings screens keep their upstream layout.
- The app uses its existing Rubik font, not Samsung's own font.
- The new light colours and the swipe-to-switch-tabs default only apply to new installs. Dark mode and the time-of-day order also apply to existing installs, as described above.
- "Also ring on phone speaker" has not been tried on a real phone yet. It needs Android 6 or newer, and only Android 9 and newer can force the second copy onto the speaker. See docs/CUSTOM_CHANGES.md for details.
- Home screen widgets keep the colour chosen in the widget settings and do not switch with dark mode.
- The splash screen shown while the app starts uses Android's plain black or white background.
- Vibration feedback only works if Android's touch feedback is on and the phone has a vibration motor.
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

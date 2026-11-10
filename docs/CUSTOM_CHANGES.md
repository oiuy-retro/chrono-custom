# Custom changes

This file lists every change compared with upstream Chrono, with the files involved.

## Interface

### Large collapsing header
- New `lib/navigation/widgets/large_header.dart`: big title and subtitle that shrink to a toolbar.
- `lib/navigation/screens/nav_scaffold.dart`: uses the header instead of the small top bar. It listens to vertical scrolling of the current tab to decide how far to collapse. The Alarm tab subtitle uses the next upcoming alarm and refreshes every 30 seconds and whenever the alarm list is saved. The settings button stays in the header.
- `lib/alarm/utils/next_alarm.dart`: adds `alarmListRevision` (a counter the alarm list bumps on save) and `getNextUpcomingAlarm()`.

### Tab order and labels
- `lib/navigation/data/tabs.dart`: order is now Alarm, Clock, Stopwatch, Timer. The "Default Tab" setting still stores the upstream index (0 Alarm, 1 Clock, 2 Timer, 3 Stopwatch); `tabIndexFromLegacyIndex()` converts it, so saved settings and backups keep working.
- `lib/app.dart`: uses that conversion when opening the app.
- `nav_scaffold.dart` and `lib/navigation/widgets/app_navigation_bar.dart`: labels always shown in both navigation bar styles.

### Alarm list item
- `lib/alarm/widgets/alarm_card.dart`: new layout. Same actions as before (switch, Dismiss for snoozed alarms that cannot be disabled, delete for finished alarms, and the Skip, Duplicate and Delete menu).

### Add and edit alarm screen
- New `lib/alarm/screens/alarm_editor_screen.dart`. It edits a copy of the alarm, the same way upstream's customize screen did, and uses the same Cancel and Save buttons and the unsaved-changes prompt.
- Sections and where each upstream setting went:
  - Label: Label
  - Repeat: everything in the upstream "Schedule" group (type, week days, dates, date range, interval, delete after ringing, delete after finishing)
  - Sound: Melody, Volume, Rising volume, Time to full volume, Audio channel
  - Vibration: Vibration
  - Snooze: Enabled, Length, Max snoozes
  - Dismiss task: Tasks
  - Advanced (collapsed): Start melody at random position, Volume while doing tasks, While snoozed (prevent disabling, prevent deletion), Tags, and any setting not listed above
- The alarm settings schema (`lib/alarm/data/alarm_settings_schema.dart`) is unchanged, so saved alarms and backups are compatible with upstream 0.6.0.
- `lib/alarm/screens/alarm_screen.dart`: the add button and the "Add alarm" launcher shortcut open this screen directly with the current time.

### Alarm reliability setup
- New `android/app/src/main/kotlin/com/vicolo/chrono/ReliabilityChannel.kt`, registered in `MainActivity.kt`, on the method channel `com.vicolo.chrono/reliability`. `getStatus` returns the Android version, `Build.MANUFACTURER`, and: notifications enabled, `AlarmManager.canScheduleExactAlarms()` (Android 12+), `NotificationManager.canUseFullScreenIntent()` (Android 14+), `PowerManager.isIgnoringBatteryOptimizations()`, and `PackageManager.isAutoRevokeWhitelisted` (Android 11+). `open` starts the matching settings screen. Every intent is tried in a list with try/catch and falls back to App info and then the main Settings screen, so a missing screen never crashes the app.
- Intents used: app notification settings; `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`; `android.settings.MANAGE_APP_USE_FULL_SCREEN_INTENT`; `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` then `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`; `Intent.ACTION_AUTO_REVOKE_PERMISSIONS`. For Samsung "Never sleeping apps": `com.samsung.android.lool` / `com.samsung.android.sm` / `com.samsung.android.sm_cn` battery activities, then `ACTION_POWER_USAGE_SUMMARY`. For Samsung "Unrestricted": App info.
- The manifest already declared `USE_EXACT_ALARM` and `SCHEDULE_EXACT_ALARM` upstream, so on Android 13 and newer exact alarms are normally allowed already. The app does not use "display over other apps", so that permission is not requested.
- New `lib/system/logic/reliability.dart`: status model, the ordered item list, Done ticks and the "shown once" flag (stored with GetStorage). Notification permission is requested with `permission_handler` first and falls back to the settings screen.
- New `lib/system/screens/reliability_screen.dart`: the screen (refreshes on resume; "Fix all" works through a queue, one item per return to the app) and the Alarm tab banner.
- `lib/navigation/screens/nav_scaffold.dart`: opens the screen once on first launch.
- `lib/alarm/screens/alarm_screen.dart`: shows the banner above the alarm list.
- `lib/settings/data/general_settings_schema.dart`: "Alarm reliability setup" entry at the top of Reliability. Defaults for "Show Foreground Notification" and "useBackgroundService" changed from off to on. Saved values are kept, so this only affects new installs. The alarm audio channel default was already "Alarm" upstream, and boot handling and full-screen alarms are always on (they have no setting).

### Text
- `lib/l10n/app_en.arb`: new English strings `alarmRingsInHeader`, `allAlarmsOffHeader`, `repeatSection`, `advancedSection`, `advancedSectionDescription`, `dismissTaskSection`, `dismissTaskSectionDescription`, and the `reliability*` strings for the setup screen. The file was rewritten by a script, which also normalised some spacing; no existing text changed.

### Theme
- `lib/theme/data/default_style_themes.dart`: the default "Paper" style has a corner radius of 24 instead of 16. Existing installs keep their saved style.

## Samsung Clock design and vibration feedback (pre-release 3)

This replaces the earlier mix of Samsung and Apple styles.

- `lib/navigation/widgets/large_header.dart`: centred large title (38 sp) and subtitle.
- `lib/navigation/screens/nav_scaffold.dart`: the expanded header is about 30% of the screen height (between 160 and 320 dp) and collapses to 56 dp. Vibration on tab and page change.
- `lib/navigation/widgets/app_navigation_bar.dart`: rounded bottom bar with text tabs and a highlight on the current tab. Used when "Use Material Style" is off (the default); the Material bar is unchanged.
- `lib/alarm/widgets/alarm_card.dart`: label, large time (AM/PM smaller), day letters with active days highlighted, or the date for other repeat types; switch with vibration.
- New `lib/alarm/logic/day_chips.dart`: reads and writes the day buttons. It only uses the existing "Type" and "Week Days" settings: no days selected means Once, all seven means Daily, anything else is Weekly with those days. Saved alarms and backups stay compatible.
- `lib/alarm/screens/alarm_editor_screen.dart`: rebuilt in the Samsung layout described in the README. The other repeat types, the full sound settings and the snooze settings open from the calendar button and the rows. Any setting not shown on the main screen is listed in the Advanced section, so none is lost.
- `lib/common/widgets/customize_screen.dart`: new `buttonsAtBottom` option for a bottom Cancel/Save bar.
- `lib/common/widgets/list/custom_list_view.dart`: select mode with round check boxes and a bottom bar (All, Delete, Cancel); `listSelectionActive` lets the add button hide (`lib/common/widgets/fab.dart`).
- `lib/stopwatch/screens/stopwatch_screen.dart` and `lib/stopwatch/widgets/stopwatch_ticker.dart`: wide round buttons instead of floating buttons (Reset is available when paused, as in Samsung Clock) and large digits in the 00:00.00 format (`formatStopwatchTime`).
- `lib/timer/widgets/timer_card.dart`: circular ring with the time inside, round play/pause and reset buttons, same menu.
- `lib/clock/widgets/timezone_card_content.dart`: larger city name and time.
- `lib/theme/data/default_color_schemes.dart` and `lib/theme/theme.dart`: "One UI" and "One UI Dark" schemes, used as defaults on new installs.
- `lib/settings/data/general_settings_schema.dart`: Swipe Action defaults to switching tabs on new installs.
- New `lib/common/utils/haptics.dart`: one place for all vibration feedback. It uses Flutter's `HapticFeedback`, which goes through Android's view feedback and so follows the system touch feedback setting, and checks the new "Vibration Feedback" switch in `lib/settings/data/accessibility_settings_schema.dart` (on by default).
- Vibration added in: `spinner_time_picker.dart` (each wheel tick), `switch_field.dart`, `toggle_field.dart`, the day buttons, `custom_list_view.dart` (press and hold, select), `action_pane.dart` (swipe delete and duplicate), `fab.dart`, the stopwatch and timer buttons, and tab changes.
- `lib/l10n/app_en.arb`: new English strings for the above.

## Packaging and build
- `android/app/build.gradle`: application ID `com.oiuyretro.chrono`; app name "Chrono Custom"; release signing from `CHRONO_KEYSTORE_PROPERTIES` or `android/keystore.properties`, unsigned if neither exists. The Kotlin package and method channel names are still `com.vicolo.chrono`; they are internal and do not affect installation.
- `android/keystore.properties.example`: template for the signing file.
- `android/settings.gradle`: adds `com.android.tools:r8:8.3.37` to the settings build script classpath. The D8 bundled with Android Gradle Plugin 7.4.2 fails with a NullPointerException on libraries compiled with JDK 21 (AndroidX lifecycle 2.8.x, tsbackgroundfetch 4.1.1).
- `android/gradle.properties`: Gradle heap raised from 1.5 GB to 4 GB.
- `pubspec.yaml`: version `0.6.0-custom.1+30`; `path_provider_platform_interface` and `plugin_platform_interface` added as dev dependencies for the screenshot test.
- `.gitignore`: signing files and `test/screenshots/goldens/`.

## Tests
- New `test/screenshots/redesign_screenshots_test.dart` (also renders the reliability screen).
- New `test/alarm/logic/day_chips_test.dart` (day button rules and the vibration setting) and `test/stopwatch/stopwatch_format_test.dart`.
- The screenshot test also renders the stopwatch, timer and world clock.
- New `test/system/reliability_test.dart`: item list per Android version and maker, Samsung title, and the Fix all order.

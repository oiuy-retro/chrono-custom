# Changelog

All changes in this custom build. Upstream changes are listed in the [upstream repository](https://github.com/vicolo-dev/chrono/releases).

## 0.6.0-custom.1, versionCode 32 (pre-release 5)

Alarm sound:
- New per-alarm switch "Also ring on phone speaker" (off by default), shown under Alarm sound. While Bluetooth audio is connected, the alarm plays on the Bluetooth device and a second copy plays on the phone's built-in speaker. Without Bluetooth only one copy plays, as before.
- Both copies start at the same point, follow the alarm volume and rising volume, and stop on dismiss and snooze. If Bluetooth disconnects while the alarm rings, the speaker copy keeps playing and the other copy is silenced.
- "Start at random point" (upstream's "Random position", renamed) is now on the main alarm screen and on by default for new alarms. Existing alarms keep their setting; on existing installs the template for new alarms is switched on once.
- The random point is never in the last 15 seconds or the last 20% of the sound. Sounds shorter than 20 seconds, or whose length cannot be read, start at the beginning. The sound loops from the beginning after it ends.
- Rising volume now actually rises. Before, the first volume change cancelled the steps, so the alarm played at full volume straight away.
- Timers are unchanged (no random start, no speaker copy).

Other:
- versionCode raised to 32.
- New tests for the random start point, the new defaults and the speaker channel. Screenshots of the alarm screen with the new switches in light and dark.

## 0.6.0-custom.1, versionCode 31 (pre-release 4)

Alarm order:
- The alarm list is sorted by time of day, earliest first, by default and stays sorted when alarms are added or changed. Before this, the default was upstream's "Default" order (the order alarms were added in).
- Existing installs on "Default" are switched once; any other sort you had picked is kept. The Sort button above the list still offers every order, including "Default".
- "Show Sort" now only hides the Sort button; the list is still sorted.
- Alarms with the same time keep a steady order (stable sort).

Dark mode:
- New "Theme" setting at the top of Settings: System default (follows the phone), Light or Dark. Default System default.
- Dark mode uses the One UI Dark scheme (black page, dark grey cards). It works with and without Material You.
- Dark schemes are now reported to Flutter as dark, so check boxes, text fields, dialogs and icons use light-on-dark colours.
- Material You cards use a lighter or darker shade than the page so they stay visible.
- The old "System Dark Mode" and "Brightness" settings are hidden and replaced by Theme; they are still read from backups. Existing installs move to One UI Dark once unless a custom dark scheme was in use. The One UI schemes are added to the scheme list on existing installs.
- Alarm name field on the alarm screen is a plain underlined field with a readable hint in light and dark.

Other:
- versionCode raised to 31.
- New tests for the alarm order (default, one-time switch, live sorting) and for dark mode (Theme default, dark scheme brightness, migration, Material You cards). Screenshot test renders dark versions of every main screen, the settings screen and the ringing screen.

## 0.6.0-custom.1, versionCode 30 (pre-release 3)

Samsung Clock design (replaces the earlier mix with Apple Clock):
- Large centred tab titles that take about a third of the screen and collapse on scroll.
- Rounded bottom tab bar with text tabs and a highlight on the current tab. Swiping switches tabs on new installs.
- Alarm cards show the label, a large time with a small AM/PM, and S M T W T F S with the active days highlighted.
- Press and hold in a list to enter select mode with round check boxes and a bottom bar (All, Delete, Cancel).
- Add and edit alarm screen rebuilt: time wheels with AM/PM, day buttons, Alarm name field, Alarm sound / Vibration / Snooze rows with summaries and switches, Advanced section for the rest, Cancel and Save at the bottom.
- Stopwatch with large 00:00.00 digits and wide round Start, Lap, Stop, Reset and Resume buttons.
- Timers with a circular ring and round play/pause and reset buttons.
- Larger city names and times in the world clock.
- New default colour schemes "One UI" and "One UI Dark" for new installs.

Vibration feedback:
- Short vibrations on time wheel ticks, switches, day buttons, press-and-hold selection, tab changes, stopwatch and timer buttons, the add button, and swipe actions.
- Follows Android's touch feedback setting. New setting Settings, Accessibility, Vibration feedback (on by default).

Other:
- versionCode raised to 30.
- New tests for the day buttons, the vibration setting and the stopwatch format. Screenshot test also renders the stopwatch, timer and world clock.

## 0.6.0-custom.1, versionCode 29 (pre-release 2)

Alarm reliability:
- New "Alarm reliability" screen ("Set up for Samsung" on Samsung phones) with a live status and a Fix button for: notifications, alarms and reminders (exact alarms, Android 12+), full-screen alerts (Android 14+), battery optimization, and keeping permissions when the app is unused (Android 11+). On Samsung it adds two manual items with a Done tick: battery usage set to Unrestricted, and Never sleeping apps / Put unused apps to sleep.
- "Fix all" opens each unmet item in turn and re-checks the status when you return to the app.
- The screen opens once on first launch, a banner on the Alarm tab links to it while anything is not OK, and Settings, General, Reliability has an "Alarm reliability setup" entry.
- New installs have "Show foreground notification" and "Use background service" on by default. Saved settings are unchanged.
- versionCode raised to 29.

## 0.6.0-custom.1, versionCode 28 (pre-release 1)

Based on upstream commit `9e30f243271a27e79573e2b2d3da10159419eb8e` (v0.6.0 plus four commits).

Interface:
- Large title header on every tab that shrinks to a toolbar when the list scrolls. The Alarm tab shows the time until the next alarm; the Clock tab shows today's date.
- Tabs reordered to Alarm, Clock, Stopwatch, Timer. Labels are always shown.
- Alarm list items show a larger time, the label and schedule below it, and the switch on the right.
- New add and edit alarm screen: scroll-wheel time picker at the top, then sections for Label, Repeat, Sound, Vibration, Snooze and Dismiss task, and a collapsed Advanced section.
- The add button opens the alarm screen directly instead of a time dialog.
- The default "Paper" style uses rounder corners (24 instead of 16) on new installs.

Packaging:
- Application ID changed to `com.oiuyretro.chrono`; app name "Chrono Custom" ("Chrono Custom Dev" for the dev flavor).
- Release signing reads a `keystore.properties` file from outside the repository. Without it the release APK is unsigned.
- Newer D8/R8 (8.3.37) on the build classpath to fix "Error while dexing" with AGP 7.4.2.
- Gradle memory raised to 4 GB.

Tests:
- Added a screenshot test (`test/screenshots`) that only runs with `--update-goldens`, plus a check that the alarm settings sections still exist.

# Changelog

All changes in this custom build. Upstream changes are listed in the [upstream repository](https://github.com/vicolo-dev/chrono/releases).

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

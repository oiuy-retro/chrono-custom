# Changelog

All changes in this custom build. Upstream changes are listed in the [upstream repository](https://github.com/vicolo-dev/chrono/releases).

## 0.6.0-custom.1 (unreleased, pre-release build)

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

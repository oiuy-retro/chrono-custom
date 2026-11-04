# Updating from upstream

A fork keeps its own copy of the code. To get new versions of Chrono, you fetch the upstream changes and merge them into this repository. In this repository the remote called `origin` is the fork (`oiuy-retro/chrono-custom`) and `upstream` is the original project (`vicolo-dev/chrono`). Upstream's main branch is called `master`; this fork's is `main`.

## Steps

1. Get the latest upstream code:

   ```
   git fetch upstream --tags
   ```

2. Start a branch for the update from `main`:

   ```
   git checkout main
   git pull
   git checkout -b chore/sync-upstream-<version>
   ```

3. Merge the upstream release you want (a tag such as `v0.6.1`, or `upstream/master`):

   ```
   git merge v0.6.1
   ```

4. If git reports conflicts, the files most likely to conflict are the ones listed in [CUSTOM_CHANGES.md](CUSTOM_CHANGES.md). Keep upstream's new behaviour and re-apply the custom change on top. Pay special attention to:
   - `lib/alarm/data/alarm_settings_schema.dart`: if upstream adds, renames or moves an alarm setting, check `lib/alarm/screens/alarm_editor_screen.dart`. New settings appear under Advanced automatically; renamed ones need their path updated in the editor.
   - `lib/navigation/data/tabs.dart` and the "Default Tab" setting.
   - `android/app/build.gradle` (application ID, app name, signing).
   - `android/settings.gradle`: if upstream moves to Android Gradle Plugin 8 or newer, the extra R8 classpath entry can be removed.

5. Update `pubspec.yaml` to the new version with a `-custom.N` suffix, and add an entry to `CHANGELOG.md` and the base commit in `README.md`.

6. Run `flutter pub get`, `flutter analyze`, `flutter test` and a release build (see [BUILDING.md](BUILDING.md)).

7. Push the branch and open a pull request to `main`. Install the test build on a phone and check that alarms ring before merging.

Do not force-push and do not rebase `main`.

import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:get_storage/get_storage.dart';

const String randomStartDefaultMigrationKey =
    "chrono_custom_random_start_default_v1";

/// One-time change to the template used for new alarms (Settings, Alarm,
/// Default Settings): "Start at random point" is turned on. Alarms that
/// already exist keep their own setting.
Future<void> migrateAlarmDefaults({GetStorage? storage}) async {
  storage ??= GetStorage();
  if (storage.read(randomStartDefaultMigrationKey) == true) return;
  appSettings
      .getGroup("Alarm")
      .getGroup("Default Settings")
      .getGroup("Sound and Vibration")
      .getGroup("Sound")
      .getSetting("start_melody_at_random_pos")
      .setValueWithoutNotify(true);
  await appSettings.save();
  await storage.write(randomStartDefaultMigrationKey, true);
}

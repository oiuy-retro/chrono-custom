import 'package:clock_app/common/utils/list_storage.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/settings/types/setting_group.dart';
import 'package:clock_app/theme/data/default_color_schemes.dart';
import 'package:clock_app/theme/types/color_scheme.dart';
import 'package:clock_app/theme/types/theme_brightness.dart';
import 'package:get_storage/get_storage.dart';

const String themeMigrationKey = "chrono_custom_theme_migrated_v1";

/// One-time switch to the new "Theme" setting and the One UI dark scheme.
///
/// - Before this, dark mode without Material You only happened when the
///   hidden-now "System Dark Mode" switch was on. If it was off, the user had
///   never used a dark scheme, so the dark scheme becomes "One UI Dark".
///   If it was on, their chosen dark scheme is kept.
/// - With Material You, an explicit Light or Dark choice in the old
///   "Brightness" setting is carried over to "Theme". Otherwise "Theme" stays
///   on System default, which follows the phone's dark mode.
/// - The One UI schemes are added to the saved scheme list if missing, so
///   they can be picked in the colour scheme screens.
Future<void> migrateThemeSettings({GetStorage? storage}) async {
  storage ??= GetStorage();
  if (storage.read(themeMigrationKey) == true) return;

  final SettingGroup colors =
      appSettings.getGroup("Appearance").getGroup("Colors");
  final bool systemDarkMode = colors.getSetting("System Dark Mode").value;
  final bool useMaterialYou = colors.getSetting("Use Material You").value;
  final ThemeBrightness oldBrightness = colors.getSetting("Brightness").value;

  if (!systemDarkMode) {
    colors.getSetting("Dark Color Scheme").setValueWithoutNotify(
        defaultColorSchemes.firstWhere((s) => s.name == 'One UI Dark'));
  }
  if (useMaterialYou && oldBrightness != ThemeBrightness.system) {
    appSettings
        .getSetting("Theme")
        .setValueWithoutNotify(oldBrightness == ThemeBrightness.light ? 1 : 2);
  }
  await appSettings.save();

  if (textFileExistsSync('color_schemes')) {
    final List<ColorSchemeData> schemes =
        await loadList<ColorSchemeData>('color_schemes');
    bool changed = false;
    for (final name in ['One UI', 'One UI Dark']) {
      if (!schemes.any((s) => s.name == name && s.isDefault)) {
        schemes.add(defaultColorSchemes.firstWhere((s) => s.name == name));
        changed = true;
      }
    }
    if (changed) await saveList<ColorSchemeData>('color_schemes', schemes);
  }

  await storage.write(themeMigrationKey, true);
}

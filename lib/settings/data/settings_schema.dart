import 'package:clock_app/alarm/data/alarm_app_settings_schema.dart';
import 'package:clock_app/app.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:clock_app/theme/types/theme_brightness.dart';
import 'package:clock_app/clock/data/clock_settings_schema.dart';
import 'package:clock_app/developer/data/developer_settings_schema.dart';
import 'package:clock_app/settings/data/accessibility_settings_schema.dart';
import 'package:clock_app/settings/data/backup_settings_schema.dart';
import 'package:clock_app/settings/data/general_settings_schema.dart';
import 'package:clock_app/settings/screens/about_screen.dart';
import 'package:clock_app/settings/types/setting_group.dart';
import 'package:clock_app/settings/types/setting_link.dart';
import 'package:clock_app/stopwatch/data/stopwatch_settings_schema.dart';
import 'package:clock_app/theme/data/appearance_settings_schema.dart';
import 'package:clock_app/timer/data/timer_app_settings_schema.dart';
import 'package:clock_app/widgets/data/widget_settings_schema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


// Increment this after every schema change
const int settingsSchemaVersion = 7;

SettingGroup appSettings = SettingGroup(
  "Settings",
  (context) => AppLocalizations.of(context)!.settings,
  version: settingsSchemaVersion,
  isSearchable: true,
  [
    // Chrono Custom: light/dark choice at the top of Settings. "System
    // default" follows the phone's dark mode.
    SelectSetting<ThemeBrightness>(
      "Theme",
      (context) => AppLocalizations.of(context)!.themeSetting,
      [
        SelectSettingOption(
            (context) => AppLocalizations.of(context)!.themeSystemDefault,
            ThemeBrightness.system),
        SelectSettingOption(
            (context) => AppLocalizations.of(context)!.themeLight,
            ThemeBrightness.light),
        SelectSettingOption(
            (context) => AppLocalizations.of(context)!.themeDark,
            ThemeBrightness.dark),
      ],
      getDescription: (context) =>
          AppLocalizations.of(context)!.themeSettingDescription,
      onChange: (context, index) => App.refreshTheme(context),
      searchTags: ["dark mode", "night mode", "light", "brightness"],
    ),
    generalSettingsSchema,
    appearanceSettingsSchema,
    alarmAppSettingsSchema,
    clockSettingsSchema,
    timerAppSettingsSchema,
    stopwatchSettingsSchema,
    widgetSettingSchema,
    accessibilitySettingsSchema,
    backupSettingsSchema,
    developerSettingsSchema,
    SettingPageLink(
      "About",
      (context) => AppLocalizations.of(context)!.aboutSettingGroup,
      const AboutScreen(),
      icon: Icons.info_outline_rounded,
    ),
  ],
);


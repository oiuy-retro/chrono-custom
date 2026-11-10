import 'package:clock_app/settings/types/setting.dart';
import 'package:clock_app/settings/types/setting_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

SettingGroup accessibilitySettingsSchema = SettingGroup(
  "Accessibility",
  (context) => AppLocalizations.of(context)!.accessibilitySettingGroup,
  [
    SwitchSetting("Left Handed Mode",
        (context) => AppLocalizations.of(context)!.leftHandedSetting, false),
    SwitchSetting(
      "Vibration Feedback",
      (context) => AppLocalizations.of(context)!.vibrationFeedbackSetting,
      true,
      getDescription: (context) =>
          AppLocalizations.of(context)!.vibrationFeedbackSettingDescription,
      searchTags: ["haptic", "vibration", "touch", "feedback"],
    ),
  ],
  icon: Icons.accessibility_new_rounded,
  showExpandedView: false,
);

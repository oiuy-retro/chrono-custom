import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/alarm/widgets/alarm_description.dart';
import 'package:clock_app/clock/types/time.dart';
import 'package:clock_app/common/widgets/card_container.dart';
import 'package:clock_app/common/widgets/customize_screen.dart';
import 'package:clock_app/common/widgets/spinner_time_picker.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/settings/logic/get_setting_widget.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:clock_app/settings/types/setting_group.dart';
import 'package:clock_app/settings/types/setting_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Add / edit alarm screen.
///
/// Leads with a large scroll-wheel time picker, then shows the alarm's
/// settings in plain sections (Label, Repeat, Sound, Vibration, Snooze,
/// Dismiss task) instead of nested menus. Less common options live in a
/// collapsed "Advanced" section. Every setting of the alarm schema is still
/// shown somewhere: anything not placed in a named section is added to
/// "Advanced" automatically.
class AlarmEditorScreen extends StatelessWidget {
  const AlarmEditorScreen({
    super.key,
    required this.alarm,
    required this.isNewAlarm,
  });

  final Alarm alarm;
  final bool isNewAlarm;

  @override
  Widget build(BuildContext context) {
    return CustomizeScreen<Alarm>(
      item: alarm,
      isNewItem: isNewAlarm,
      builder: (context, item) => _AlarmEditorBody(alarm: item),
    );
  }
}

class _AlarmEditorBody extends StatefulWidget {
  const _AlarmEditorBody({required this.alarm});

  final Alarm alarm;

  @override
  State<_AlarmEditorBody> createState() => _AlarmEditorBodyState();
}

class _AlarmEditorBodyState extends State<_AlarmEditorBody> {
  late final Setting _timeFormatSetting = appSettings
      .getGroup("General")
      .getGroup("Display")
      .getSetting("Time Format");

  bool _is24Hour(BuildContext context) {
    TimeFormat format = _timeFormatSetting.value;
    if (format == TimeFormat.device) {
      return MediaQuery.of(context).alwaysUse24HourFormat;
    }
    return format == TimeFormat.h24;
  }

  void _refresh() => setState(() {});

  SettingItem? _find(SettingGroup group, List<String> path) {
    try {
      SettingItem current = group;
      for (final name in path) {
        if (current is! SettingGroup) return null;
        current = current.getSettingItem(name);
      }
      return current;
    } catch (_) {
      return null;
    }
  }

  List<SettingItem> _leaves(SettingItem item) {
    if (item is SettingGroup) {
      return item.settingItems.expand(_leaves).toList();
    }
    return [item];
  }

  List<Widget> _widgetsFor(List<SettingItem> items) {
    return getSettingWidgets(
      items,
      showAsCard: false,
      checkDependentEnableConditions: _refresh,
      onSettingChanged: _refresh,
      isAppSettings: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;
    final SettingGroup settings = widget.alarm.settings;

    final Set<SettingItem> placed = {};
    List<SettingItem> pick(List<List<String>> paths) {
      final result = <SettingItem>[];
      for (final path in paths) {
        final item = _find(settings, path);
        if (item == null) continue;
        result.add(item);
        placed.addAll(_leaves(item));
      }
      return result;
    }

    // Children of a group, rendered flat (no nested page).
    List<SettingItem> pickChildren(List<String> groupPath) {
      final group = _find(settings, groupPath);
      if (group is! SettingGroup) return [];
      placed.addAll(_leaves(group));
      return group.settingItems;
    }

    const sv = "Sound and Vibration";
    final sections = <(String?, String?, List<SettingItem>)>[
      (null, null, pick([["Label"]])),
      (l10n.repeatSection, null, pickChildren(["Schedule"])),
      (
        l10n.soundSettingGroup,
        null,
        pick([
          [sv, "Sound", "Melody"],
          [sv, "Sound", "Volume"],
          [sv, "Sound", "Rising Volume"],
          [sv, "Sound", "Time To Full Volume"],
          [sv, "Sound", "Audio Channel"],
        ])
      ),
      (null, null, pick([[sv, "Vibration"]])),
      (
        l10n.snoozeSettingGroup,
        null,
        pick([
          ["Snooze", "Enabled"],
          ["Snooze", "Length"],
          ["Snooze", "Max Snoozes"],
        ])
      ),
      (
        l10n.dismissTaskSection,
        l10n.dismissTaskSectionDescription,
        pick([["Tasks"]])
      ),
    ];

    final advancedItems = <SettingItem>[
      ...pick([
        [sv, "Sound", "start_melody_at_random_pos"],
        [sv, "Sound", "task_volume"],
      ]),
      ...pickChildren(["Snooze", "While Snoozed"]),
      ...pick([["Tags"]]),
    ];
    // Safety net: never hide a setting that exists in the schema.
    for (final leaf in _leaves(settings)) {
      if (!placed.contains(leaf)) {
        advancedItems.add(leaf);
        placed.add(leaf);
      }
    }

    Widget sectionCard(String? title, String? description, List<Widget> children,
        {bool collapsible = false}) {
      if (children.isEmpty) return const SizedBox.shrink();
      final Widget header = title == null
          ? const SizedBox.shrink()
          : Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                )),
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(description,
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6))),
              ),
          ],
        ),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: CardContainer(
          child: collapsible
              ? Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.only(right: 16),
                    title: header,
                    children: children,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [header, const SizedBox(height: 4), ...children],
                  ),
                ),
        ),
      );
    }

    final bool is24Hour = _is24Hour(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // Large scroll-wheel time picker.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TimePickerSpinner(
            key: ValueKey("alarm_wheel_$is24Hour"),
            time: widget.alarm.time.toDateTime(),
            is24HourMode: is24Hour,
            isForce2Digits: true,
            itemHeight: 72,
            itemWidth: 96,
            spacing: 8,
            highlightedTextStyle: textTheme.displayLarge?.copyWith(
              fontSize: 56,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            normalTextStyle: textTheme.displayLarge?.copyWith(
              fontSize: 40,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withOpacity(0.25),
            ),
            onTimeChange: (dateTime) {
              setState(() {
                widget.alarm.setTimeFromTimeOfDay(
                    TimeOfDay.fromDateTime(dateTime));
              });
            },
          ),
        ),
        Center(child: AlarmDescription(alarm: widget.alarm)),
        const SizedBox(height: 8),
        for (final (title, description, items) in sections)
          sectionCard(title, description, _widgetsFor(items)),
        sectionCard(
          l10n.advancedSection,
          l10n.advancedSectionDescription,
          _widgetsFor(advancedItems),
          collapsible: true,
        ),
      ],
    );
  }
}

import 'package:clock_app/alarm/logic/day_chips.dart';
import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/alarm/widgets/alarm_description.dart';
import 'package:clock_app/clock/types/time.dart';
import 'package:clock_app/common/types/file_item.dart';
import 'package:clock_app/common/utils/haptics.dart';
import 'package:clock_app/common/widgets/card_container.dart';
import 'package:clock_app/common/widgets/customize_screen.dart';
import 'package:clock_app/common/widgets/spinner_time_picker.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/settings/logic/get_setting_widget.dart';
import 'package:clock_app/settings/screens/settings_group_screen.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:clock_app/settings/types/setting_group.dart';
import 'package:clock_app/settings/types/setting_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Add / edit alarm screen laid out like Samsung Clock on One UI.
///
/// Time spinner (hour, minute, AM/PM), a row of day chips, the alarm name,
/// then rows for Alarm sound, Vibration and Snooze with switches and summary
/// values, the dismiss task, and a collapsed Advanced section. Cancel and Save
/// are at the bottom. Each row opens the full upstream settings for that
/// group, so every setting stays reachable. Any setting not covered by a row
/// is listed under Advanced automatically.
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
      buttonsAtBottom: true,
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

  late final TextEditingController _labelController =
      TextEditingController(text: widget.alarm.label);

  SettingGroup get _settings => widget.alarm.settings;
  SettingGroup get _schedule => _settings.getGroup("Schedule");
  SettingGroup get _soundAndVibration =>
      _settings.getGroup("Sound and Vibration");
  SettingGroup get _sound => _soundAndVibration.getGroup("Sound");
  SettingGroup get _snooze => _settings.getGroup("Snooze");

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  bool _is24Hour(BuildContext context) {
    TimeFormat format = _timeFormatSetting.value;
    if (format == TimeFormat.device) {
      return MediaQuery.of(context).alwaysUse24HourFormat;
    }
    return format == TimeFormat.h24;
  }

  void _refresh() => setState(() {});

  Future<void> _openGroup(SettingGroup group) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SettingGroupScreen(settingGroup: group, isAppSettings: false),
      ),
    );
    _refresh();
  }

  List<SettingItem> _leaves(SettingItem item) {
    if (item is SettingGroup) {
      return item.settingItems.expand(_leaves).toList();
    }
    return [item];
  }

  /// Settings not reachable from any row: shown under Advanced.
  List<SettingItem> _advancedItems() {
    final covered = <SettingItem>{
      ..._leaves(_schedule),
      ..._leaves(_soundAndVibration),
      ..._leaves(_snooze),
      _settings.getSetting("Label"),
      _settings.getSetting("Tasks"),
    };
    return _leaves(_settings).where((s) => !covered.contains(s)).toList();
  }

  String _melodyName() {
    try {
      final value = _sound.getSetting("Melody").value;
      if (value is FileItem) return value.name;
    } catch (_) {}
    return "";
  }

  String _formatNumber(dynamic value) {
    if (value is double && value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  Widget _row({
    required String title,
    String? subtitle,
    bool? switchValue,
    ValueChanged<bool>? onSwitch,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: switchValue == false
                                  ? colorScheme.onSurface.withOpacity(0.5)
                                  : colorScheme.primary)),
                    ),
                ],
              ),
            ),
            if (switchValue != null) ...[
              if (onTap != null)
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: colorScheme.onSurface.withOpacity(0.12),
                ),
              Switch(
                value: switchValue,
                onChanged: (v) {
                  Haptics.toggle();
                  onSwitch?.call(v);
                  _refresh();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: CardContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );

  Widget _dayChips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labels = dayChipLabels(context, widget.alarm);
    final states = dayChipStates(widget.alarm);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < labels.length; i++)
            Semantics(
              button: true,
              selected: states[i],
              child: InkResponse(
                radius: 22,
                onTap: () {
                  Haptics.toggle();
                  tapDayChip(context, widget.alarm, i);
                  _refresh();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: states[i] ? colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: states[i]
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: states[i]
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;
    final bool is24Hour = _is24Hour(context);

    final Setting vibration = _soundAndVibration.getSetting("Vibration");
    final Setting snoozeEnabled = _snooze.getSetting("Enabled");
    final String snoozeSummary = snoozeEnabled.value == true
        ? l10n.snoozeRowSummary(
            _formatNumber(_snooze.getSetting("Length").value),
            _formatNumber(_snooze.getSetting("Max Snoozes").value))
        : l10n.offLabel;

    final tasksWidget = getSettingItemWidget(
      _settings.getSetting("Tasks"),
      showAsCard: false,
      checkDependentEnableConditions: _refresh,
      onSettingChanged: _refresh,
      isAppSettings: false,
    );

    final advanced = getSettingWidgets(
      _advancedItems(),
      showAsCard: false,
      checkDependentEnableConditions: _refresh,
      onSettingChanged: _refresh,
      isAppSettings: false,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // Samsung-style time spinner: hour, minute and AM/PM columns.
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: TimePickerSpinner(
            key: ValueKey("alarm_wheel_$is24Hour"),
            time: widget.alarm.time.toDateTime(),
            is24HourMode: is24Hour,
            isForce2Digits: true,
            itemHeight: 64,
            itemWidth: 92,
            spacing: 4,
            highlightedTextStyle: textTheme.displayLarge?.copyWith(
              fontSize: 52,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
            ),
            normalTextStyle: textTheme.displayLarge?.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w300,
              color: colorScheme.onSurface.withOpacity(0.28),
            ),
            onTimeChange: (dateTime) {
              setState(() {
                widget.alarm
                    .setTimeFromTimeOfDay(TimeOfDay.fromDateTime(dateTime));
              });
            },
          ),
        ),
        _card([
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 4, 0),
            child: Row(
              children: [
                Expanded(child: AlarmDescription(alarm: widget.alarm)),
                IconButton(
                  tooltip: l10n.repeatOptionsRow,
                  icon: Icon(Icons.calendar_month_rounded,
                      color: colorScheme.onSurface.withOpacity(0.7)),
                  onPressed: () {
                    Haptics.button();
                    _openGroup(_schedule);
                  },
                ),
              ],
            ),
          ),
          _dayChips(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _labelController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.alarmNameHint,
                border: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.2))),
              ),
              onChanged: (text) =>
                  _settings.getSetting("Label").setValue(context, text),
            ),
          ),
        ]),
        _card([
          _row(
            title: l10n.alarmSoundRow,
            subtitle: _melodyName(),
            onTap: () => _openGroup(_sound),
          ),
          _row(
            title: l10n.vibrationSetting,
            subtitle: vibration.value == true ? l10n.onLabel : l10n.offLabel,
            switchValue: vibration.value == true,
            onSwitch: (v) => vibration.setValue(context, v),
          ),
          _row(
            title: l10n.snoozeSettingGroup,
            subtitle: snoozeSummary,
            switchValue: snoozeEnabled.value == true,
            onSwitch: (v) => snoozeEnabled.setValue(context, v),
            onTap: () => _openGroup(_snooze),
          ),
        ]),
        if (tasksWidget != null)
          _card([
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
              child: Text(l10n.dismissTaskSectionDescription,
                  style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6))),
            ),
            tasksWidget,
          ]),
        if (advanced.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: CardContainer(
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(l10n.advancedSection,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  subtitle: Text(l10n.advancedSectionDescription,
                      style: textTheme.bodySmall),
                  onExpansionChanged: (_) => Haptics.toggle(),
                  children: advanced,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

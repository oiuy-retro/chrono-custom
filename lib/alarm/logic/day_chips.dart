import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/alarm/types/schedules/daily_alarm_schedule.dart';
import 'package:clock_app/alarm/types/schedules/once_alarm_schedule.dart';
import 'package:clock_app/alarm/types/schedules/weekly_alarm_schedule.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:flutter/widgets.dart';

/// Samsung-style "S M T W T F S" day chips on top of the existing schedule
/// settings. No new settings are stored: the chips set the schedule "Type"
/// (Once, Daily or Weekly) and the "Week Days" toggle.

ToggleSetting _weekDaysSetting(Alarm alarm) => alarm.settings
    .getGroup("Schedule")
    .getSetting("Week Days") as ToggleSetting;

SelectSetting _typeSetting(Alarm alarm) =>
    alarm.settings.getGroup("Schedule").getSetting("Type") as SelectSetting;

/// Letters for the chips, in display order (respects "First Day of Week").
List<String> dayChipLabels(BuildContext context, Alarm alarm) =>
    _weekDaysSetting(alarm)
        .options
        .map((o) => o.getLocalizedName(context))
        .toList();

/// Whether each chip is highlighted, in display order.
List<bool> dayChipStates(Alarm alarm) {
  final type = alarm.scheduleType;
  if (type == DailyAlarmSchedule) return List.filled(7, true);
  if (type == WeeklyAlarmSchedule) {
    return List<bool>.from(_weekDaysSetting(alarm).value as List);
  }
  return List.filled(7, false);
}

/// True when the chips fully describe the schedule (Once, Daily, Weekly).
bool dayChipsDescribeSchedule(Alarm alarm) => [
      OnceAlarmSchedule,
      DailyAlarmSchedule,
      WeeklyAlarmSchedule
    ].contains(alarm.scheduleType);

void _setType(BuildContext context, Alarm alarm, Type type) {
  final setting = _typeSetting(alarm);
  final index = setting.options.indexWhere((o) => o.value == type);
  if (index >= 0) setting.setValue(context, index);
}

void _setDays(BuildContext context, Alarm alarm, List<bool> displayOrder) {
  final setting = _weekDaysSetting(alarm);
  final offset = setting.getOffset?.call() ?? 0;
  final n = displayOrder.length;
  final raw = List<bool>.filled(n, false);
  for (int i = 0; i < n; i++) {
    raw[(i + offset) % n] = displayOrder[i];
  }
  setting.setValue(context, raw);
}

/// Handles a tap on the chip at [displayIndex], like Samsung Clock:
/// picking days makes the alarm repeat on those days, all seven means every
/// day, and clearing the last day makes it a one-time alarm again.
void tapDayChip(BuildContext context, Alarm alarm, int displayIndex) {
  final states = dayChipStates(alarm);
  states[displayIndex] = !states[displayIndex];
  final count = states.where((s) => s).length;
  if (count == 0) {
    _setType(context, alarm, OnceAlarmSchedule);
  } else if (count == 7) {
    _setType(context, alarm, DailyAlarmSchedule);
  } else {
    _setDays(context, alarm, states);
    _setType(context, alarm, WeeklyAlarmSchedule);
  }
}

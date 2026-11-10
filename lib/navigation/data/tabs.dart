import 'package:clock_app/alarm/screens/alarm_screen.dart';
import 'package:clock_app/navigation/types/quick_action_controller.dart';
import 'package:clock_app/stopwatch/screens/stopwatch_screen.dart';
import 'package:clock_app/timer/screens/timer_screen.dart';

import 'package:clock_app/icons/flux_icons.dart';
import 'package:clock_app/clock/screens/clock_screen.dart';
import 'package:clock_app/navigation/types/tab.dart';
import 'package:flutter/material.dart' hide Tab;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

List<Tab> getTabs(BuildContext context,
    [QuickActionController? actionController]) {
  return [
    Tab(
        id: "alarm",
        title: AppLocalizations.of(context)!.alarmTitle,
        icon: FluxIcons.alarm,
        widget: AlarmScreen(actionController: actionController)),
    Tab(
        id: "clock",
        title: AppLocalizations.of(context)!.clockTitle,
        icon: FluxIcons.clock,
        widget: const ClockScreen()),
    Tab(
        id: "stopwatch",
        title: AppLocalizations.of(context)!.stopwatchTitle,
        icon: FluxIcons.stopwatch,
        widget: const StopwatchScreen()),
    Tab(
        id: "timer",
        title: AppLocalizations.of(context)!.timerTitle,
        icon: FluxIcons.timer,
        widget: TimerScreen(actionController: actionController)),
  ];
}

/// Tab ids in the order used by upstream Chrono. The "Default Tab" setting
/// stores an index into this list, so saved settings keep working after the
/// tabs were reordered to Alarm, World clock, Stopwatch, Timer.
const List<String> legacyTabOrder = ["alarm", "clock", "timer", "stopwatch"];

/// Converts a stored "Default Tab" value into an index for [getTabs].
int tabIndexFromLegacyIndex(BuildContext context, dynamic legacyIndex) {
  if (legacyIndex is! int ||
      legacyIndex < 0 ||
      legacyIndex >= legacyTabOrder.length) {
    return 0;
  }
  final index = getTabs(context)
      .indexWhere((tab) => tab.id == legacyTabOrder[legacyIndex]);
  return index < 0 ? 0 : index;
}

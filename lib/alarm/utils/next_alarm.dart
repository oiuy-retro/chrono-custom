import 'package:flutter/foundation.dart';
import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/common/utils/list_storage.dart';

Alarm? getNextAlarm() {
  List<Alarm> alarms = loadListSync('alarms');
  if (alarms.isEmpty) return null;
  alarms.sort((a, b) {
    if (a.currentScheduleDateTime == null) return 1;
    if (b.currentScheduleDateTime == null) return -1;
    return a.currentScheduleDateTime!.compareTo(b.currentScheduleDateTime!);
  });
  return alarms.first;
}

/// Bumped whenever the alarm list is saved, so widgets outside the alarm
/// list (for example the large "next alarm" header) can refresh.
final ValueNotifier<int> alarmListRevision = ValueNotifier<int>(0);

/// Returns the next enabled alarm that has an upcoming ring time, or null.
Alarm? getNextUpcomingAlarm() {
  final Alarm? alarm = getNextAlarm();
  if (alarm == null || alarm.currentScheduleDateTime == null) return null;
  return alarm;
}

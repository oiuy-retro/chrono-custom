import 'package:clock_app/alarm/data/alarm_sort_options.dart';
import 'package:clock_app/common/utils/list_storage.dart';

/// File that stores the alarm list sort choice. 0 means "Default" (the order
/// alarms were added in); 1 and up are positions in [alarmSortOptions] + 1.
const String alarmSortIndexKey = "alarms-sort-index";

/// Marker so the one-time switch to time-of-day sorting runs only once.
const String alarmSortMigrationKey = "alarms-sort-time-of-day-v1";

/// Sort index for "Early hours first" (time of day, earliest first), the
/// order Samsung Clock uses.
int get timeOfDayAscendingSortIndex =>
    alarmSortOptions
        .indexWhere((o) => o.sortFunction == sortTimeOfDayAscending) +
    1;

/// Makes time of day (earliest first) the alarm list order.
///
/// New installs get it straight away. Existing installs that were still on
/// upstream's "Default" (insertion order, index 0) are moved to it once.
/// Anyone who had picked another sort keeps it, and anyone who picks
/// "Default" again later keeps that too, because this runs only once.
Future<void> initAlarmSortDefault() async {
  if (textFileExistsSync(alarmSortMigrationKey)) return;
  final bool hadNoChoice = !textFileExistsSync(alarmSortIndexKey) ||
      loadTextFileSync(alarmSortIndexKey).trim() == "0" ||
      loadTextFileSync(alarmSortIndexKey).trim().isEmpty;
  if (hadNoChoice) {
    await saveTextFile(
        alarmSortIndexKey, timeOfDayAscendingSortIndex.toString());
  }
  await saveTextFile(alarmSortMigrationKey, "done");
}

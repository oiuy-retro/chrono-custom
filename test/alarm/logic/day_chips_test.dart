import 'package:clock_app/alarm/logic/day_chips.dart';
import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/alarm/types/schedules/daily_alarm_schedule.dart';
import 'package:clock_app/alarm/types/schedules/once_alarm_schedule.dart';
import 'package:clock_app/alarm/types/schedules/weekly_alarm_schedule.dart';
import 'package:clock_app/common/types/time.dart';
import 'package:clock_app/common/utils/haptics.dart';
import 'package:clock_app/common/widgets/fields/switch_field.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }),
  ));
  return ctx;
}

void main() {
  testWidgets('day chips follow Samsung rules', (tester) async {
    final context = await _context(tester);
    final alarm = Alarm(const Time(hour: 7, minute: 0));
    expect(alarm.scheduleType, OnceAlarmSchedule);
    expect(dayChipStates(alarm).where((s) => s).length, 0);

    // Picking one day makes it weekly on that day only.
    tapDayChip(context, alarm, 2);
    expect(alarm.scheduleType, WeeklyAlarmSchedule);
    expect(dayChipStates(alarm), [false, false, true, false, false, false, false]);

    // Picking all seven makes it daily.
    for (final i in [0, 1, 3, 4, 5, 6]) {
      tapDayChip(context, alarm, i);
    }
    expect(alarm.scheduleType, DailyAlarmSchedule);
    expect(dayChipStates(alarm).every((s) => s), true);

    // Removing one from daily gives weekly with six days.
    tapDayChip(context, alarm, 0);
    expect(alarm.scheduleType, WeeklyAlarmSchedule);
    expect(dayChipStates(alarm).where((s) => s).length, 6);

    // Clearing every day makes it a one-time alarm again.
    for (final i in [1, 2, 3, 4, 5, 6]) {
      tapDayChip(context, alarm, i);
    }
    expect(alarm.scheduleType, OnceAlarmSchedule);
  });

  testWidgets('switches give haptic feedback unless turned off',
      (tester) async {
    final kinds = <String>[];
    Haptics.debugOnFeedback = kinds.add;
    addTearDown(() => Haptics.debugOnFeedback = null);
    bool value = false;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SwitchField(
            name: "Test", value: value, onChanged: (v) => value = v),
      ),
    ));
    await tester.tap(find.byType(Switch));
    expect(kinds, ["toggle"]);

    final setting =
        appSettings.getGroup("Accessibility").getSetting("Vibration Feedback");
    setting.setValueWithoutNotify(false);
    addTearDown(() => setting.setValueWithoutNotify(true));
    await tester.tap(find.byType(Switch));
    expect(kinds, ["toggle"]);
  });
}

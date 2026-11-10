import 'dart:io';

import 'package:clock_app/alarm/data/alarm_sort_options.dart';
import 'package:clock_app/alarm/logic/alarm_sort_default.dart';
import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/common/data/paths.dart';
import 'package:clock_app/common/types/list_controller.dart';
import 'package:clock_app/common/types/time.dart';
import 'package:clock_app/common/utils/list_storage.dart';
import 'package:clock_app/common/widgets/list/custom_list_view.dart';
import 'package:clock_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);
  final String root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

File _file(String key) => File('${getAppDataDirectoryPathSync()}/$key.txt');

void _reset() {
  for (final key in [alarmSortIndexKey, alarmSortMigrationKey]) {
    if (_file(key).existsSync()) _file(key).deleteSync();
  }
}

void main() {
  setUpAll(() async {
    final tmp = Directory.systemTemp.createTempSync('chrono_sort');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    await initializeAppDataDirectory();
  });

  test('time of day (earliest first) is sort option 5', () {
    expect(timeOfDayAscendingSortIndex, 5);
    expect(alarmSortOptions[timeOfDayAscendingSortIndex - 1].sortFunction,
        sortTimeOfDayAscending);
  });

  group('initAlarmSortDefault', () {
    setUp(_reset);

    test('new install gets time of day', () async {
      await initAlarmSortDefault();
      expect(loadTextFileSync(alarmSortIndexKey), '5');
    });

    test('existing install on upstream Default is moved once', () async {
      await saveTextFile(alarmSortIndexKey, '0');
      await initAlarmSortDefault();
      expect(loadTextFileSync(alarmSortIndexKey), '5');

      // Picking Default again afterwards is respected.
      await saveTextFile(alarmSortIndexKey, '0');
      await initAlarmSortDefault();
      expect(loadTextFileSync(alarmSortIndexKey), '0');
    });

    test('an explicitly chosen sort is kept', () async {
      await saveTextFile(alarmSortIndexKey, '3');
      await initAlarmSortDefault();
      expect(loadTextFileSync(alarmSortIndexKey), '3');
    });
  });

  testWidgets('alarm list stays ordered by time as alarms are added',
      (tester) async {
    final controller = ListController<Alarm>();
    final items = [
      Alarm(const Time(hour: 22, minute: 0)),
      Alarm(const Time(hour: 6, minute: 30)),
    ];
    await tester.pumpWidget(MaterialApp(
      theme: defaultTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CustomListView<Alarm>(
          items: items,
          listController: controller,
          itemBuilder: (alarm) => SizedBox(
              height: 60,
              child: Text('alarm ${alarm.time.hour}:${alarm.time.minute}')),
          sortOptions: alarmSortOptions,
          initialSortIndex: timeOfDayAscendingSortIndex,
          showSortControl: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    List<String> order() => tester
        .widgetList<Text>(find.textContaining('alarm '))
        .map((t) => t.data!)
        .toList();
    double y(String label) => tester.getTopLeft(find.text(label)).dy;

    expect(y('alarm 6:30'), lessThan(y('alarm 22:0')));
    expect(find.text('Sort'), findsNothing);

    controller.addItem(Alarm(const Time(hour: 12, minute: 15)));
    await tester.pumpAndSettle();
    expect(order().length, 3);
    expect(y('alarm 6:30'), lessThan(y('alarm 12:15')));
    expect(y('alarm 12:15'), lessThan(y('alarm 22:0')));
  });
}

// Renders the redesigned screens to PNG files for review.
//
// Only runs when golden files are being updated:
//   flutter test --update-goldens test/screenshots
// The PNGs are written to test/screenshots/goldens/, which is gitignored.
import 'dart:io';

import 'package:clock_app/alarm/screens/alarm_editor_screen.dart';
import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/alarm/widgets/alarm_card.dart';
import 'package:clock_app/common/types/time.dart';
import 'package:clock_app/common/widgets/card_container.dart';
import 'package:clock_app/icons/flux_icons.dart';
import 'package:clock_app/navigation/widgets/large_header.dart';
import 'package:clock_app/system/logic/reliability.dart';
import 'package:clock_app/system/screens/reliability_screen.dart';
import 'package:clock_app/clock/data/default_favorite_cities.dart';
import 'package:clock_app/clock/screens/clock_screen.dart';
import 'package:clock_app/common/utils/list_storage.dart';
import 'package:clock_app/navigation/widgets/app_navigation_bar.dart';
import 'package:clock_app/stopwatch/screens/stopwatch_screen.dart';
import 'package:clock_app/stopwatch/types/stopwatch.dart';
import 'package:clock_app/timer/screens/timer_screen.dart';
import 'package:clock_app/timer/types/timer.dart';
import 'package:clock_app/timer/types/time_duration.dart' as ctime;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:clock_app/theme/theme.dart';
import 'package:clock_app/common/utils/json_serialize.dart';
import 'package:clock_app/theme/utils/color_scheme.dart';
import 'package:clock_app/alarm/screens/alarm_notification_screen.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/settings/screens/settings_group_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clock_app/common/data/paths.dart';
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

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Widget _app(Widget home, {ThemeData? theme}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme ?? defaultTheme,
      home: home,
    );

Widget _tabScaffold(
    {required int index,
    required String title,
    String? subtitle,
    required Widget body,
    double collapse = 0}) {
  const expanded = 274.0; // about a third of a 915 dp tall phone
  return Builder(builder: (context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(expanded - (expanded - 56) * collapse),
        child: LargeHeader(
          title: title,
          subtitle: subtitle,
          collapse: collapse,
          expandedHeight: expanded,
          actions: [
            IconButton(
                onPressed: () {},
                icon: const Icon(FluxIcons.settings),
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.8))
          ],
        ),
      ),
      body: body,
      bottomNavigationBar:
          AppNavigationBar(selectedTabIndex: index, onTabSelected: (_) {}),
    );
  });
}

Widget _alarmTab(double collapse) {
  final alarms = [
    Alarm(const Time(hour: 6, minute: 30)),
    Alarm(const Time(hour: 7, minute: 15))
      ..setSettingWithoutNotify("Label", "Gym"),
    Alarm(const Time(hour: 22, minute: 0)),
  ];
  return Builder(builder: (context) {
    final schedule = alarms[1].settings.getGroup("Schedule");
    final type = schedule.getSetting("Type");
    type.setValueWithoutNotify(2); // weekly
    schedule
        .getSetting("Week Days")
        .setValueWithoutNotify([true, false, true, false, true, false, false]);
    alarms[2].settings.getGroup("Schedule").getSetting("Type")
        .setValueWithoutNotify(1); // daily
    return _tabScaffold(
      index: 0,
      title: "Alarm",
      subtitle: "Alarm in 8 hours 12 minutes",
      collapse: collapse,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final alarm in alarms)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: CardContainer(
                child: AlarmCard(
                  alarm: alarm,
                  onEnabledChange: (_) {},
                  onPressDelete: () {},
                  onPressDuplicate: () {},
                  onDismiss: () {},
                  onSkipChange: (_) {},
                ),
              ),
            ),
        ],
      ),
    );
  });
}

void main() {
  final bool enabled = autoUpdateGoldenFiles;

  setUpAll(() async {
    if (!enabled) return;
    final tmp = Directory.systemTemp.createTempSync('chrono_shots');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    await initializeAppDataDirectory();
    File('${getAppDataDirectoryPathSync()}/ringtones.txt').writeAsStringSync(
        '[{"id":1,"title":"Default","uri":"default","isDeletable":false,"type":"FileItemType.audio"}]');
    File('${getAppDataDirectoryPathSync()}/tags.txt').writeAsStringSync('[]');
    tzdata.initializeTimeZones();
    File('${getAppDataDirectoryPathSync()}/timer_presets.txt')
        .writeAsStringSync('[]');
    await saveList<ClockStopwatch>('stopwatches', [ClockStopwatch()]);
    final t1 = ClockTimer(const ctime.TimeDuration(minutes: 5))
      ..setSettingWithoutNotify("Label", "Tea");
    final t2 = ClockTimer(const ctime.TimeDuration(minutes: 25))
      ..setSettingWithoutNotify("Label", "Focus");
    await saveList<ClockTimer>('timers', [t1, t2]);
    await saveList('favorite_cities', initialFavoriteCities.take(3).toList());
    await _loadFont('Rubik', ['fonts/Rubik/Rubik-VariableFont.ttf']);
    await _loadFont('FluxIcons', ['fonts/FluxIcons.ttf']);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      await _loadFont('MaterialIcons', [
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'
      ]);
    }
  });

  Future<void> shoot(WidgetTester tester, Widget widget, String name,
      {Size size = const Size(412, 915)}) async {
    tester.view.physicalSize = size * 2.625;
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(widget);
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('alarm list, expanded header', (tester) async {
    await shoot(tester, _app(_alarmTab(0)), 'alarm_list_expanded');
  }, skip: !enabled);

  testWidgets('alarm list, collapsed header', (tester) async {
    await shoot(tester, _app(_alarmTab(1)), 'alarm_list_collapsed');
  }, skip: !enabled);

  testWidgets('add alarm screen', (tester) async {
    await shoot(
        tester,
        _app(AlarmEditorScreen(
            alarm: Alarm(const Time(hour: 7, minute: 30)), isNewAlarm: true)),
        'add_alarm',
        size: const Size(412, 1900));
  }, skip: !enabled);

  testWidgets('add alarm screen, advanced expanded', (tester) async {
    tester.view.physicalSize = const Size(412, 2600) * 2.625;
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(AlarmEditorScreen(
        alarm: Alarm(const Time(hour: 7, minute: 30)), isNewAlarm: true)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/add_alarm_advanced.png'));
    await tester.pump(const Duration(seconds: 1));
  }, skip: !enabled);

  testWidgets('stopwatch', (tester) async {
    await shoot(
        tester,
        _app(_tabScaffold(
            index: 2, title: "Stopwatch", body: const StopwatchScreen())),
        'stopwatch');
  }, skip: !enabled);

  testWidgets('timer', (tester) async {
    await shoot(
        tester,
        _app(_tabScaffold(index: 3, title: "Timer", body: const TimerScreen())),
        'timer');
  }, skip: !enabled);

  testWidgets('world clock', (tester) async {
    await shoot(
        tester,
        _app(_tabScaffold(
            index: 1,
            title: "Clock",
            subtitle: "Tuesday, November 10",
            body: const ClockScreen())),
        'world_clock');
  }, skip: !enabled);

  testWidgets('reliability setup screen', (tester) async {
    await shoot(
        tester,
        _app(ReliabilityScreen(service: _ShotReliabilityService())),
        'reliability_setup',
        size: const Size(412, 1500));
  }, skip: !enabled);

  // Dark mode (One UI Dark scheme, and Material You dark for comparison).
  ThemeData dark() => getTheme(colorSchemeData: defaultDarkColorScheme);
  ThemeData materialYouDark() => getTheme(
      colorScheme: withDistinctCards(ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A8CAF), brightness: Brightness.dark)));

  testWidgets('dark: alarm list', (tester) async {
    await shoot(tester, _app(_alarmTab(0), theme: dark()), 'alarm_list_dark');
  }, skip: !enabled);

  testWidgets('dark: alarm list, Material You', (tester) async {
    await shoot(tester, _app(_alarmTab(0), theme: materialYouDark()),
        'alarm_list_materialyou_dark');
  }, skip: !enabled);

  testWidgets('dark: add alarm', (tester) async {
    await shoot(
        tester,
        _app(
            AlarmEditorScreen(
                alarm: Alarm(const Time(hour: 7, minute: 30)),
                isNewAlarm: true),
            theme: dark()),
        'add_alarm_dark');
  }, skip: !enabled);

  for (final darkMode in [false, true]) {
    testWidgets('alarm edit sound switches, dark: $darkMode', (tester) async {
      await shoot(
          tester,
          _app(
              AlarmEditorScreen(
                  alarm: Alarm(const Time(hour: 7, minute: 30)),
                  isNewAlarm: true),
              theme: darkMode ? dark() : null),
          darkMode ? 'alarm_edit_sound_switches_dark' : 'alarm_edit_sound_switches',
          size: const Size(412, 1120));
      expect(find.text('Start at random point'), findsOneWidget);
      expect(find.text('Also ring on phone speaker'), findsOneWidget);
    }, skip: !enabled);
  }

  testWidgets('dark: timer', (tester) async {
    await shoot(
        tester,
        _app(_tabScaffold(index: 3, title: "Timer", body: const TimerScreen()),
            theme: dark()),
        'timer_dark');
  }, skip: !enabled);

  testWidgets('dark: stopwatch', (tester) async {
    await shoot(
        tester,
        _app(
            _tabScaffold(
                index: 2, title: "Stopwatch", body: const StopwatchScreen()),
            theme: dark()),
        'stopwatch_dark');
  }, skip: !enabled);

  testWidgets('dark: world clock', (tester) async {
    await shoot(
        tester,
        _app(
            _tabScaffold(
                index: 1,
                title: "Clock",
                subtitle: "Tuesday, November 10",
                body: const ClockScreen()),
            theme: dark()),
        'world_clock_dark');
  }, skip: !enabled);

  testWidgets('dark: reliability setup', (tester) async {
    await shoot(
        tester,
        _app(ReliabilityScreen(service: _ShotReliabilityService()),
            theme: dark()),
        'reliability_setup_dark',
        size: const Size(412, 1500));
  }, skip: !enabled);

  testWidgets('dark: settings', (tester) async {
    await shoot(
        tester,
        _app(SettingGroupScreen(settingGroup: appSettings), theme: dark()),
        'settings_dark',
        size: const Size(412, 1300));
  }, skip: !enabled);

  testWidgets('light: settings', (tester) async {
    await shoot(tester, _app(SettingGroupScreen(settingGroup: appSettings)),
        'settings', size: const Size(412, 1300));
  }, skip: !enabled);

  testWidgets('dark: alarm ringing', (tester) async {
    final alarm = Alarm(const Time(hour: 7, minute: 30))
      ..setSettingWithoutNotify("Label", "Wake up");
    // Written directly: the storage queue may be busy with earlier tests.
    File('${getAppDataDirectoryPathSync()}/alarms.txt')
        .writeAsStringSync(listToString<Alarm>([alarm]));
    await shoot(tester,
        _app(AlarmNotificationScreen(scheduleId: alarm.id), theme: dark()),
        'alarm_ringing_dark');
  }, skip: !enabled);

  test('editor places every alarm setting', () {
    // Sanity check that the schema still has the sections the editor uses.
    final alarm = Alarm(const Time(hour: 7, minute: 30));
    final s = alarm.settings;
    expect(s.getSetting("Label"), isNotNull);
    expect(s.getGroup("Schedule"), isNotNull);
    expect(s.getGroup("Sound and Vibration").getGroup("Sound"), isNotNull);
    expect(s.getGroup("Snooze").getGroup("While Snoozed"), isNotNull);
    expect(s.getSetting("Tasks"), isNotNull);
    expect(s.getSetting("Tags"), isNotNull);
  });
}

class _ShotReliabilityService extends ReliabilityService {
  @override
  Future<ReliabilityStatus> getStatus() async => const ReliabilityStatus(
        sdk: 34,
        manufacturer: "samsung",
        notifications: true,
        exactAlarms: true,
        fullScreenIntent: false,
        batteryOptimization: false,
        autoRevoke: true,
      );
  @override
  bool isManualDone(String id) => id == samsungAppBatteryItem;
}

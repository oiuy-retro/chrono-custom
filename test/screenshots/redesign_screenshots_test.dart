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
import 'package:clock_app/theme/theme.dart';
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

Widget _alarmTab(double collapse) {
  final alarms = [
    Alarm(const Time(hour: 6, minute: 30)),
    Alarm(const Time(hour: 7, minute: 15))
      ..setSettingWithoutNotify("Label", "Gym"),
    Alarm(const Time(hour: 22, minute: 0)),
  ];
  return Builder(builder: (context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(152 - 96 * collapse),
        child: LargeHeader(
          title: "Alarm",
          subtitle: "Alarm in 8 hours 12 minutes",
          collapse: collapse,
          expandedHeight: 152,
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(FluxIcons.settings))
          ],
        ),
      ),
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
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(FluxIcons.alarm), label: "Alarm"),
          NavigationDestination(icon: Icon(FluxIcons.clock), label: "Clock"),
          NavigationDestination(
              icon: Icon(FluxIcons.stopwatch), label: "Stopwatch"),
          NavigationDestination(icon: Icon(FluxIcons.timer), label: "Timer"),
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

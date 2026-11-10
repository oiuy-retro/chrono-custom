import 'package:clock_app/system/logic/reliability.dart';
import 'package:clock_app/system/screens/reliability_screen.dart';
import 'package:clock_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReliabilityService extends ReliabilityService {
  FakeReliabilityService(this.status);
  ReliabilityStatus status;
  final List<String> opened = [];
  final Map<String, bool> done = {};

  @override
  Future<ReliabilityStatus> getStatus() async => status;
  @override
  Future<void> open(String id) async => opened.add(id);
  @override
  bool isManualDone(String id) => done[id] ?? false;
  @override
  Future<void> setManualDone(String id, bool value) async => done[id] = value;
}

const samsungBad = ReliabilityStatus(
  sdk: 34,
  manufacturer: "samsung",
  notifications: true,
  exactAlarms: false,
  fullScreenIntent: false,
  batteryOptimization: false,
  autoRevoke: true,
);

Widget app(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: defaultTheme,
      home: home,
    );

void main() {
  group('buildReliabilityItems', () {
    test('hides items the Android version does not have', () {
      final items = buildReliabilityItems(
          const ReliabilityStatus(sdk: 29, manufacturer: "Google"), (_) => false);
      expect(items.map((i) => i.id), ["notifications", "batteryOptimization"]);
    });

    test('adds manual Samsung items only on Samsung', () {
      final items = buildReliabilityItems(samsungBad, (_) => false);
      expect(items.map((i) => i.id), [
        "notifications",
        "exactAlarms",
        "fullScreenIntent",
        "batteryOptimization",
        "autoRevoke",
        samsungAppBatteryItem,
        samsungSleepingItem,
      ]);
      expect(items.where((i) => i.isManual).length, 2);
    });

    test('fromMap treats missing values as OK', () {
      final s = ReliabilityStatus.fromMap({"sdk": 33, "exactAlarms": false});
      expect(s.sdk, 33);
      expect(s.exactAlarms, false);
      expect(s.notifications, true);
    });
  });

  testWidgets('shows Samsung title and statuses', (tester) async {
    tester.view.physicalSize = const Size(1080, 7000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final service = FakeReliabilityService(samsungBad);
    await tester.pumpWidget(app(ReliabilityScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.text("Set up for Samsung"), findsOneWidget);
    expect(find.text("Needs fixing"), findsNWidgets(3));
    expect(find.text("Check manually"), findsNWidgets(2));
  });

  testWidgets('Fix all opens unmet items one at a time on resume',
      (tester) async {
    final service = FakeReliabilityService(samsungBad);
    await tester.pumpWidget(app(ReliabilityScreen(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Fix all"));
    await tester.pumpAndSettle();
    expect(service.opened, ["exactAlarms"]);

    service.status = const ReliabilityStatus(
        sdk: 34,
        manufacturer: "samsung",
        fullScreenIntent: false,
        batteryOptimization: false);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(service.opened, ["exactAlarms", "fullScreenIntent"]);
  });

  testWidgets('generic title on other phones', (tester) async {
    final service = FakeReliabilityService(
        const ReliabilityStatus(sdk: 34, manufacturer: "Google"));
    await tester.pumpWidget(app(ReliabilityScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.text("Alarm reliability"), findsOneWidget);
    expect(find.text("Everything is set up"), findsOneWidget);
  });
}

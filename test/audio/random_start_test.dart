import 'dart:io';
import 'dart:math';

import 'package:clock_app/alarm/logic/alarm_defaults_migration.dart';
import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/audio/logic/random_start.dart';
import 'package:clock_app/common/data/paths.dart';
import 'package:clock_app/common/types/time.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:speaker_output/speaker_output.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);
  final String root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('randomStartPosition', () {
    test('unknown or short sounds start at 0', () {
      expect(randomStartPosition(null), Duration.zero);
      expect(randomStartPosition(const Duration(seconds: 5)), Duration.zero);
      expect(randomStartPosition(const Duration(seconds: 19)), Duration.zero);
    });

    test('never in the last 15 seconds or the last 20%', () {
      final random = Random(1);
      for (final seconds in [20, 30, 60, 75, 180, 600]) {
        final length = Duration(seconds: seconds);
        final latest = Duration(
            milliseconds: min(length.inMilliseconds - 15000,
                (length.inMilliseconds * 0.8).floor()));
        for (int i = 0; i < 500; i++) {
          final start = randomStartPosition(length, random);
          expect(start >= Duration.zero, true);
          expect(start <= latest, true, reason: '$start of $length');
        }
      }
    });

    test('positions are spread across the allowed range', () {
      final random = Random(7);
      const length = Duration(minutes: 3);
      final starts =
          List.generate(400, (_) => randomStartPosition(length, random));
      expect(starts.any((s) => s < const Duration(seconds: 30)), true);
      expect(starts.any((s) => s > const Duration(seconds: 120)), true);
    });
  });

  group('alarm settings', () {
    setUpAll(() async {
      final tmp = Directory.systemTemp.createTempSync('chrono_random');
      PathProviderPlatform.instance = _FakePathProvider(tmp.path);
      await initializeAppDataDirectory();
      await GetStorage.init();
    });

    test('new alarms start at a random point and do not use the speaker copy',
        () {
      final alarm = Alarm(const Time(hour: 7, minute: 0));
      expect(alarm.shouldStartMelodyAtRandomPos, true);
      expect(alarm.alsoRingOnPhoneSpeaker, false);
    });

    test('saved alarms without the new setting load with it off', () {
      final alarm = Alarm(const Time(hour: 7, minute: 0));
      final json = alarm.toJson()!;
      final sound = json['settings']['Sound and Vibration']['Sound'] as Map;
      sound.remove('also_ring_on_phone_speaker');
      sound['start_melody_at_random_pos'] = false;
      final loaded = Alarm.fromJson(json);
      expect(loaded.alsoRingOnPhoneSpeaker, false);
      expect(loaded.shouldStartMelodyAtRandomPos, false);
    });

    test('existing installs get random start on in the new-alarm template',
        () async {
      final storage = GetStorage();
      await storage.remove(randomStartDefaultMigrationKey);
      final setting = appSettings
          .getGroup("Alarm")
          .getGroup("Default Settings")
          .getGroup("Sound and Vibration")
          .getGroup("Sound")
          .getSetting("start_melody_at_random_pos");
      setting.setValueWithoutNotify(false);
      await migrateAlarmDefaults(storage: storage);
      expect(setting.value, true);
      // Runs only once: turning it off afterwards is kept.
      setting.setValueWithoutNotify(false);
      await migrateAlarmDefaults(storage: storage);
      expect(setting.value, false);
      setting.setValueWithoutNotify(true);
    });
  });

  group('SpeakerOutput', () {
    const channel = MethodChannel('com.oiuyretro.chrono/speaker_output');
    final calls = <String>[];

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      calls.clear();
    });

    test('is a safe no-op when the native side is missing', () async {
      expect(await SpeakerOutput.isBluetoothOutputConnected(), false);
      expect(await SpeakerOutput.start('content://x'), false);
      await SpeakerOutput.stop();
    });

    test('passes uri, start point and volume to the native player', () async {
      Map? startArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'status') return {'bluetoothOutput': true};
        if (call.method == 'start') {
          startArgs = call.arguments as Map;
          return true;
        }
        return null;
      });
      expect(await SpeakerOutput.isBluetoothOutputConnected(), true);
      expect(
          await SpeakerOutput.start('content://media/1',
              position: const Duration(seconds: 42), volume: 0.5),
          true);
      expect(startArgs, {
        'uri': 'content://media/1',
        'positionMs': 42000,
        'volume': 0.5,
      });
      await SpeakerOutput.setVolume(1);
      await SpeakerOutput.stop();
      expect(calls, ['status', 'start', 'setVolume', 'stop']);
    });
  });
}

import 'package:flutter/services.dart';

/// Second copy of the alarm sound on the phone's built-in speaker, used while
/// Bluetooth audio is connected. Android only; every call is a safe no-op
/// elsewhere (and in tests).
class SpeakerOutput {
  static const MethodChannel _channel =
      MethodChannel('com.oiuyretro.chrono/speaker_output');

  static void Function()? _onBluetoothDisconnected;

  /// Called when the last Bluetooth output goes away while the speaker copy
  /// is playing.
  static set onBluetoothDisconnected(void Function()? callback) {
    _onBluetoothDisconnected = callback;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'bluetoothDisconnected') {
        _onBluetoothDisconnected?.call();
      }
      return null;
    });
  }

  /// Whether a Bluetooth audio output (A2DP, SCO, LE audio or hearing aid) is
  /// connected. False when it cannot be checked (Android 5).
  static Future<bool> isBluetoothOutputConnected() async {
    try {
      final status = await _channel.invokeMapMethod<String, dynamic>('status');
      return status?['bluetoothOutput'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Starts the speaker copy, looping, at [position]. Completes once it is
  /// playing; returns false if it could not be started.
  static Future<bool> start(String uri,
      {Duration position = Duration.zero, double volume = 1.0}) async {
    try {
      return await _channel.invokeMethod<bool>('start', {
            'uri': uri,
            'positionMs': position.inMilliseconds,
            'volume': volume,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setVolume(double volume) => _call('setVolume', {
        'volume': volume,
      });
  static Future<void> pause() => _call('pause');
  static Future<void> stop() => _call('stop');

  static Future<void> _call(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod(method, args);
    } catch (_) {}
  }
}

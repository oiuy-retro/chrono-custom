import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:flutter/services.dart';

/// Touch feedback in the style of Samsung One UI, in one place.
///
/// Uses Flutter's [HapticFeedback], which on Android calls
/// `View.performHapticFeedback`. Android skips that when the system
/// "Touch feedback" / "Touch interactions" vibration setting is off, so the
/// system setting is respected. The in-app "Vibration feedback" setting
/// (Accessibility) can turn it off for this app only.
class Haptics {
  Haptics._();

  /// Set by tests to check which feedback was requested.
  static void Function(String kind)? debugOnFeedback;

  static bool get enabled {
    try {
      return appSettings
          .getGroup("Accessibility")
          .getSetting("Vibration Feedback")
          .value as bool;
    } catch (_) {
      return true;
    }
  }

  static void _run(String kind, Future<void> Function() feedback) {
    if (!enabled) return;
    debugOnFeedback?.call(kind);
    feedback().catchError((_) {});
  }

  /// Light tick: each step of a time or number spinner.
  static void tick() => _run("tick", HapticFeedback.selectionClick);

  /// Toggles: switches, checkboxes, day chips, tab changes.
  static void toggle() => _run("toggle", HapticFeedback.lightImpact);

  /// Button presses such as start, stop, lap and reset.
  static void button() => _run("button", HapticFeedback.lightImpact);

  /// Stronger: long-press into select mode, delete, swipe actions.
  static void heavy() => _run("heavy", HapticFeedback.mediumImpact);
}

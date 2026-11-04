import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

/// One thing that must be set up for alarms to ring reliably.
class ReliabilityItem {
  const ReliabilityItem({
    required this.id,
    required this.isManual,
    required this.isOk,
  });

  /// Stable id, also used as the argument for the Android side.
  final String id;

  /// True when Android gives no way to read the setting, so the user has to
  /// check it and tick "Done" themselves.
  final bool isManual;

  /// For automatic items: the live status. For manual items: whether the user
  /// ticked "Done".
  final bool isOk;
}

/// Raw status as reported by the platform.
class ReliabilityStatus {
  const ReliabilityStatus({
    this.sdk = 0,
    this.manufacturer = "",
    this.notifications = true,
    this.exactAlarms = true,
    this.fullScreenIntent = true,
    this.batteryOptimization = true,
    this.autoRevoke = true,
  });

  final int sdk;
  final String manufacturer;
  final bool notifications;
  final bool exactAlarms;
  final bool fullScreenIntent;
  final bool batteryOptimization;
  final bool autoRevoke;

  bool get isSamsung => manufacturer.toLowerCase().contains("samsung");

  factory ReliabilityStatus.fromMap(Map<dynamic, dynamic> map) {
    bool b(String key) => map[key] is bool ? map[key] as bool : true;
    return ReliabilityStatus(
      sdk: map["sdk"] is int ? map["sdk"] as int : 0,
      manufacturer: map["manufacturer"]?.toString() ?? "",
      notifications: b("notifications"),
      exactAlarms: b("exactAlarms"),
      fullScreenIntent: b("fullScreenIntent"),
      batteryOptimization: b("batteryOptimization"),
      autoRevoke: b("autoRevoke"),
    );
  }
}

/// Ids of the manual Samsung items.
const samsungAppBatteryItem = "samsungAppBattery";
const samsungSleepingItem = "samsungSleeping";

/// Builds the ordered list of items that apply to this device.
List<ReliabilityItem> buildReliabilityItems(
    ReliabilityStatus status, bool Function(String id) isManualDone) {
  final items = <ReliabilityItem>[
    ReliabilityItem(
        id: "notifications", isManual: false, isOk: status.notifications),
    if (status.sdk >= 31)
      ReliabilityItem(
          id: "exactAlarms", isManual: false, isOk: status.exactAlarms),
    if (status.sdk >= 34)
      ReliabilityItem(
          id: "fullScreenIntent",
          isManual: false,
          isOk: status.fullScreenIntent),
    ReliabilityItem(
        id: "batteryOptimization",
        isManual: false,
        isOk: status.batteryOptimization),
    if (status.sdk >= 30)
      ReliabilityItem(id: "autoRevoke", isManual: false, isOk: status.autoRevoke),
    if (status.isSamsung) ...[
      ReliabilityItem(
          id: samsungAppBatteryItem,
          isManual: true,
          isOk: isManualDone(samsungAppBatteryItem)),
      ReliabilityItem(
          id: samsungSleepingItem,
          isManual: true,
          isOk: isManualDone(samsungSleepingItem)),
    ],
  ];
  return items;
}

/// Talks to the Android side. Replaceable in tests.
class ReliabilityService {
  static const _channel = MethodChannel('com.vicolo.chrono/reliability');
  static const _storagePrefix = "reliability_done_";
  static const _shownKey = "reliability_setup_shown";

  Future<ReliabilityStatus> getStatus() async {
    try {
      final map = await _channel.invokeMethod<Map>('getStatus');
      return ReliabilityStatus.fromMap(map ?? {});
    } catch (e) {
      debugPrint("Reliability status unavailable: $e");
      return const ReliabilityStatus();
    }
  }

  Future<void> open(String id) async {
    if (id == "notifications") {
      try {
        final status = await Permission.notification.request();
        if (status.isGranted) return;
      } catch (_) {}
    }
    try {
      await _channel.invokeMethod('open', {"item": id});
    } catch (e) {
      debugPrint("Could not open settings for $id: $e");
    }
  }

  bool isManualDone(String id) {
    try {
      return GetStorage().read<bool>("$_storagePrefix$id") ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setManualDone(String id, bool value) async {
    try {
      await GetStorage().write("$_storagePrefix$id", value);
    } catch (_) {}
  }

  bool get wasSetupShown {
    try {
      return GetStorage().read<bool>(_shownKey) ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> markSetupShown() async {
    try {
      await GetStorage().write(_shownKey, true);
    } catch (_) {}
  }

  Future<List<ReliabilityItem>> getItems() async {
    final status = await getStatus();
    return buildReliabilityItems(status, isManualDone);
  }
}

ReliabilityService reliabilityService = ReliabilityService();

/// Bumped when the reliability status may have changed, so the alarm tab
/// banner can refresh.
final ValueNotifier<int> reliabilityRevision = ValueNotifier<int>(0);

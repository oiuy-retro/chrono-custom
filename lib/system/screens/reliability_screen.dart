import 'package:clock_app/common/widgets/card_container.dart';
import 'package:clock_app/system/logic/reliability.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String reliabilityItemTitle(BuildContext context, String id) {
  final l = AppLocalizations.of(context)!;
  return switch (id) {
    "notifications" => l.reliabilityItemNotifications,
    "exactAlarms" => l.reliabilityItemExactAlarms,
    "fullScreenIntent" => l.reliabilityItemFullScreenIntent,
    "batteryOptimization" => l.reliabilityItemBatteryOptimization,
    "autoRevoke" => l.reliabilityItemAutoRevoke,
    samsungAppBatteryItem => l.reliabilityItemSamsungAppBattery,
    samsungSleepingItem => l.reliabilityItemSamsungSleeping,
    _ => id,
  };
}

String reliabilityItemDescription(BuildContext context, String id) {
  final l = AppLocalizations.of(context)!;
  return switch (id) {
    "notifications" => l.reliabilityItemNotificationsDescription,
    "exactAlarms" => l.reliabilityItemExactAlarmsDescription,
    "fullScreenIntent" => l.reliabilityItemFullScreenIntentDescription,
    "batteryOptimization" => l.reliabilityItemBatteryOptimizationDescription,
    "autoRevoke" => l.reliabilityItemAutoRevokeDescription,
    samsungAppBatteryItem => l.reliabilityItemSamsungAppBatteryDescription,
    samsungSleepingItem => l.reliabilityItemSamsungSleepingDescription,
    _ => "",
  };
}

/// Lists the settings alarms depend on, with a live status and a Fix button
/// for each, and a "Fix all" button that opens the unmet ones in order.
/// Status is re-read every time the app comes back to the foreground.
class ReliabilityScreen extends StatefulWidget {
  const ReliabilityScreen({super.key, this.service});

  final ReliabilityService? service;

  @override
  State<ReliabilityScreen> createState() => _ReliabilityScreenState();
}

class _ReliabilityScreenState extends State<ReliabilityScreen>
    with WidgetsBindingObserver {
  late final ReliabilityService _service = widget.service ?? reliabilityService;
  ReliabilityStatus? _status;
  List<ReliabilityItem> _items = [];

  // "Fix all" queue: ids still to open, in order.
  List<String>? _fixAllQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    reliabilityRevision.value++;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh().then((_) => _continueFixAll());
    }
  }

  Future<void> _refresh() async {
    final status = await _service.getStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _items = buildReliabilityItems(status, _service.isManualDone);
    });
    reliabilityRevision.value++;
  }

  Future<void> _fix(String id) => _service.open(id);

  Future<void> _startFixAll() async {
    _fixAllQueue = _items.where((i) => !i.isOk).map((i) => i.id).toList();
    await _continueFixAll();
  }

  Future<void> _continueFixAll() async {
    final queue = _fixAllQueue;
    if (queue == null) return;
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      final item = _items.where((i) => i.id == id).firstOrNull;
      if (item == null || item.isOk) continue;
      await _fix(id);
      // Notification permission can be granted by an in-app dialog without
      // leaving the app, so refresh and keep going.
      if (id == "notifications") {
        await _refresh();
        continue;
      }
      return; // Wait for the user to come back (onResume).
    }
    _fixAllQueue = null;
  }

  Future<void> _setDone(String id, bool value) async {
    await _service.setManualDone(id, value);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bool isSamsung = _status?.isSamsung ?? false;
    final bool allOk = _items.isNotEmpty && _items.every((i) => i.isOk);
    const okColor = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSamsung ? l.reliabilitySamsungTitle : l.reliabilityTitle),
      ),
      body: _status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(l.reliabilityIntro,
                    style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: allOk ? null : _startFixAll,
                    icon: Icon(allOk
                        ? Icons.check_circle_rounded
                        : Icons.build_rounded),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(allOk ? l.reliabilityAllSet : l.reliabilityFixAll),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in _items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: CardContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.isOk
                                  ? Icons.check_circle_rounded
                                  : item.isManual
                                      ? Icons.help_rounded
                                      : Icons.error_rounded,
                              color: item.isOk
                                  ? okColor
                                  : item.isManual
                                      ? Colors.orange.shade700
                                      : colorScheme.error,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(reliabilityItemTitle(context, item.id),
                                      style: textTheme.titleMedium),
                                  const SizedBox(height: 2),
                                  Text(
                                      item.isOk
                                          ? l.reliabilityStatusOk
                                          : item.isManual
                                              ? l.reliabilityStatusCheckManually
                                              : l.reliabilityStatusNeedsFix,
                                      style: textTheme.labelMedium?.copyWith(
                                          color: item.isOk
                                              ? okColor
                                              : item.isManual
                                                  ? Colors.orange.shade800
                                                  : colorScheme.error)),
                                  const SizedBox(height: 4),
                                  Text(
                                      reliabilityItemDescription(
                                          context, item.id),
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.7))),
                                  if (item.isManual)
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: item.isOk,
                                          onChanged: (v) =>
                                              _setDone(item.id, v ?? false),
                                        ),
                                        Text(l.reliabilityDone),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            if (!item.isOk || item.isManual)
                              TextButton(
                                onPressed: () => _fix(item.id),
                                child: Text(item.isManual
                                    ? l.reliabilityOpen
                                    : l.reliabilityFix),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Banner shown on the Alarm tab when any reliability item is not OK.
class ReliabilityBanner extends StatefulWidget {
  const ReliabilityBanner({super.key, this.service});

  final ReliabilityService? service;

  @override
  State<ReliabilityBanner> createState() => _ReliabilityBannerState();
}

class _ReliabilityBannerState extends State<ReliabilityBanner>
    with WidgetsBindingObserver {
  late final ReliabilityService _service = widget.service ?? reliabilityService;
  bool _hasProblem = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reliabilityRevision.addListener(_check);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    reliabilityRevision.removeListener(_check);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final items = await _service.getItems();
    if (!mounted) return;
    final problem = items.any((i) => !i.isOk);
    if (problem != _hasProblem) setState(() => _hasProblem = problem);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasProblem) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ReliabilityScreen(service: widget.service))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: colorScheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l.reliabilityBanner,
                      style: TextStyle(color: colorScheme.onErrorContainer)),
                ),
                Text(l.reliabilityFix,
                    style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:isolate';

import 'package:clock_app/alarm/logic/new_alarm_snackbar.dart';
import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/common/utils/snackbar.dart';
import 'package:clock_app/common/widgets/card_container.dart';
import 'package:clock_app/icons/flux_icons.dart';
import 'package:clock_app/navigation/data/tabs.dart';
import 'package:clock_app/navigation/types/quick_action_controller.dart';
import 'package:clock_app/navigation/widgets/app_navigation_bar.dart';
import 'package:clock_app/navigation/widgets/large_header.dart';
import 'package:clock_app/alarm/utils/next_alarm.dart';
import 'package:clock_app/settings/types/listener_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:clock_app/settings/data/general_settings_schema.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/settings/screens/settings_group_screen.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:clock_app/system/logic/handle_intents.dart';
import 'package:clock_app/system/logic/quick_actions.dart';
import 'package:clock_app/theme/types/theme_extension.dart';
import 'package:clock_app/system/logic/reliability.dart';
import 'package:clock_app/system/screens/reliability_screen.dart';
import 'package:clock_app/common/utils/haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:material_color_utilities/palettes/tonal_palette.dart';
import 'package:receive_intent/receive_intent.dart' as intent_handler;

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  SendPort? _sendPort;

  // Called when the task is started.
  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp("/");
  }
}

class NavScaffold extends StatefulWidget {
  const NavScaffold({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends State<NavScaffold> {
  late int _selectedTabIndex;
  late Setting swipeActionSetting;
  late Setting showForegroundSetting;
  late StreamSubscription _sub;
  late PageController _controller;
  QuickActionController quickActionController = QuickActionController();
  final Map<int, double> _scrollOffsets = {};
  Timer? _headerTimer;

  // One UI: the expanded app bar takes roughly the top third of the screen.
  double _expandedHeaderHeight = 220;
  static const double _collapsedHeaderHeight = 56;
  double get _collapseDistance =>
      _expandedHeaderHeight - _collapsedHeaderHeight;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is! ScrollUpdateNotification &&
        notification is! OverscrollNotification) {
      return false;
    }
    final double offset = notification.metrics.pixels
        .clamp(0.0, _collapseDistance)
        .toDouble();
    if ((_scrollOffsets[_selectedTabIndex] ?? 0) != offset) {
      setState(() {
        _scrollOffsets[_selectedTabIndex] = offset;
      });
    }
    return false;
  }

  void _onAlarmListChanged() {
    if (mounted) setState(() {});
  }

  String? _getHeaderSubtitle(BuildContext context, String tabId) {
    final localizations = AppLocalizations.of(context)!;
    if (tabId == "alarm") {
      final Alarm? alarm = getNextUpcomingAlarm();
      if (alarm == null) return localizations.allAlarmsOffHeader;
      return localizations
          .alarmRingsInHeader(getRemainingAlarmTimeText(context, alarm));
    }
    if (tabId == "clock") {
      return DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString())
          .format(DateTime.now());
    }
    return null;
  }

  SystemUiOverlayStyle _overlayStyle(BuildContext context, Color? navColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color systemNavigationBarColor = navColor ?? colorScheme.background;
    return SystemUiOverlayStyle(
      systemNavigationBarColor: systemNavigationBarColor,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          systemNavigationBarColor.computeLuminance() > 0.179
              ? Brightness.dark
              : Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: colorScheme.surface.computeLuminance() > 0.179
          ? Brightness.dark
          : Brightness.light,
    );
  }

  void _onTabSelected(int index, [String? tabInitAction]) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    if (index != _selectedTabIndex) Haptics.toggle();

    setState(() {
      _controller.jumpToPage(index);
      _selectedTabIndex = index;
    });

    if (tabInitAction != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        quickActionController.callAction(tabInitAction);
      });
    }
  }

  void _handlePageViewChanged(int currentPageIndex) {
    if (currentPageIndex != _selectedTabIndex) Haptics.toggle();
    setState(() {
      _selectedTabIndex = currentPageIndex;
    });
  }

  void update(dynamic value) {
    setState(() {});
  }

  _showNextScheduleSnackBar(Alarm alarm) {
    Future.delayed(Duration.zero).then((value) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      DateTime? nextScheduleDateTime = alarm.currentScheduleDateTime;
      if (nextScheduleDateTime == null) return;
      ScaffoldMessenger.of(context).showSnackBar(getThemedSnackBar(
          context, getNewAlarmText(context, alarm),
          fab: true, navBar: true));
    });
  }

  Future<void> initReceiveIntent() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      final receivedIntent =
          await intent_handler.ReceiveIntent.getInitialIntent();
      if (mounted) {
        handleIntent(
            receivedIntent, context, _showNextScheduleSnackBar, _onTabSelected);
      }
    } on PlatformException {
      // Handle exception
    }

    _sub = intent_handler.ReceiveIntent.receivedIntentStream.listen(
        (intent_handler.Intent? receivedIntent) {
      if (receivedIntent != null) {
        handleIntent(
            receivedIntent, context, _showNextScheduleSnackBar, _onTabSelected);
      }
      // Validate receivedIntent and warn the user, if it is not correct,
    }, onError: (err) {
      // Handle exception
    });
  }

  Future<bool> _updateForegroundNotification(dynamic value) async {
    if (!value) {
      return FlutterForegroundTask.stopService();
    }
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.updateService(
        notificationTitle: 'Foreground service is running',
        notificationText: '',
        callback: startCallback,
      );
    } else {
      return FlutterForegroundTask.startService(
        notificationTitle: 'Foreground service is running',
        notificationText: '',
        callback: startCallback,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    initializeQuickActions(context, _onTabSelected);
    initReceiveIntent();

    swipeActionSetting =
        appSettings.getGroup("General").getSetting("Swipe Action");
    showForegroundSetting = appSettings
        .getGroup("General")
        .getGroup("Reliability")
        .getSetting("Show Foreground Notification");
    swipeActionSetting.addListener(update);
    showForegroundSetting.addListener(_updateForegroundNotification);
    _controller = PageController(initialPage: widget.initialTabIndex);
    _selectedTabIndex = widget.initialTabIndex;

    _updateForegroundNotification(showForegroundSetting.value);

    // Open the reliability setup once, on the first launch after install.
    if (!reliabilityService.wasSetupShown) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        await reliabilityService.markSetupShown();
        if (!mounted) return;
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ReliabilityScreen()));
      });
    }

    alarmListRevision.addListener(_onAlarmListChanged);
    ListenerManager.addOnChangeListener("alarms", _onAlarmListChanged);
    // Keep the "Alarm in X h Y min" header current.
    _headerTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _onAlarmListChanged());
  }

  @override
  void dispose() {
    swipeActionSetting.removeListener(update);
    showForegroundSetting.removeListener(_updateForegroundNotification);
    _sub.cancel();
    _headerTimer?.cancel();
    alarmListRevision.removeListener(_onAlarmListChanged);
    ListenerManager.removeOnChangeListener("alarms", _onAlarmListChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;
    final tabs = getTabs(context, quickActionController);
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    ThemeSettingExtension themeSettings =
        theme.extension<ThemeSettingExtension>()!;
    ColorScheme colorScheme = theme.colorScheme;

    TonalPalette tonalPalette = toTonalPalette(colorScheme.surface.value);

    Color materialNavColor = themeSettings.useMaterialYou
        ? Color(tonalPalette
            .get(Theme.of(context).brightness == Brightness.light ? 96 : 15))
        : colorScheme.surface;

    final Size screenSize = MediaQuery.of(context).size;
    _expandedHeaderHeight = orientation == Orientation.portrait
        ? (screenSize.height * 0.3).clamp(160.0, 320.0)
        : _collapsedHeaderHeight;
    final double collapse =
        ((_scrollOffsets[_selectedTabIndex] ?? 0) / _collapseDistance)
            .clamp(0.0, 1.0);
    final double headerHeight = MediaQuery.of(context).padding.top +
        _expandedHeaderHeight -
        (_expandedHeaderHeight - _collapsedHeaderHeight) * collapse;
    final Widget settingsButton = IconButton(
      onPressed: () {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    SettingGroupScreen(settingGroup: appSettings)));
      },
      icon: const Icon(FluxIcons.settings, semanticLabel: "Settings"),
      color: colorScheme.onSurface.withOpacity(0.8),
    );

    return WithForegroundTask(
      child: Scaffold(
        appBar: orientation == Orientation.portrait
            ? PreferredSize(
                preferredSize: Size.fromHeight(headerHeight),
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: _overlayStyle(context,
                      themeSettings.useMaterialStyle ? materialNavColor : null),
                  child: SafeArea(
                    bottom: false,
                    child: LargeHeader(
                      title: tabs[_selectedTabIndex].title,
                      subtitle: _getHeaderSubtitle(
                          context, tabs[_selectedTabIndex].id),
                      collapse: collapse,
                      expandedHeight: _expandedHeaderHeight,
                      collapsedHeight: _collapsedHeaderHeight,
                      actions: [settingsButton],
                    ),
                  ),
                ),
              )
            : null,
        bottomNavigationBar: orientation == Orientation.portrait
            ? themeSettings.useMaterialStyle
                ? NavigationBar(
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    selectedIndex: _selectedTabIndex,
                    backgroundColor: materialNavColor,
                    onDestinationSelected: _onTabSelected,
                    destinations: <Widget>[
                      for (final tab in tabs)
                        NavigationDestination(
                          icon: Icon(tab.icon),
                          label: tab.title,
                        )
                    ],
                  )
                : AppNavigationBar(
                    selectedTabIndex: _selectedTabIndex,
                    onTabSelected: _onTabSelected,
                  )
            : null,
        extendBody: false,
        body: SafeArea(
          child: Row(
            children: [
              if (orientation == Orientation.landscape)
                NavigationRail(
                  destinations: [
                    for (final tab in tabs)
                      NavigationRailDestination(
                        icon: Icon(tab.icon),
                        label: Text(tab.title),
                      )
                  ],
                  leading: Text(tabs[_selectedTabIndex].title,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.6),
                      )),
                  trailing: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SettingGroupScreen(
                                  settingGroup: appSettings)));
                    },
                    icon: const Icon(FluxIcons.settings,
                        semanticLabel: "Settings"),
                    color: colorScheme.onBackground.withOpacity(0.8),
                  ),
                  selectedIndex: _selectedTabIndex,
                  onDestinationSelected: _onTabSelected,
                ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: PageView(
                    controller: _controller,
                    onPageChanged: _handlePageViewChanged,
                    physics: swipeActionSetting.value == SwipeAction.cardActions
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    children: tabs.map((tab) => tab.widget).toList()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

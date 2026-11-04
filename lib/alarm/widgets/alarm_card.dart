import 'package:clock_app/alarm/logic/schedule_description.dart';
import 'package:clock_app/alarm/logic/time_icon.dart';
import 'package:clock_app/alarm/screens/alarm_notification_screen.dart';
import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/alarm/types/time_of_day_icon.dart';
import 'package:clock_app/clock/types/time.dart';
import 'package:clock_app/common/types/popup_action.dart';
import 'package:clock_app/common/utils/popup_action.dart';
import 'package:clock_app/common/widgets/card_edit_menu.dart';
import 'package:clock_app/common/widgets/clock/digital_clock_display.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AlarmCard extends StatefulWidget {
  const AlarmCard({
    super.key,
    required this.onEnabledChange,
    required this.alarm,
    required this.onPressDelete,
    required this.onPressDuplicate,
    required this.onDismiss,
    required this.onSkipChange,
  });

  final Alarm alarm;
  final void Function(bool) onEnabledChange;
  final void Function() onDismiss;
  final void Function(bool) onSkipChange;
  final VoidCallback onPressDelete;
  final VoidCallback onPressDuplicate;

  @override
  State<AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard> {
  late String dateFormat;
  late TimeFormat timeFormat;

  late Setting dateFormatSetting;
  late Setting timeFormatSetting;

  void setDateFormat(dynamic newDateFormat) {
    setState(() {
      dateFormat = newDateFormat;
    });
  }

  void setTimeFormat(dynamic newTimeFormat) {
    setState(() {
      timeFormat = newTimeFormat;
    });
  }

  void update(value) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    dateFormatSetting = appSettings
        .getGroup("General")
        .getGroup("Display")
        .getSetting("Date Format");

    timeFormatSetting = appSettings
        .getGroup("General")
        .getGroup("Display")
        .getSetting("Time Format");

    dateFormatSetting.addListener(setDateFormat);
    timeFormatSetting.addListener(setTimeFormat);
    setDateFormat(dateFormatSetting.value);
    setTimeFormat(timeFormatSetting.value);
  }

  @override
  void dispose() {
    dateFormatSetting.removeListener(setDateFormat);
    timeFormatSetting.removeListener(setTimeFormat);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TimeIcon timeOfDayIcon = getTimeIcon(widget.alarm.time);

    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    TextTheme textTheme = theme.textTheme;

    Widget getActionButton() {
      if (widget.alarm.isFinished) {
        return IconButton(
          onPressed: widget.onPressDelete,
          icon: Icon(
            Icons.delete_rounded,
            color: colorScheme.error,
            size: 32,
          ),
        );
      }
      if (widget.alarm.canBeDisabled) {
        return Switch(
          value: widget.alarm.isEnabled,
          onChanged: widget.onEnabledChange,
        );
      }
      return TextButton(
        child: Text(AppLocalizations.of(context)!.dismissAlarmButton,
            maxLines: 1,
            style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
        onPressed: () async {
          if (widget.alarm.tasks.isEmpty) {
            widget.onDismiss();
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlarmNotificationScreen(
                scheduleId: widget.alarm.id,
                initialIndex: 0,
                onPop: widget.onDismiss,
              ),
            ),
          );
          if (result != null && result == true) {
            widget.onDismiss();
          }
        },
      );
    }

    final Color mutedColor = colorScheme.onSurface.withOpacity(0.5);
    final Color secondaryColor = widget.alarm.isEnabled
        ? colorScheme.onSurface.withOpacity(0.7)
        : mutedColor;
    final String scheduleText = getAlarmScheduleDescription(
        context, widget.alarm, dateFormat, timeFormat);

    // Layout: big time on the left (iOS), label and schedule underneath,
    // a clear on/off switch on the right (One UI), and the overflow menu.
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 4.0, top: 14, bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DigitalClockDisplay(
                    dateTime: widget.alarm.time.toDateTime(),
                    scale: 0.85,
                    color: widget.alarm.isEnabled ? null : mutedColor),
                if (widget.alarm.label.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Text(
                      widget.alarm.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: textTheme.titleSmall?.copyWith(
                          color: secondaryColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      timeOfDayIcon.icon,
                      color: widget.alarm.isEnabled
                          ? timeOfDayIcon.color
                          : mutedColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        scheduleText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: secondaryColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          getActionButton(),
          CardEditMenu(actions: [
            if (widget.alarm.canBeSkipped)
              MenuAction(
                widget.alarm.shouldSkipNextAlarm
                    ? AppLocalizations.of(context)!.cancelSkipAlarmButton
                    : AppLocalizations.of(context)!.skipAlarmButton,
                (context) {
                  widget.onSkipChange(!widget.alarm.shouldSkipNextAlarm);
                },
                Icons.skip_next_rounded,
              ),
            getDuplicatePopupAction(context, widget.onPressDuplicate),
            if (widget.alarm.isDeletable)
              getDeletePopupAction(context, widget.onPressDelete),
          ]),
        ],
      ),
    );
  }
}

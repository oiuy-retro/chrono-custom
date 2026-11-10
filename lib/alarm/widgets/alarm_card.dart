import 'package:clock_app/alarm/logic/schedule_description.dart';
import 'package:clock_app/alarm/screens/alarm_notification_screen.dart';
import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/clock/types/time.dart';
import 'package:clock_app/common/types/popup_action.dart';
import 'package:clock_app/common/utils/popup_action.dart';
import 'package:clock_app/common/widgets/card_edit_menu.dart';
import 'package:clock_app/common/widgets/clock/digital_clock_display.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:clock_app/alarm/logic/day_chips.dart';
import 'package:clock_app/alarm/types/schedules/daily_alarm_schedule.dart';
import 'package:clock_app/alarm/types/schedules/weekly_alarm_schedule.dart';
import 'package:clock_app/common/utils/haptics.dart';
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
          onChanged: (value) {
            Haptics.toggle();
            widget.onEnabledChange(value);
          },
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

    final Color mutedColor = colorScheme.onSurface.withOpacity(0.4);
    final bool enabled = widget.alarm.isEnabled;
    final Color secondaryColor =
        enabled ? colorScheme.onSurface.withOpacity(0.65) : mutedColor;
    final String scheduleText = getAlarmScheduleDescription(
        context, widget.alarm, dateFormat, timeFormat);

    // Samsung Clock layout: label and big time on the left, the repeat days
    // (S M T W T F S, active days highlighted) or the date in the middle,
    // and the on/off switch on the right.
    Widget scheduleWidget;
    if (widget.alarm.scheduleType == DailyAlarmSchedule ||
        widget.alarm.scheduleType == WeeklyAlarmSchedule) {
      final labels = dayChipLabels(context, widget.alarm);
      final states = dayChipStates(widget.alarm);
      scheduleWidget = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < labels.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Text(
                  labels[i],
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: states[i] ? FontWeight.w700 : FontWeight.w400,
                    color: states[i]
                        ? (enabled ? colorScheme.primary : mutedColor)
                        : colorScheme.onSurface
                            .withOpacity(enabled ? 0.35 : 0.2),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      scheduleWidget = Text(
        scheduleText,
        maxLines: 2,
        textAlign: TextAlign.end,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelMedium?.copyWith(color: secondaryColor),
      );
    }

    return Padding(
      padding:
          const EdgeInsets.only(left: 20.0, right: 4.0, top: 12, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.alarm.label.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      widget.alarm.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style:
                          textTheme.bodyMedium?.copyWith(color: secondaryColor),
                    ),
                  ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: DigitalClockDisplay(
                      dateTime: widget.alarm.time.toDateTime(),
                      scale: 0.8,
                      color: enabled ? null : mutedColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: scheduleWidget,
            ),
          ),
          const SizedBox(width: 4),
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

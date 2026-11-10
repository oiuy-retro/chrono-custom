import 'dart:async';

import 'package:clock_app/common/types/popup_action.dart';
import 'package:clock_app/common/utils/popup_action.dart';
import 'package:clock_app/common/widgets/card_edit_menu.dart';
import 'package:clock_app/timer/types/time_duration.dart';
import 'package:clock_app/timer/types/timer.dart';
import 'package:clock_app/timer/widgets/timer_progress_bar.dart';
import 'package:clock_app/common/utils/haptics.dart';
import 'package:flutter/material.dart';

class TimerCard extends StatefulWidget {
  const TimerCard({
    super.key,
    required this.timer,
    required this.onToggleState,
    required this.onPressDelete,
    required this.onPressDuplicate,
    required this.onPressReset,
    required this.onPressAddTime,
  });

  final ClockTimer timer;
  final VoidCallback onToggleState;
  final VoidCallback onPressDelete;
  final VoidCallback onPressDuplicate;
  final VoidCallback onPressReset;
  final VoidCallback onPressAddTime;

  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  late ValueNotifier<double> valueNotifier;
  late ClockTimer _previousTimer;

  late int remainingSeconds;

  Timer? periodicTimer;

  void updateTimer() {
    setState(() {
      periodicTimer?.cancel();
      if (widget.timer.isRunning) {
        periodicTimer =
            Timer.periodic(const Duration(seconds: 1), (Timer timer) {
          valueNotifier.value = widget.timer.remainingSeconds.toDouble();
        });
      }
      valueNotifier.value = widget.timer.remainingSeconds.toDouble();
    });
  }

  @override
  void initState() {
    super.initState();
    // if (GetStorage().read('first_timer_created') == false) {
    //   GetStorage().write('first_timer_created', true);
    //   showEditTip(context, () => mounted);
    // }
    valueNotifier = ValueNotifier(widget.timer.remainingSeconds.toDouble());
    remainingSeconds = widget.timer.remainingSeconds;
    valueNotifier.addListener(() {
      setState(() {
        remainingSeconds = valueNotifier.value.toInt();
      });
    });
    updateTimer();
    _previousTimer = ClockTimer.from(widget.timer);
  }

  @override
  void dispose() {
    periodicTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    TextTheme textTheme = theme.textTheme;

    if (!_previousTimer.equals(widget.timer)) {
      updateTimer();
      _previousTimer = ClockTimer.from(widget.timer);
    }

    // Samsung Clock style: circular progress ring with the remaining time
    // inside, label above, and round play/pause and reset buttons.
    final String timeText =
        TimeDuration.fromSeconds(remainingSeconds).toTimeString();
    Widget roundButton(IconData icon, VoidCallback onTap, {bool primary = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: primary
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.08),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Haptics.button();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon,
                  size: 26,
                  color: primary ? colorScheme.onPrimary : colorScheme.onSurface),
            ),
          ),
        ),
      );
    }

    return Padding(
        padding: const EdgeInsets.only(
            left: 16.0, right: 4.0, top: 16.0, bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TimerProgressBar(
                timer: widget.timer,
                size: 104,
                centerWidget: Padding(
                  padding: const EdgeInsets.all(14),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      timeText,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                )),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.timer.label,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      roundButton(
                          widget.timer.isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded, () {
                        widget.onToggleState();
                        updateTimer();
                      }, primary: true),
                      if (!widget.timer.isStopped)
                        roundButton(Icons.replay_rounded, widget.onPressReset),
                    ],
                  ),
                ],
              ),
            ),
            CardEditMenu(actions: [
              if (!widget.timer.isStopped)
                MenuAction(
                  "Reset",
                  (context) => widget.onPressReset(),
                  Icons.replay_rounded,
                ),
              if (!widget.timer.isStopped)
                MenuAction(
                  '+${widget.timer.addLength.floor()}:00',
                  (context) => widget.onPressAddTime(),
                  Icons.add_rounded,
                ),
              getDuplicatePopupAction(context, widget.onPressDuplicate),
              getDeletePopupAction(context, widget.onPressDelete),
            ]),
          ],
        ));
  }
}

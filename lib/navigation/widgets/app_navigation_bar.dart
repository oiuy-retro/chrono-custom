import 'package:clock_app/navigation/data/tabs.dart';
import 'package:clock_app/navigation/types/tab.dart';
import 'package:flutter/material.dart' hide Tab;

/// Bottom tab bar in the style of Samsung Clock on One UI: a rounded bar with
/// text tabs, the selected one in bold on a soft pill.
class AppNavigationBar extends StatelessWidget {
  final int selectedTabIndex;
  final void Function(int) onTabSelected;

  const AppNavigationBar(
      {super.key, required this.selectedTabIndex, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final List<Tab> tabs = getTabs(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Material(
          color: theme.cardColor,
          elevation: 0,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: i == selectedTabIndex,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => onTabSelected(i),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: i == selectedTabIndex
                                  ? colorScheme.primary.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                tabs[i].title,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: textTheme.titleSmall?.copyWith(
                                  fontSize: 15,
                                  fontWeight: i == selectedTabIndex
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: i == selectedTabIndex
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withOpacity(0.55),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

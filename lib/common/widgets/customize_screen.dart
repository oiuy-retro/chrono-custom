import 'package:clock_app/common/types/list_item.dart';
import 'package:clock_app/navigation/widgets/app_top_bar.dart';
import 'package:clock_app/common/utils/haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomizeState {
  bool isSaved = false;
  bool isChanged = false;
}

class CustomizeScreen<Item extends CustomizableListItem>
    extends StatefulWidget {
  const CustomizeScreen({
    super.key,
    required this.item,
    this.onSave,
    required this.builder,
    required this.isNewItem,
    this.buttonsAtBottom = false,
  });

  /// Samsung style: Cancel and Save in a bar at the bottom, no top bar.
  final bool buttonsAtBottom;

  final Item item;
  final void Function(Item item)? onSave;
  final Widget Function(BuildContext context, Item item) builder;
  final bool isNewItem;

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState<Item>();
}

class _CustomizeScreenState<Item extends CustomizableListItem>
    extends State<CustomizeScreen<Item>> {
  late final Item _item = widget.item.copy();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    void save() {
      Haptics.button();
      widget.onSave?.call(_item);
      _isSaved = true;
      Navigator.pop(context, _item);
    }

    final Widget? bottomBar = widget.buttonsAtBottom
        ? SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Haptics.button();
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(AppLocalizations.of(context)!.cancelButton,
                            style: TextStyle(
                                fontSize: 17,
                                color: colorScheme.onSurface.withOpacity(0.8))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: save,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(AppLocalizations.of(context)!.saveButton,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : null;

    return Scaffold(
      bottomNavigationBar: bottomBar,
      appBar: widget.buttonsAtBottom
          ? const AppTopBar()
          : AppTopBar(actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            AppLocalizations.of(context)!.cancelButton,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextButton(
            onPressed: save,
            child: Text(AppLocalizations.of(context)!.saveButton),
          ),
        )
      ]),
      body: WillPopScope(
        onWillPop: () async {
          if (_isSaved) return true;
          if (_item.hasSameSettingsAs(widget.item) && !widget.isNewItem) {
            return true;
          }
          bool? shouldPop = await showDialog<bool>(
            context: context,
            builder: (buildContext) {
              return AlertDialog(
                actionsPadding: const EdgeInsets.only(bottom: 6, right: 10),
                content: Text(AppLocalizations.of(context)!.saveReminderAlert),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: Text(AppLocalizations.of(context)!.noButton,
                        style: TextStyle(color: colorScheme.primary)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: Text(AppLocalizations.of(context)!.yesButton,
                        style: TextStyle(color: colorScheme.error)),
                  ),
                ],
              );
            },
          );
          return shouldPop ?? false;
        },
        child: widget.builder(context, _item),
      ),
    );
  }
}

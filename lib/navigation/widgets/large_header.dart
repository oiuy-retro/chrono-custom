import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// A large expanded app bar in the style of Samsung One UI.
///
/// When [collapse] is 0 the header fills about the top third of the screen,
/// with a big centred title and an optional centred subtitle. As the page underneath scrolls, [collapse] goes towards 1 and the
/// header shrinks to a normal toolbar with a small title.
class LargeHeader extends StatelessWidget {
  const LargeHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.collapse = 0,
    this.actions = const [],
    this.expandedHeight = 168,
    this.collapsedHeight = 56,
  });

  final String title;
  final String? subtitle;
  final double collapse;
  final List<Widget> actions;
  final double expandedHeight;
  final double collapsedHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final t = collapse.clamp(0.0, 1.0);
    final height = lerpDouble(expandedHeight, collapsedHeight, t)!;
    final bigOpacity = (1 - t * 1.6).clamp(0.0, 1.0);
    final smallOpacity = ((t - 0.6) / 0.4).clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Small toolbar title, fades in when collapsed.
          Positioned(
            left: 24,
            right: 24 + 48.0 * actions.length,
            top: 0,
            height: collapsedHeight,
            child: Opacity(
              opacity: smallOpacity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          // Actions, always visible in the toolbar row.
          Positioned(
            right: 8,
            top: 0,
            height: collapsedHeight,
            child: Row(children: actions),
          ),
          // Large centred title block, fades out as it collapses.
          if (bigOpacity > 0)
            Positioned(
              left: 24,
              right: 24,
              top: collapsedHeight * 0.5,
              bottom: 8,
              child: Opacity(
                opacity: bigOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        fontSize: 38,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

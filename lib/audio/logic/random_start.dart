import 'dart:math';

/// Sounds shorter than this always start at the beginning.
const Duration randomStartMinLength = Duration(seconds: 20);

/// Never start within this much of the end.
const Duration randomStartEndMargin = Duration(seconds: 15);

/// Never start in the last 20% of the sound.
const double randomStartMaxFraction = 0.8;

/// Picks where a "Start at random point" alarm begins playing.
///
/// Returns zero when the length is unknown or shorter than 20 seconds.
/// Otherwise picks a point before both the last 15 seconds and the last 20%,
/// so the sound does not end right away. Looping then continues from the
/// start.
Duration randomStartPosition(Duration? length, [Random? random]) {
  if (length == null || length < randomStartMinLength) return Duration.zero;
  final int ms = length.inMilliseconds;
  final int latest = min(ms - randomStartEndMargin.inMilliseconds,
      (ms * randomStartMaxFraction).floor());
  if (latest <= 0) return Duration.zero;
  return Duration(milliseconds: (random ?? Random()).nextInt(latest + 1));
}

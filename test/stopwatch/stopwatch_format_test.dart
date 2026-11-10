import 'package:clock_app/stopwatch/widgets/stopwatch_ticker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stopwatch readout uses the Samsung 00:00.00 format', () {
    expect(formatStopwatchTime(0), '00:00.00');
    expect(formatStopwatchTime(61234), '01:01.23');
    expect(formatStopwatchTime(3723450), '01:02:03.45');
    expect(formatStopwatchTime(61234, showMilliseconds: false), '01:01');
  });
}

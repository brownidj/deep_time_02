import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_vertical_overlays_helpers.dart';

void main() {
  test('connector lines anchor at marker tip x', () {
    final lines = buildConnectorLines(
      ys: const [10.0, 20.0],
      leftBoundaryX: 120.0,
      anchorX: 300.0,
    );

    expect(lines, hasLength(2));
    expect(lines[0].anchorX, 300.0);
    expect(lines[1].anchorX, 300.0);
  });

  test('connector lines always span from left boundary to anchor', () {
    final lines = buildConnectorLines(
      ys: const [42.0],
      leftBoundaryX: 90.0,
      anchorX: 200.0,
    );

    expect(lines.single.leftX, 90.0);
    expect(lines.single.anchorX, 200.0);
    expect(lines.single.leftX <= lines.single.anchorX, isTrue);
  });

  test('connector line builder handles inverted boundary safely', () {
    final lines = buildConnectorLines(
      ys: const [42.0],
      leftBoundaryX: 260.0,
      anchorX: 200.0,
    );

    expect(lines.single.leftX, 200.0);
    expect(lines.single.anchorX, 200.0);
  });
}

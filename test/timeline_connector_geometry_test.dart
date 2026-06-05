import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_connector_geometry.dart';

void main() {
  test('connector ends exactly at marker tip x', () {
    final span = leftwardConnectorSpan(boundaryX: -240.0, markerTipX: 0.0);
    expect(span.right, 0.0);
  });

  test('connector left edge is boundary when boundary is left of marker', () {
    final span = leftwardConnectorSpan(boundaryX: -180.0, markerTipX: 0.0);
    expect(span.left, -180.0);
    expect(span.right, 0.0);
  });

  test('connector never extends right of marker tip', () {
    final span = leftwardConnectorSpan(boundaryX: 40.0, markerTipX: 0.0);
    expect(span.left, 0.0);
    expect(span.right, 0.0);
  });
}

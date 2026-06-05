import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body_helpers.dart';

void main() {
  testWidgets('extinctions width fits marker + longest short label', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    const labels = ['K-Pg', 'End-Ord', 'End-Permian'];
    final painter = TextPainter(
      text: const TextSpan(text: 'End-Permian', style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final expected = 0 + 13 + 6 + painter.width + 6;

    final width = extinctionsTrackWidthForLabels(
      labels,
      style: style,
      markerLeft: 0,
      markerSize: 13,
      labelGap: 6,
      rightPadding: 6,
      fallbackLabel: 'Ext.',
    );
    expect(width, expected);
  });
}

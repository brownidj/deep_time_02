import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_vertical_columns_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connector anchors stay valid when continent column is hidden', () {
    final trackWidths = <TimelineTrack, double>{
      TimelineTrack.ma: 40,
      TimelineTrack.eon: 50,
      TimelineTrack.era: 60,
      TimelineTrack.period: 70,
      TimelineTrack.epoch: 80,
      TimelineTrack.stage: 90,
      TimelineTrack.paleoEcology: 95,
      TimelineTrack.rlife: 100,
      TimelineTrack.extinctions: 110,
      TimelineTrack.events: 120,
      TimelineTrack.clades: 130,
    };
    final order = [
      TimelineTrack.ma,
      TimelineTrack.eon,
      TimelineTrack.era,
      TimelineTrack.period,
      TimelineTrack.epoch,
      TimelineTrack.stage,
      TimelineTrack.paleoEcology,
      TimelineTrack.rlife,
      TimelineTrack.extinctions,
      TimelineTrack.events,
      TimelineTrack.clades,
    ];
    final layout = buildVerticalColumnsLayout(
      trackOrder: order,
      scaledWidth: (track) => trackWidths[track]!,
      trackWidth: (track) => trackWidths[track]!,
      useFixedHeights: false,
    );

    expect(layout.eventLineLeft.isFinite, isTrue);
    expect(layout.extinctionLineLeft.isFinite, isTrue);
    expect(layout.extinctionLineLeft, 0);
  });
}

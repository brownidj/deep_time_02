import 'package:deep_time_2/domain/models/clade_display_group.dart';
import 'package:deep_time_2/ui/models/clade_label_mode.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('representative life column can be hidden from settings', (
    tester,
  ) async {
    final changes = <({TimelineTrack track, bool visible})>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimelineSettingsDialog(
            labelMode: TimeLabelMode.geologicTime,
            onScaleChanged: (_) {},
            cladeViewMode: CladeViewMode.representativeOnly,
            cladeLabelMode: CladeLabelMode.common,
            cladeCategoryId: 'all',
            cladeDisplayGroups: const <CladeDisplayGroup>[],
            onCladeViewModeChanged: (_) {},
            onCladeCategoryChanged: (_) {},
            onCladeLabelModeChanged: (_) {},
            visibleTracks: {...kDefaultTimelineTrackOrder},
            onTrackVisibilityChanged: (track, visible) {
              changes.add((track: track, visible: visible));
            },
          ),
        ),
      ),
    );

    final rlifeSwitch = find.widgetWithText(
      SwitchListTile,
      'Representative life',
    );
    await tester.ensureVisible(rlifeSwitch);
    await tester.tap(rlifeSwitch);
    await tester.pump();

    expect(changes, contains((track: TimelineTrack.rlife, visible: false)));
  });
}

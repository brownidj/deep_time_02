import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/clade_zoom_level.dart';

import 'timeline_row_alignment_helpers.dart';
import 'timeline_focused_clade_renderer_test_helpers.dart';

void main() {
  testWidgets('Focused renderer uses direct child horizontal segments only', (
    tester,
  ) async {
    await setLargeSurface(tester);
    final layout = focusedPinnedStripLayout();
    const clades = [
      Clade(
        id: 'root',
        label: 'Root',
        scientificRank: 'clade',
        startMa: 60,
        endMa: 20,
        displayGroups: ['all'],
        displayPriority: 0,
        minZoomLevel: CladeZoomLevel.whole,
        zoomable: true,
      ),
      Clade(
        id: 'child_a',
        label: 'Child A',
        scientificRank: 'clade',
        parentId: 'root',
        startMa: 58,
        endMa: 44,
        displayGroups: ['all'],
        displayPriority: 1,
        minZoomLevel: CladeZoomLevel.whole,
      ),
      Clade(
        id: 'child_b',
        label: 'Child B',
        scientificRank: 'clade',
        parentId: 'root',
        startMa: 50,
        endMa: 20,
        displayGroups: ['all'],
        displayPriority: 2,
        minZoomLevel: CladeZoomLevel.whole,
      ),
    ];
    final childrenByParentId = <String, List<Clade>>{
      'root': [clades[1], clades[2]],
    };

    await pumpFocusedCladeTestBody(
      tester,
      layout: layout,
      clades: clades,
      childrenByParentId: childrenByParentId,
      activeCladeRootId: 'root',
      activeCladeRootLabel: 'Root',
    );

    expect(find.byKey(const ValueKey('focused-clade-label-root')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('focused-clade-label-child_a')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('focused-clade-label-child_b')),
      findsOneWidget,
    );

    final rootDx = tester
        .getTopLeft(find.byKey(const ValueKey('focused-clade-label-root')))
        .dx;
    final childADx = tester
        .getTopLeft(find.byKey(const ValueKey('focused-clade-label-child_a')))
        .dx;
    final childBDx = tester
        .getTopLeft(find.byKey(const ValueKey('focused-clade-label-child_b')))
        .dx;

    expect(childADx, greaterThan(rootDx));
    expect(childBDx, greaterThan(rootDx));
  });
}

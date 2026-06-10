import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/clade_zoom_level.dart';

import 'timeline_row_alignment_helpers.dart';
import 'timeline_focused_clade_renderer_test_helpers.dart';

void main() {
  testWidgets('Focused renderer gives same-depth clades distinct lanes', (
    tester,
  ) async {
    await setLargeSurface(tester);
    final layout = splitPeriodLayout();
    const clades = [
      Clade(
        id: 'dinosauria',
        label: 'Dinosauria',
        scientificRank: 'clade',
        startMa: 95,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 0,
        minZoomLevel: CladeZoomLevel.whole,
        zoomable: true,
      ),
      Clade(
        id: 'ornithischia',
        label: 'Ornithischia',
        scientificRank: 'clade',
        parentId: 'dinosauria',
        startMa: 85,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 1,
        minZoomLevel: CladeZoomLevel.whole,
        zoomable: true,
      ),
      Clade(
        id: 'saurischia',
        label: 'Saurischia',
        scientificRank: 'clade',
        parentId: 'dinosauria',
        startMa: 82,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 2,
        minZoomLevel: CladeZoomLevel.whole,
        zoomable: true,
      ),
      Clade(
        id: 'theropoda',
        label: 'Theropoda',
        scientificRank: 'clade',
        parentId: 'saurischia',
        startMa: 70,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 3,
        minZoomLevel: CladeZoomLevel.whole,
      ),
      Clade(
        id: 'ornithopoda',
        label: 'Ornithopoda',
        scientificRank: 'clade',
        parentId: 'ornithischia',
        startMa: 68,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 4,
        minZoomLevel: CladeZoomLevel.whole,
      ),
    ];
    final childrenByParentId = <String, List<Clade>>{
      'dinosauria': [clades[1], clades[2]],
      'ornithischia': [clades[4]],
      'saurischia': [clades[3]],
    };

    await pumpFocusedCladeTestBody(
      tester,
      layout: layout,
      clades: clades,
      childrenByParentId: childrenByParentId,
      activeCladeRootId: 'dinosauria',
      activeCladeRootLabel: 'Dinosauria',
    );

    final ornithischiaFinder = find.byKey(
      const ValueKey('focused-clade-label-ornithischia'),
    );
    final saurischiaFinder = find.byKey(
      const ValueKey('focused-clade-label-saurischia'),
    );
    expect(ornithischiaFinder, findsOneWidget);
    expect(saurischiaFinder, findsOneWidget);

    final ornithischiaDx = tester.getTopLeft(ornithischiaFinder).dx;
    final saurischiaDx = tester.getTopLeft(saurischiaFinder).dx;
    expect((ornithischiaDx - saurischiaDx).abs(), greaterThan(20.0));
  });

  testWidgets(
    'Focused renderer suppresses inline label when pinned strip label is visible',
    (tester) async {
      await setLargeSurface(tester);
      final layout = focusedPinnedStripLayout();
      const clades = [
        Clade(
          id: 'root_clade',
          label: 'Root Clade',
          scientificRank: 'clade',
          startMa: 100,
          endMa: 0,
          displayGroups: ['all'],
          displayPriority: 0,
          minZoomLevel: CladeZoomLevel.whole,
          zoomable: true,
        ),
        Clade(
          id: 'child_clade',
          label: 'Child Clade',
          scientificRank: 'clade',
          parentId: 'root_clade',
          startMa: 80,
          endMa: 0,
          displayGroups: ['all'],
          displayPriority: 1,
          minZoomLevel: CladeZoomLevel.whole,
        ),
      ];
      final childrenByParentId = <String, List<Clade>>{
        'root_clade': [clades[1]],
      };

      await pumpFocusedCladeTestBody(
        tester,
        layout: layout,
        clades: clades,
        childrenByParentId: childrenByParentId,
        activeCladeRootId: 'root_clade',
        activeCladeRootLabel: 'Root Clade',
      );

      expect(
        find.byKey(const ValueKey('focused-clade-label-root_clade')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('clade-top-strip')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('clade-top-strip-label-root_clade')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Focused renderer inserts younger direct child nearer parent', (
    tester,
  ) async {
    await setLargeSurface(tester);
    final layout = focusedPinnedStripLayout();
    const clades = [
      Clade(
        id: 'eurypoda',
        label: 'Eurypoda',
        scientificRank: 'clade',
        startMa: 60,
        endMa: 20,
        displayGroups: ['all'],
        displayPriority: 0,
        minZoomLevel: CladeZoomLevel.whole,
        zoomable: true,
      ),
      Clade(
        id: 'stegosauria',
        label: 'Stegosauria',
        scientificRank: 'clade',
        parentId: 'eurypoda',
        startMa: 58,
        endMa: 44,
        displayGroups: ['all'],
        displayPriority: 1,
        minZoomLevel: CladeZoomLevel.whole,
      ),
      Clade(
        id: 'ankylosauria',
        label: 'Ankylosauria',
        scientificRank: 'clade',
        parentId: 'eurypoda',
        startMa: 60,
        endMa: 20,
        displayGroups: ['all'],
        displayPriority: 2,
        minZoomLevel: CladeZoomLevel.whole,
      ),
    ];
    final childrenByParentId = <String, List<Clade>>{
      'eurypoda': [clades[1], clades[2]],
    };

    await pumpFocusedCladeTestBody(
      tester,
      layout: layout,
      clades: clades,
      childrenByParentId: childrenByParentId,
      activeCladeRootId: 'eurypoda',
      activeCladeRootLabel: 'Eurypoda',
    );

    final parentDx = tester
        .getTopLeft(find.byKey(const ValueKey('focused-clade-label-eurypoda')))
        .dx;
    final stegoDx = tester
        .getTopLeft(
          find.byKey(const ValueKey('focused-clade-label-stegosauria')),
        )
        .dx;
    final ankyloDx = tester
        .getTopLeft(
          find.byKey(const ValueKey('focused-clade-label-ankylosauria')),
        )
        .dx;

    expect(stegoDx, greaterThan(parentDx));
    expect(ankyloDx, greaterThan(stegoDx));
  });
}

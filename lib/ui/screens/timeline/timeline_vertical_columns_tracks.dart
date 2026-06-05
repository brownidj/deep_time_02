part of 'timeline_vertical_columns.dart';
const double _standardVerticalEventBarWidth = 24.0;
Widget _buildVerticalTrack({
  required TimelineTrack track,
  required double Function(TimelineTrack) scaledWidth,
  required double columnHeight,
  required TimelineLayoutSnapshot layout,
  required TimelineBodyMetrics metrics,
  required int? selectedId,
  required ValueChanged<TimelineBandSegment> onBandSelect,
  required ValueChanged<TimelineRowSegment> onSelect,
  required DeepTimePalette palette,
  required bool useFixedHeights,
  required MinHeightMaps minHeights,
  required TimelineMarkerCatalog markers,
  required ScrollController scrollController,
  required List<Clade> clades,
  required CladeViewMode cladeViewMode,
  required String cladeCategoryId,
  required CladeLabelMode cladeLabelMode,
  required List<String> cladeRepresentativeIds,
  required String cladeSearchQuery, required String? cladeSpotlightId, required String? activeCladeRootId,
  required Map<String, List<Clade>> childrenByParentId,
  required ValueChanged<Clade> onCladeSpotlight,
  required ValueChanged<String?> onCladeRootChanged,
  required List<PaleoEcologyEntry> paleoEcology,
  required List<double> stageHeightsForPaleo, required List<double> eonHeightsForClades,
  required List<double> eraHeightsForClades, required List<double> periodHeightsForClades,
  required List<double> epochHeightsForClades,
}) {
  switch (track) {
    case TimelineTrack.ma:
      return _MaColumn(
        width: scaledWidth(TimelineTrack.ma),
        height: columnHeight,
        layout: layout,
        metrics: metrics,
      );
    case TimelineTrack.eon:
      return _VerticalBandColumn(
        width: scaledWidth(TimelineTrack.eon),
        height: columnHeight,
        segments: layout.eonSegments,
        unitsTotal: metrics.eonTotalUnits,
        selectedId: selectedId,
        onTapSegment: onBandSelect,
        colorForSegment: (segment) => palette.colorForKey(segment.colorKey),
        rotateLabel: true,
        horizontalPadding: 2,
        minHeightForSegment: useFixedHeights
            ? null
            : (segment, _) => minHeights.eonHeights[segment.id] ?? 0.0,
      );
    case TimelineTrack.era:
      return _VerticalBandColumn(
        width: scaledWidth(TimelineTrack.era),
        height: columnHeight,
        segments: layout.eraSegments,
        unitsTotal: metrics.eraTotalUnits,
        selectedId: selectedId,
        onTapSegment: onBandSelect,
        colorForSegment: (segment) => palette.colorForKey(segment.colorKey),
        rotateLabel: true,
        horizontalPadding: 2,
        minHeightForSegment: useFixedHeights
            ? null
            : (segment, _) => segment.isGap
                  ? minHeightFromParentRange(
                      segment.startMa,
                      segment.endMa,
                      layout.eonSegments,
                      minHeights.eonHeights,
                      (parent) => parent.startMa,
                      (parent) => parent.endMa,
                      (parent) => parent.id,
                    )
                  : (minHeights.eraHeights[segment.id] ?? 0.0),
      );
    case TimelineTrack.period:
      return _VerticalRowColumn(
        width: scaledWidth(TimelineTrack.period),
        height: columnHeight,
        segments: layout.periodSegments,
        unitsTotal: metrics.periodUnits,
        selectedId: selectedId,
        onTapSegment: onSelect,
        colorForSegment: (segment) => palette.colorForKey(segment.colorKey),
        rotateLabel: true,
        horizontalPadding: 6,
        minHeightForSegment: useFixedHeights
            ? null
            : (segment, _) => segment.isGap
                  ? minHeightFromParentRange(
                      segment.startMa,
                      segment.endMa,
                      layout.eraSegments,
                      minHeights.eraHeights,
                      (parent) => parent.startMa,
                      (parent) => parent.endMa,
                      (parent) => parent.id,
                    )
                  : (minHeights.periodHeights[segment.id] ?? 0.0),
      );
    case TimelineTrack.epoch:
      return _VerticalRowColumn(
        width: scaledWidth(TimelineTrack.epoch),
        height: columnHeight,
        segments: layout.epochSegments,
        unitsTotal: metrics.epochTotalUnits,
        selectedId: selectedId,
        onTapSegment: onSelect,
        colorForSegment: (segment) => palette.colorForKey(segment.colorKey),
        rotateLabel: false,
        horizontalPadding: 6,
        minHeightForSegment: useFixedHeights
            ? null
            : (segment, _) => segment.isGap
                  ? minHeightFromParentRange(
                      segment.startMa,
                      segment.endMa,
                      layout.periodSegments,
                      minHeights.periodHeights,
                      (parent) => parent.startMa,
                      (parent) => parent.endMa,
                      (parent) => parent.id,
                    )
                  : (minHeights.epochHeights[segment.id] ?? 0.0),
      );
    case TimelineTrack.stage:
      return _VerticalRowColumn(
        width: scaledWidth(TimelineTrack.stage),
        height: columnHeight,
        segments: layout.stageSegments,
        unitsTotal: metrics.stageTotalUnits,
        selectedId: selectedId,
        onTapSegment: onSelect,
        colorForSegment: (segment) => palette.colorForKey(segment.colorKey),
        rotateLabel: false,
        horizontalPadding: 6,
        minHeightForSegment: useFixedHeights
            ? null
            : (segment, style) => segment.isGap
                  ? minHeightFromParentRange(
                      segment.startMa,
                      segment.endMa,
                      layout.epochSegments,
                      minHeights.epochHeights,
                      (parent) => parent.startMa,
                      (parent) => parent.endMa,
                      (parent) => parent.id,
                    )
                  : (minHeights.stageHeights[segment.id] ??
                        minHeightForStageLabel(segment, style)),
      );
    case TimelineTrack.continents:
      return _VerticalEventsColumn(
        width: scaledWidth(TimelineTrack.continents),
        height: columnHeight,
        events: layout.continentSegments,
        totalUnits: metrics.periodUnits,
        palette: palette,
        barGradientForEvent: (event) => _buildContinentBlockGradient(
          event: event,
          fallbackColor: _safeColorForKey(event.colorKey, palette),
          leftColumns: [
            _LeftColorColumn(
              ranges: _rangesFromRowSegments(layout.stageSegments),
              colorForKey: palette.colorForKey,
            ),
            _LeftColorColumn(
              ranges: _rangesFromRowSegments(layout.epochSegments),
              colorForKey: palette.colorForKey,
            ),
            _LeftColorColumn(
              ranges: _rangesFromRowSegments(layout.periodSegments),
              colorForKey: palette.colorForKey,
            ),
            _LeftColorColumn(
              ranges: _rangesFromBandSegments(layout.eraSegments),
              colorForKey: palette.colorForKey,
            ),
            _LeftColorColumn(
              ranges: _rangesFromBandSegments(layout.eonSegments),
              colorForKey: palette.colorForKey,
            ),
          ],
        ),
        horizontalPadding: 0,
        laneGap: 6,
        showPoints: false,
        fillLaneWidths: false,
        fixedLaneWidth: _standardVerticalEventBarWidth,
      );
    case TimelineTrack.waterways:
      return _VerticalEventsColumn(
        width: scaledWidth(TimelineTrack.waterways),
        height: columnHeight,
        events: layout.waterwaySegments,
        totalUnits: metrics.periodUnits,
        palette: palette,
        barGradientForEvent: (event) => _buildContinentBlockGradient(
          event: event,
          fallbackColor: _safeColorForKey(event.colorKey, palette),
          leftColumns: [
            _LeftColorColumn(
              ranges: _rangesFromRowSegments(layout.stageSegments),
              colorForKey: palette.colorForKey,
            ),
            _LeftColorColumn(
              ranges: _rangesFromRowSegments(layout.epochSegments),
              colorForKey: palette.colorForKey,
            ),
            _LeftColorColumn(
              ranges: _rangesFromRowSegments(layout.periodSegments),
              colorForKey: palette.colorForKey,
            ),
            _LeftColorColumn(
              ranges: _rangesFromBandSegments(layout.eraSegments),
              colorForKey: palette.colorForKey,
            ),
            _LeftColorColumn(
              ranges: _rangesFromBandSegments(layout.eonSegments),
              colorForKey: palette.colorForKey,
            ),
          ],
        ),
        horizontalPadding: 0,
        laneGap: 6,
        showPoints: false,
        fillLaneWidths: false,
        fixedLaneWidth: _standardVerticalEventBarWidth,
      );
    case TimelineTrack.paleoEcology:
      return _VerticalPaleoEcologyColumn(
        width: scaledWidth(TimelineTrack.paleoEcology),
        height: columnHeight,
        layout: layout,
        entries: paleoEcology,
        palette: palette,
        stageHeights: stageHeightsForPaleo,
      );
    case TimelineTrack.rlife:
      return _VerticalRowColumn(
        width: scaledWidth(TimelineTrack.rlife),
        height: columnHeight,
        segments: layout.rlifeSegments,
        unitsTotal: metrics.rlifeTotalUnits,
        selectedId: selectedId,
        onTapSegment: onSelect,
        colorForSegment: (segment) => palette.colorForKey(segment.colorKey),
        rotateLabel: false,
        horizontalPadding: 6,
        minHeightForSegment: null,
      );
    case TimelineTrack.extinctions:
      return _VerticalExtinctionColumn(
        width: scaledWidth(TimelineTrack.extinctions),
        height: columnHeight,
        periodSegments: layout.periodSegments,
        stageSegments: layout.stageSegments,
        extinctions: markers.extinctions,
      );
    case TimelineTrack.events:
      return _VerticalEventsColumn(
        width: scaledWidth(TimelineTrack.events),
        height: columnHeight,
        events: layout.eventSegments,
        totalUnits: metrics.periodUnits,
        palette: palette,
        fixedLaneWidth: _standardVerticalEventBarWidth,
      );
    case TimelineTrack.clades:
      return _VerticalCladeColumn(
        width: scaledWidth(TimelineTrack.clades),
        height: columnHeight,
        layout: layout,
        totalUnits: metrics.periodUnits,
        scrollController: scrollController,
        clades: clades,
        stageSegments: layout.stageSegments,
        stageHeights: stageHeightsForPaleo,
        epochSegments: layout.epochSegments,
        epochHeights: epochHeightsForClades,
        periodSegments: layout.periodSegments,
        periodHeights: periodHeightsForClades,
        eraSegments: layout.eraSegments,
        eraHeights: eraHeightsForClades,
        eonSegments: layout.eonSegments,
        eonHeights: eonHeightsForClades,
        viewMode: cladeViewMode,
        displayGroupId: cladeCategoryId,
        labelMode: cladeLabelMode,
        representativeIds: cladeRepresentativeIds,
        searchQuery: cladeSearchQuery,
        spotlightId: cladeSpotlightId,
        activeCladeRootId: activeCladeRootId,
        childrenByParentId: childrenByParentId,
        onSpotlight: onCladeSpotlight,
        onCladeRootChanged: onCladeRootChanged,
      );
  }
}

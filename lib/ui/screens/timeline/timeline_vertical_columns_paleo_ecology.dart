part of 'timeline_vertical_columns.dart';

class _VerticalPaleoEcologyColumn extends StatelessWidget {
  const _VerticalPaleoEcologyColumn({
    required this.width,
    required this.height,
    required this.layout,
    required this.entries,
    required this.palette,
    required this.stageHeights,
  });

  final double width;
  final double height;
  final TimelineLayoutSnapshot layout;
  final List<PaleoEcologyEntry> entries;
  final DeepTimePalette palette;
  final List<double> stageHeights;

  @override
  Widget build(BuildContext context) {
    if (width <= 0 || height <= 0) {
      return const SizedBox.shrink();
    }
    final blocks = _buildBlocks(
      layout,
      stageHeights: stageHeights,
      columnHeight: height,
    );
    final entriesByKey = {for (final entry in entries) entry.lookupKey: entry};

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: [
          for (final block in blocks)
            _buildBlock(
              context,
              block: block,
              width: width,
              entry: entriesByKey[block.sourceKey],
              palette: palette,
            ),
        ],
      ),
    );
  }

  Widget _buildBlock(
    BuildContext context, {
    required _PaleoBlock block,
    required double width,
    required PaleoEcologyEntry? entry,
    required DeepTimePalette palette,
  }) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: DeepTimePalette.darkLabel,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    final isVisibleBlock = block.sourceKey != null;
    final summary = entry == null ? null : paleoEcologySummaryText(entry);
    final tooltipMessage = entry == null
        ? null
        : _paleoEcologyTooltipMessage(entry, block);
    if (entry != null &&
        const {
          'Greenlandian',
          'Northgrippian',
          'Meghalayan',
        }.contains(entry.name)) {
      AppDebug.log(
        'Paleo ecology block ${entry.name}: '
        'height=${block.height.toStringAsFixed(2)} '
        'range=${block.startMa}->${block.endMa} summary=$summary',
      );
    }
    final backgroundColor = !isVisibleBlock
        ? Colors.transparent
        : block.colorKey == null
        ? DeepTimePalette.timelineGapBackground
        : _safeColorForKey(block.colorKey!, palette);
    final blockBody = SizedBox(
      key: block.sourceKey == null
          ? null
          : ValueKey('paleo-ecology-block-${block.sourceKey}'),
      width: width,
      height: block.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: isVisibleBlock
              ? Border(
                  right: BorderSide(color: DeepTimePalette.periodDivider),
                  bottom: BorderSide(color: DeepTimePalette.periodDivider),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: summary == null
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    summary,
                    style: textStyle,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
        ),
      ),
    );
    if (tooltipMessage == null || tooltipMessage.trim().isEmpty) {
      return blockBody;
    }
    return Tooltip(message: tooltipMessage, child: blockBody);
  }
}

class _PaleoBlock {
  const _PaleoBlock({
    required this.startMa,
    required this.endMa,
    required this.height,
    required this.sourceKey,
    required this.colorKey,
  });

  final double startMa;
  final double endMa;
  final double height;
  final String? sourceKey;
  final String? colorKey;
}

class _RangeRef {
  const _RangeRef({
    required this.startMa,
    required this.endMa,
    required this.isGap,
    this.sourceKey,
    this.colorKey,
  });

  final double startMa;
  final double endMa;
  final bool isGap;
  final String? sourceKey;
  final String? colorKey;

  bool contains(double ma) => ma <= startMa && ma >= endMa;
}

List<_PaleoBlock> _buildBlocks(
  TimelineLayoutSnapshot layout, {
  required List<double> stageHeights,
  required double columnHeight,
}) {
  final divisionById = {
    for (final division in layout.divisions) division.id: division,
  };
  String? sourceKeyForRow(TimelineRowSegment segment) {
    if (segment.isGap) {
      return null;
    }
    final path = _pathForDivision(segment.id, divisionById) ?? [segment.label];
    return PaleoEcologyEntry.lookupKeyFor(rank: segment.rank, path: path);
  }

  String? sourceKeyForBand(TimelineBandSegment segment) {
    if (segment.isGap) {
      return null;
    }
    final path = _pathForDivision(segment.id, divisionById) ?? [segment.label];
    return PaleoEcologyEntry.lookupKeyFor(rank: segment.rank, path: path);
  }

  final stageRanges = [
    for (final segment in layout.stageSegments)
      _RangeRef(
        startMa: segment.startMa,
        endMa: segment.endMa,
        isGap: segment.isGap,
        sourceKey: sourceKeyForRow(segment),
        colorKey: segment.isGap ? null : segment.colorKey,
      ),
  ];
  final geologicColumns = <List<_RangeRef>>[
    stageRanges,
    [
      for (final segment in layout.epochSegments)
        _RangeRef(
          startMa: segment.startMa,
          endMa: segment.endMa,
          isGap: segment.isGap,
          sourceKey: sourceKeyForRow(segment),
          colorKey: segment.isGap ? null : segment.colorKey,
        ),
    ],
    [
      for (final segment in layout.periodSegments)
        _RangeRef(
          startMa: segment.startMa,
          endMa: segment.endMa,
          isGap: segment.isGap,
          sourceKey: sourceKeyForRow(segment),
          colorKey: segment.isGap ? null : segment.colorKey,
        ),
    ],
    [
      for (final segment in layout.eraSegments)
        _RangeRef(
          startMa: segment.startMa,
          endMa: segment.endMa,
          isGap: segment.isGap,
          sourceKey: sourceKeyForBand(segment),
          colorKey: segment.isGap ? null : segment.colorKey,
        ),
    ],
    [
      for (final segment in layout.eonSegments)
        _RangeRef(
          startMa: segment.startMa,
          endMa: segment.endMa,
          isGap: segment.isGap,
          sourceKey: sourceKeyForBand(segment),
          colorKey: segment.isGap ? null : segment.colorKey,
        ),
    ],
  ];

  _RangeRef? firstNonGapAt(double ma) {
    for (final column in geologicColumns) {
      for (final range in column) {
        if (range.contains(ma) && !range.isGap) {
          return range;
        }
      }
    }
    return null;
  }

  if (layout.stageSegments.isEmpty ||
      stageHeights.length != layout.stageSegments.length) {
    return const [];
  }
  final blocks = <_PaleoBlock>[];
  var consumed = 0.0;
  for (var i = 0; i < layout.stageSegments.length; i += 1) {
    final stage = layout.stageSegments[i];
    final rawHeight = stageHeights[i].clamp(0.0, columnHeight);
    final blockHeight = i == layout.stageSegments.length - 1
        ? (columnHeight - consumed).clamp(0.0, columnHeight)
        : rawHeight;
    consumed += blockHeight;
    if (blockHeight <= 0) {
      continue;
    }
    final span = stage.startMa - stage.endMa;
    if (span <= 0) {
      continue;
    }
    final mid = stage.startMa - (span / 2.0);
    final source = firstNonGapAt(mid);
    if (stage.isGap) {
      blocks.add(
        _PaleoBlock(
          startMa: stage.startMa,
          endMa: stage.endMa,
          height: blockHeight,
          sourceKey: source?.sourceKey,
          colorKey: source?.colorKey,
        ),
      );
      continue;
    }
    blocks.add(
      _PaleoBlock(
        startMa: stage.startMa,
        endMa: stage.endMa,
        height: blockHeight,
        sourceKey: source?.sourceKey,
        colorKey: source?.colorKey ?? stage.colorKey,
      ),
    );
  }
  return blocks;
}

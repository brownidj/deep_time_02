part of 'timeline_vertical_columns.dart';

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

  final geologicColumns = <List<_RangeRef>>[
    [
      for (final segment in layout.stageSegments)
        _RangeRef(
          startMa: segment.startMa,
          endMa: segment.endMa,
          isGap: segment.isGap,
          sourceKey: sourceKeyForRow(segment),
          colorKey: segment.isGap ? null : segment.colorKey,
        ),
    ],
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
    final source = firstNonGapAt(stage.startMa - (span / 2.0));
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

List<String>? _pathForDivision(
  int id,
  Map<int, GeologicDivision> divisionById,
) {
  final path = <String>[];
  var current = divisionById[id];
  while (current != null) {
    path.add(current.name);
    final parentId = current.parentId;
    current = parentId == null ? null : divisionById[parentId];
  }
  return path.isEmpty ? null : path.reversed.toList(growable: false);
}

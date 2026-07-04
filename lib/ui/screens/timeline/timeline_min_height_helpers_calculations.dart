import 'package:flutter/widgets.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_min_height_helpers_paleo.dart';

double minHeightForStageLabel(
  TimelineRowSegment segment,
  TextStyle? style, {
  double verticalPadding = 4,
}) {
  if (segment.isGap || segment.label.trim().isEmpty) {
    return 0.0;
  }
  final painter = TextPainter(
    text: TextSpan(text: segment.label, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.height + (verticalPadding * 2);
}

double minHeightForVerticalLabel(
  TimelineRowSegment segment,
  TextStyle? style, {
  double verticalPadding = 4,
}) {
  if (segment.isGap || segment.label.trim().isEmpty) {
    return 0.0;
  }
  final painter = TextPainter(
    text: TextSpan(text: segment.label, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width + (verticalPadding * 2);
}

double minHeightForVerticalBandLabel(
  TimelineBandSegment segment,
  TextStyle? style, {
  double verticalPadding = 4,
}) {
  if (segment.isGap || segment.label.trim().isEmpty) {
    return 0.0;
  }
  final painter = TextPainter(
    text: TextSpan(text: segment.label, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width + (verticalPadding * 2);
}

double minHeightFromParentRange<T>(
  double startMa,
  double endMa,
  List<T> parents,
  Map<int, double> parentHeights,
  double Function(T parent) parentStart,
  double Function(T parent) parentEnd,
  int Function(T parent) parentId,
) {
  for (final parent in parents) {
    if (startMa <= parentStart(parent) && endMa >= parentEnd(parent)) {
      return parentHeights[parentId(parent)] ?? 0.0;
    }
  }
  return 0.0;
}

Map<int, double> buildStageMinHeights(
  List<TimelineRowSegment> stages,
  TextStyle? style, {
  double verticalPadding = 4,
  List<GeologicDivision> divisions = const [],
  List<PaleoEcologyEntry> paleoEcology = const [],
  double paleoWidth = 0,
  TextStyle? paleoStyle,
}) {
  final divisionById = {
    for (final division in divisions) division.id: division,
  };
  final entriesByKey = {
    for (final entry in paleoEcology) entry.lookupKey: entry,
  };
  return {
    for (final segment in stages)
      segment.id: _stageMinHeight(
        segment,
        style,
        verticalPadding: verticalPadding,
        divisionById: divisionById,
        entriesByKey: entriesByKey,
        paleoWidth: paleoWidth,
        paleoStyle: paleoStyle ?? style,
      ),
  };
}

double _stageMinHeight(
  TimelineRowSegment segment,
  TextStyle? style, {
  required double verticalPadding,
  required Map<int, GeologicDivision> divisionById,
  required Map<String, PaleoEcologyEntry> entriesByKey,
  required double paleoWidth,
  required TextStyle? paleoStyle,
}) {
  final labelHeight = minHeightForStageLabel(
    segment,
    style,
    verticalPadding: verticalPadding,
  );
  if (segment.isGap || paleoWidth <= 0) {
    return labelHeight;
  }
  final path = _pathForDivision(segment.id, divisionById) ?? [segment.label];
  final key = PaleoEcologyEntry.lookupKeyFor(rank: segment.rank, path: path);
  final entry = entriesByKey[key];
  final displayEntry = entry == null
      ? null
      : resolvePaleoEcologyDisplayEntry(entry, entriesByKey);
  final summary = displayEntry == null
      ? null
      : paleoEcologySummaryText(displayEntry);
  if (summary == null) {
    return labelHeight;
  }
  final painter = TextPainter(
    text: TextSpan(text: summary, style: paleoStyle),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: (paleoWidth - 22).clamp(1.0, double.infinity));
  return labelHeight > painter.height + (verticalPadding * 2)
      ? labelHeight
      : painter.height + (verticalPadding * 2);
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

Map<int, double> buildEpochHeights(
  List<TimelineRowSegment> epochs,
  List<TimelineRowSegment> stages,
  Map<int, double> stageHeights,
  TextStyle? epochStyle, {
  double verticalPadding = 4,
}) {
  final result = <int, double>{};
  for (final epoch in epochs) {
    var sum = 0.0;
    var hasStages = false;
    for (final stage in stages) {
      if (stage.isGap) {
        continue;
      }
      if (stage.startMa <= epoch.startMa && stage.endMa >= epoch.endMa) {
        hasStages = true;
        sum += stageHeights[stage.id] ?? 0.0;
      }
    }
    if (!hasStages) {
      sum = minHeightForStageLabel(
        epoch,
        epochStyle,
        verticalPadding: verticalPadding,
      );
    }
    result[epoch.id] = sum;
  }
  return result;
}

Map<int, double> buildPeriodHeights(
  List<TimelineRowSegment> periods,
  List<TimelineRowSegment> epochs,
  Map<int, double> epochHeights,
  TextStyle? periodStyle, {
  double verticalPadding = 4,
}) {
  final result = <int, double>{};
  for (final period in periods) {
    var sum = 0.0;
    var hasEpochs = false;
    for (final epoch in epochs) {
      if (epoch.isGap) {
        continue;
      }
      if (epoch.startMa <= period.startMa && epoch.endMa >= period.endMa) {
        hasEpochs = true;
        sum += epochHeights[epoch.id] ?? 0.0;
      }
    }
    if (!hasEpochs) {
      sum = minHeightForVerticalLabel(
        period,
        periodStyle,
        verticalPadding: verticalPadding,
      );
    }
    result[period.id] = sum;
  }
  return result;
}

Map<int, double> buildEraHeights(
  List<TimelineBandSegment> eras,
  List<TimelineRowSegment> periods,
  Map<int, double> periodHeights,
  TextStyle? eraStyle, {
  double verticalPadding = 4,
}) {
  final result = <int, double>{};
  for (final era in eras) {
    var sum = 0.0;
    var hasPeriods = false;
    for (final period in periods) {
      if (period.isGap) {
        continue;
      }
      if (period.startMa <= era.startMa && period.endMa >= era.endMa) {
        hasPeriods = true;
        sum += periodHeights[period.id] ?? 0.0;
      }
    }
    if (!hasPeriods) {
      sum = minHeightForVerticalBandLabel(
        era,
        eraStyle,
        verticalPadding: verticalPadding,
      );
    }
    result[era.id] = sum;
  }
  return result;
}

Map<int, double> buildEonHeights(
  List<TimelineBandSegment> eons,
  List<TimelineBandSegment> eras,
  Map<int, double> eraHeights,
  TextStyle? eonStyle, {
  double verticalPadding = 4,
}) {
  final result = <int, double>{};
  for (final eon in eons) {
    var sum = 0.0;
    var hasEras = false;
    for (final era in eras) {
      if (era.isGap) {
        continue;
      }
      if (era.startMa <= eon.startMa && era.endMa >= eon.endMa) {
        hasEras = true;
        sum += eraHeights[era.id] ?? 0.0;
      }
    }
    if (!hasEras) {
      sum = minHeightForVerticalBandLabel(
        eon,
        eonStyle,
        verticalPadding: verticalPadding,
      );
    }
    result[eon.id] = sum;
  }
  return result;
}

import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/application/services/timeline_layout_color_keys.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';

TimelineBandSegment bandFromDivision(
  GeologicDivision? division,
  double unitSpan,
  GeologicRank rank, {
  required double startMa,
  required double endMa,
  required Map<int, GeologicDivision> divisionById,
}) {
  if (division == null) {
    return TimelineBandSegment(
      id: -1,
      label: '',
      rank: rank,
      startMa: startMa,
      endMa: endMa,
      colorKey: '',
      isGap: true,
      unitSpan: unitSpan,
      explanation: null,
    );
  }
  return TimelineBandSegment(
    id: division.id,
    label: division.name,
    rank: division.rank,
    startMa: division.startMa,
    endMa: division.endMa,
    colorKey: colorKeyForDivision(division, divisionById),
    isGap: false,
    unitSpan: unitSpan,
    explanation: division.explanation,
  );
}

TimelineRowSegment rowFromDivision(
  GeologicDivision? division,
  double unitSpan,
  GeologicRank rank, {
  required double startMa,
  required double endMa,
  required Map<int, GeologicDivision> divisionById,
}) {
  if (division == null) {
    return TimelineRowSegment(
      id: -1,
      label: '',
      rank: rank,
      startMa: startMa,
      endMa: endMa,
      colorKey: '',
      isGap: true,
      unitSpan: unitSpan,
      secondaryLabel: null,
      explanation: null,
    );
  }
  return TimelineRowSegment(
    id: division.id,
    label: division.name,
    rank: division.rank,
    startMa: division.startMa,
    endMa: division.endMa,
    colorKey: colorKeyForDivision(division, divisionById),
    isGap: false,
    unitSpan: unitSpan,
    secondaryLabel: null,
    explanation: division.explanation,
  );
}

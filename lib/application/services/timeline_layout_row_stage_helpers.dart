import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/application/services/timeline_layout_color_keys.dart';
import 'package:deep_time_2/application/services/timeline_layout_slots.dart';

List<TimelineRowSegment> buildStageRowFromSlots(
  List<TimelineSlot> slots,
  Map<int, GeologicDivision> divisionById,
) {
  final segments = <TimelineRowSegment>[];
  var index = 0;
  while (index < slots.length) {
    final currentEon = slots[index].eon;
    final eonSlots = <TimelineSlot>[];
    while (index < slots.length && slots[index].eon.id == currentEon.id) {
      eonSlots.add(slots[index]);
      index += 1;
    }

    final hasEpochs = eonSlots.any((slot) => slot.epoch != null);
    if (!hasEpochs) {
      final totalWeight = eonSlots.fold<double>(
        0.0,
        (sum, slot) => sum + _slotSpanForStage(slot),
      );
      segments.add(
        _rowFromDivision(
          null,
          totalWeight,
          GeologicRank.stage,
          startMa: currentEon.startMa,
          endMa: currentEon.endMa,
          divisionById: divisionById,
        ),
      );
      continue;
    }

    for (final slot in eonSlots) {
      final slotRange = _slotRangeForStage(slot);
      final epoch = slot.epoch;
      if (epoch == null) {
        segments.add(
          _rowFromDivision(
            null,
            _slotSpanForStage(slot),
            GeologicRank.stage,
            startMa: slotRange.startMa,
            endMa: slotRange.endMa,
            divisionById: divisionById,
          ),
        );
        continue;
      }
      final stages = slot.stages;
      if (stages.isEmpty) {
        segments.add(
          _rowFromDivision(
            null,
            _slotSpanForStage(slot),
            GeologicRank.stage,
            startMa: slotRange.startMa,
            endMa: slotRange.endMa,
            divisionById: divisionById,
          ),
        );
        continue;
      }
      for (final stage in stages) {
        segments.add(
          TimelineRowSegment(
            id: stage.id,
            label: stage.name,
            rank: stage.rank,
            startMa: stage.startMa,
            endMa: stage.endMa,
            colorKey: colorKeyForDivision(stage, divisionById),
            isGap: false,
            unitSpan: 1.0,
            secondaryLabel: null,
            explanation: stage.explanation,
          ),
        );
      }
    }
  }
  return segments;
}

TimelineRowSegment _rowFromDivision(
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

GeologicDivision _slotRangeForStage(TimelineSlot slot) {
  return slot.epoch ?? slot.period ?? slot.era ?? slot.eon;
}

double _slotSpanForStage(TimelineSlot slot) {
  final count = slot.stages.length;
  return count > 0 ? count.toDouble() : 1.0;
}


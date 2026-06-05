import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/application/services/timeline_layout_slots.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/application/services/timeline_layout_row_stage_helpers.dart';
import 'package:deep_time_2/application/services/timeline_layout_rows_helpers.dart';

class TimelineRowBuilder {
  TimelineRowBuilder({required this.divisionById});

  final Map<int, GeologicDivision> divisionById;

  List<TimelineBandSegment> buildBandRow(
    List<TimelineSlot> slots, {
    required GeologicRank rank,
  }) {
    final segments = <TimelineBandSegment>[];
    GeologicDivision? current;
    var currentStartMa = 0.0;
    var currentEndMa = 0.0;
    var span = 0.0;
    for (final slot in slots) {
      final division = slot.divisionFor(rank);
      final slotRange = _slotRangeForRank(slot, rank);
      if (division?.id != current?.id) {
        if (span > 0) {
          segments.add(
            bandFromDivision(
              current,
              span,
              rank,
              startMa: currentStartMa,
              endMa: currentEndMa,
              divisionById: divisionById,
            ),
          );
        }
        current = division;
        currentStartMa = division?.startMa ?? slotRange.startMa;
        currentEndMa = division?.endMa ?? slotRange.endMa;
        span = slot.weight;
      } else {
        span += slot.weight;
      }
    }
    if (span > 0) {
      segments.add(
        bandFromDivision(
          current,
          span,
          rank,
          startMa: currentStartMa,
          endMa: currentEndMa,
          divisionById: divisionById,
        ),
      );
    }
    return segments;
  }

  List<TimelineRowSegment> buildRankRow(
    List<TimelineSlot> slots, {
    required GeologicRank rank,
  }) {
    final segments = <TimelineRowSegment>[];
    GeologicDivision? current;
    int? currentGapKey;
    var currentStartMa = 0.0;
    var currentEndMa = 0.0;
    var span = 0.0;
    for (final slot in slots) {
      final division = slot.divisionFor(rank);
      final slotRange = _slotRangeForRank(slot, rank);
      final slotSpan = _slotSpanForRank(slot, rank);
      final gapKey = division == null ? _gapKeyForRank(slot, rank) : null;
      final shouldBreak =
          division?.id != current?.id ||
          (division == null && current == null && gapKey != currentGapKey);
      if (shouldBreak) {
        if (span > 0) {
          segments.add(
            rowFromDivision(
              current,
              span,
              rank,
              startMa: currentStartMa,
              endMa: currentEndMa,
              divisionById: divisionById,
            ),
          );
        }
        current = division;
        currentGapKey = gapKey;
        currentStartMa = division?.startMa ?? slotRange.startMa;
        currentEndMa = division?.endMa ?? slotRange.endMa;
        span = slotSpan;
      } else {
        span += slotSpan;
      }
    }
    if (span > 0) {
      segments.add(
        rowFromDivision(
          current,
          span,
          rank,
          startMa: currentStartMa,
          endMa: currentEndMa,
          divisionById: divisionById,
        ),
      );
    }
    return segments;
  }

  List<TimelineRowSegment> buildStageRow(List<TimelineSlot> slots) {
    return buildStageRowFromSlots(slots, divisionById);
  }

  double _slotSpanForRank(TimelineSlot slot, GeologicRank rank) {
    switch (rank) {
      case GeologicRank.period:
        final hasEpochOrStage = slot.epoch != null || slot.stages.isNotEmpty;
        if (!hasEpochOrStage) {
          return slot.weight;
        }
        final periodCount = slot.stages.length;
        return periodCount > 0 ? periodCount.toDouble() : 1.0;
      case GeologicRank.epoch:
      case GeologicRank.stage:
        final count = slot.stages.length;
        return count > 0 ? count.toDouble() : 1.0;
      case GeologicRank.eon:
      case GeologicRank.era:
      case GeologicRank.age:
        return slot.weight;
    }
  }

  GeologicDivision _slotRangeForRank(TimelineSlot slot, GeologicRank rank) {
    switch (rank) {
      case GeologicRank.eon:
        return slot.eon;
      case GeologicRank.era:
        return slot.era ?? slot.eon;
      case GeologicRank.period:
        return slot.period ?? slot.era ?? slot.eon;
      case GeologicRank.epoch:
        return slot.epoch ?? slot.period ?? slot.era ?? slot.eon;
      case GeologicRank.stage:
        return slot.epoch ?? slot.period ?? slot.era ?? slot.eon;
      case GeologicRank.age:
        return slot.eon;
    }
  }

  int _gapKeyForRank(TimelineSlot slot, GeologicRank rank) {
    switch (rank) {
      case GeologicRank.period:
        return slot.era?.id ?? slot.eon.id;
      case GeologicRank.epoch:
        return slot.period?.id ?? slot.era?.id ?? slot.eon.id;
      case GeologicRank.stage:
        return slot.epoch?.id ?? slot.period?.id ?? slot.era?.id ?? slot.eon.id;
      case GeologicRank.eon:
      case GeologicRank.era:
      case GeologicRank.age:
        return slot.eon.id;
    }
  }
}

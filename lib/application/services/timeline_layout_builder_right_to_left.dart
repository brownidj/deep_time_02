import 'package:flutter/widgets.dart';
import 'package:deep_time_2/application/services/timeline_layout_color_keys.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';

class RightToLeftDivisionLayout {
  RightToLeftDivisionLayout({
    required this.divisions,
    required this.divisionById,
    required this.childrenByParentId,
  });

  final List<GeologicDivision> divisions;
  final Map<int, GeologicDivision> divisionById;
  final Map<int, List<GeologicDivision>> childrenByParentId;

  static const _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const double _labelPadding = 8;

  List<TimelineBandSegment> eonSegments = [];
  List<TimelineBandSegment> eraSegments = [];
  List<TimelineRowSegment> periodSegments = [];
  List<TimelineRowSegment> epochSegments = [];
  List<TimelineRowSegment> stageSegments = [];

  double fixedHeight = 0;
  double ageHeight = 0;

  DivisionLayoutResult build() {
    final eons =
        divisions
            .where((division) => division.rank == GeologicRank.eon)
            .toList()
          ..sort((a, b) => b.startMa.compareTo(a.startMa));

    ageHeight = _computeAgeHeight();
    var totalUnits = 0.0;
    for (final eon in eons) {
      totalUnits += _buildEon(eon).toDouble();
    }
    fixedHeight = totalUnits * ageHeight;
    return DivisionLayoutResult(
      eonSegments: eonSegments,
      eraSegments: eraSegments,
      periodSegments: periodSegments,
      epochSegments: epochSegments,
      stageSegments: stageSegments,
      fixedHeight: fixedHeight,
    );
  }

  double _computeAgeHeight() {
    final stages =
        divisions
            .where((division) => division.rank == GeologicRank.stage)
            .toList();
    if (stages.isEmpty) {
      return _labelHeight('Stage', vertical: false);
    }
    var maxHeight = 0.0;
    for (final stage in stages) {
      final height = _labelHeight(stage.name, vertical: false);
      if (height > maxHeight) {
        maxHeight = height;
      }
    }
    return maxHeight <= 0 ? _labelHeight('Stage', vertical: false) : maxHeight;
  }

  double _labelHeight(String label, {required bool vertical}) {
    if (label.trim().isEmpty) {
      return 0;
    }
    final painter = TextPainter(
      text: TextSpan(text: label, style: _labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final size = vertical ? painter.width : painter.height;
    return size + (_labelPadding * 2);
  }

  int _labelUnits(String label, {required bool vertical}) {
    final height = _labelHeight(label, vertical: vertical);
    if (ageHeight <= 0) {
      return 1;
    }
    final units = (height / ageHeight).ceil();
    return units < 1 ? 1 : units;
  }

  List<GeologicDivision> _childrenOfRank(
    GeologicDivision parent,
    GeologicRank rank,
  ) {
    final children = childrenByParentId[parent.id] ?? const [];
    final filtered =
        children.where((division) => division.rank == rank).toList()
          ..sort((a, b) => b.startMa.compareTo(a.startMa));
    return filtered;
  }

  int _buildEon(GeologicDivision eon) {
    final eras = _childrenOfRank(eon, GeologicRank.era);
    if (eras.isEmpty) {
      final units = _labelUnits(eon.name, vertical: true);
      eonSegments.add(_bandFromDivision(eon, units.toDouble()));
      _addGapEra(eon, units);
      _addGapPeriod(eon, units);
      _addGapEpoch(eon, units);
      _addGapStage(eon, units);
      return units;
    }
    var total = 0;
    for (final era in eras) {
      total += _buildEra(era);
    }
    eonSegments.add(_bandFromDivision(eon, total.toDouble()));
    return total;
  }

  int _buildEra(GeologicDivision era) {
    final periods = _childrenOfRank(era, GeologicRank.period);
    if (periods.isEmpty) {
      final units = _labelUnits(era.name, vertical: true);
      eraSegments.add(_bandFromDivision(era, units.toDouble()));
      _addGapPeriod(era, units);
      _addGapEpoch(era, units);
      _addGapStage(era, units);
      return units;
    }
    var total = 0;
    for (final period in periods) {
      total += _buildPeriod(period);
    }
    eraSegments.add(_bandFromDivision(era, total.toDouble()));
    return total;
  }

  int _buildPeriod(GeologicDivision period) {
    final epochs = _childrenOfRank(period, GeologicRank.epoch);
    if (epochs.isEmpty) {
      final units = _labelUnits(period.name, vertical: true);
      periodSegments.add(_rowFromDivision(period, units.toDouble()));
      _addGapEpoch(period, units);
      _addGapStage(period, units);
      return units;
    }
    var total = 0;
    for (final epoch in epochs) {
      total += _buildEpoch(epoch);
    }
    periodSegments.add(_rowFromDivision(period, total.toDouble()));
    return total;
  }

  int _buildEpoch(GeologicDivision epoch) {
    final stages = _childrenOfRank(epoch, GeologicRank.stage);
    if (stages.isEmpty) {
      final units = _labelUnits(epoch.name, vertical: false);
      epochSegments.add(_rowFromDivision(epoch, units.toDouble()));
      _addGapStage(epoch, units);
      return units;
    }
    var total = 0;
    for (final stage in stages) {
      total += _buildStage(stage);
    }
    epochSegments.add(_rowFromDivision(epoch, total.toDouble()));
    return total;
  }

  int _buildStage(GeologicDivision stage) {
    stageSegments.add(_rowFromDivision(stage, 1.0));
    return 1;
  }

  void _addGapEra(GeologicDivision parent, int units) {
    eraSegments.add(_bandGap(parent, GeologicRank.era, units.toDouble()));
  }

  void _addGapPeriod(GeologicDivision parent, int units) {
    periodSegments.add(_rowGap(parent, GeologicRank.period, units.toDouble()));
  }

  void _addGapEpoch(GeologicDivision parent, int units) {
    epochSegments.add(_rowGap(parent, GeologicRank.epoch, units.toDouble()));
  }

  void _addGapStage(GeologicDivision parent, int units) {
    stageSegments.add(_rowGap(parent, GeologicRank.stage, units.toDouble()));
  }

  TimelineBandSegment _bandFromDivision(
    GeologicDivision division,
    double unitSpan,
  ) {
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

  TimelineRowSegment _rowFromDivision(
    GeologicDivision division,
    double unitSpan,
  ) {
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

  TimelineBandSegment _bandGap(
    GeologicDivision parent,
    GeologicRank rank,
    double unitSpan,
  ) {
    return TimelineBandSegment(
      id: -1,
      label: '',
      rank: rank,
      startMa: parent.startMa,
      endMa: parent.endMa,
      colorKey: '',
      isGap: true,
      unitSpan: unitSpan,
      explanation: null,
    );
  }

  TimelineRowSegment _rowGap(
    GeologicDivision parent,
    GeologicRank rank,
    double unitSpan,
  ) {
    return TimelineRowSegment(
      id: -1,
      label: '',
      rank: rank,
      startMa: parent.startMa,
      endMa: parent.endMa,
      colorKey: '',
      isGap: true,
      unitSpan: unitSpan,
      secondaryLabel: null,
      explanation: null,
    );
  }
}

class DivisionLayoutResult {
  const DivisionLayoutResult({
    required this.eonSegments,
    required this.eraSegments,
    required this.periodSegments,
    required this.epochSegments,
    required this.stageSegments,
    required this.fixedHeight,
  });

  final List<TimelineBandSegment> eonSegments;
  final List<TimelineBandSegment> eraSegments;
  final List<TimelineRowSegment> periodSegments;
  final List<TimelineRowSegment> epochSegments;
  final List<TimelineRowSegment> stageSegments;
  final double fixedHeight;
}

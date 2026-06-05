import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';

class TimelineSlotBuilder {
  List<TimelineSlot> buildSlots(
    List<GeologicDivision> eons,
    Map<int, List<GeologicDivision>> childrenByParentId,
  ) {
    final sortedEons = List<GeologicDivision>.from(eons)
      ..sort((a, b) => b.startMa.compareTo(a.startMa));
    final slots = <TimelineSlot>[];
    final mesozoicEra = _findEra(sortedEons, childrenByParentId, 'Mesozoic');
    final cenozoicEra = _findEra(sortedEons, childrenByParentId, 'Cenozoic');
    final mesozoicPeriodCount = mesozoicEra == null
        ? 0
        : _childrenOfRank(
            mesozoicEra,
            GeologicRank.period,
            childrenByParentId,
          ).length;
    final cenozoicEpochCount = cenozoicEra == null
        ? 0
        : _countEpochsForEra(cenozoicEra, childrenByParentId);
    final mesozoicPeriodWeight =
        (mesozoicPeriodCount > 0 && cenozoicEpochCount > 0)
        ? cenozoicEpochCount / mesozoicPeriodCount
        : 1.0;

    for (final eon in sortedEons) {
      final eras = _childrenOfRank(eon, GeologicRank.era, childrenByParentId)
        ..sort((a, b) => b.startMa.compareTo(a.startMa));
      if (eras.isEmpty) {
        slots.add(TimelineSlot(eon: eon));
        continue;
      }
      for (final era in eras) {
        final periods = _childrenOfRank(
          era,
          GeologicRank.period,
          childrenByParentId,
        )..sort((a, b) => b.startMa.compareTo(a.startMa));
        if (periods.isEmpty) {
          slots.add(TimelineSlot(eon: eon, era: era));
          continue;
        }
        for (final period in periods) {
          final epochs = _childrenOfRank(
            period,
            GeologicRank.epoch,
            childrenByParentId,
          )..sort((a, b) => b.startMa.compareTo(a.startMa));
          if (epochs.isEmpty) {
            slots.add(TimelineSlot(eon: eon, era: era, period: period));
            continue;
          }
          final isMesozoic = _isMesozoicPeriod(period, era);
          final epochWeight = isMesozoic
              ? mesozoicPeriodWeight / epochs.length
              : 1.0;
          for (final epoch in epochs) {
            final stages = _childrenOfRank(
              epoch,
              GeologicRank.stage,
              childrenByParentId,
            )..sort((a, b) => b.startMa.compareTo(a.startMa));
            slots.add(
              TimelineSlot(
                eon: eon,
                era: era,
                period: period,
                epoch: epoch,
                stages: stages,
                weight: epochWeight,
              ),
            );
          }
        }
      }
    }
    return slots;
  }

  List<GeologicDivision> _childrenOfRank(
    GeologicDivision parent,
    GeologicRank rank,
    Map<int, List<GeologicDivision>> childrenByParentId,
  ) {
    final children = childrenByParentId[parent.id] ?? const [];
    return children.where((division) => division.rank == rank).toList();
  }

  GeologicDivision? _findEra(
    List<GeologicDivision> eons,
    Map<int, List<GeologicDivision>> childrenByParentId,
    String name,
  ) {
    for (final eon in eons) {
      final eras = _childrenOfRank(eon, GeologicRank.era, childrenByParentId);
      for (final era in eras) {
        if (era.name == name) {
          return era;
        }
      }
    }
    return null;
  }

  int _countEpochsForEra(
    GeologicDivision era,
    Map<int, List<GeologicDivision>> childrenByParentId,
  ) {
    var count = 0;
    final periods = _childrenOfRank(
      era,
      GeologicRank.period,
      childrenByParentId,
    );
    for (final period in periods) {
      count += _childrenOfRank(
        period,
        GeologicRank.epoch,
        childrenByParentId,
      ).length;
    }
    return count;
  }

  bool _isMesozoicPeriod(GeologicDivision period, GeologicDivision? era) {
    if (period.rank != GeologicRank.period) {
      return false;
    }
    if (era?.name != 'Mesozoic') {
      return false;
    }
    return switch (period.name) {
      'Triassic' => true,
      'Jurassic' => true,
      'Cretaceous' => true,
      _ => false,
    };
  }
}

class TimelineSlot {
  TimelineSlot({
    required this.eon,
    this.era,
    this.period,
    this.epoch,
    List<GeologicDivision>? stages,
    double? weight,
  }) : stages = stages ?? const [],
       weight = weight ?? 1.0;

  final GeologicDivision eon;
  final GeologicDivision? era;
  final GeologicDivision? period;
  final GeologicDivision? epoch;
  final List<GeologicDivision> stages;
  final double weight;

  GeologicDivision? divisionFor(GeologicRank rank) {
    switch (rank) {
      case GeologicRank.eon:
        return eon;
      case GeologicRank.era:
        return era;
      case GeologicRank.period:
        return period;
      case GeologicRank.epoch:
        return epoch;
      case GeologicRank.stage:
        return null;
      case GeologicRank.age:
        return null;
    }
  }
}

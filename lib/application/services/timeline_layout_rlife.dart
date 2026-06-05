import 'package:deep_time_2/application/services/timeline_layout_color_keys.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/application/services/timeline_layout_slots.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';

class TimelineRLifeBuilder {
  TimelineRLifeBuilder({required this.divisionById});

  final Map<int, GeologicDivision> divisionById;

  List<TimelineRowSegment> buildRLifeRow(List<TimelineSlot> slots) {
    const rlifeData = {
      'Precambrian':
          'Microbial mats, Stromatolites, Early eukaryotes, Ediacaran organisms',
      'Cambrian':
          'Trilobites, Archaeocyathids, Early arthropods, Early chordates, Small shelly fossils',
      'Ordovician':
          'Brachiopods, Bryozoans, Graptolites, Nautiloids, Trilobites, Early jawless fish',
      'Silurian':
          'Sea scorpions, Corals, Crinoids, Jawless fish, Early jawed fish, Early land plants',
      'Devonian':
          'Armoured fish, Lobe-finned fish, Early sharks, Ammonoids, Early forests, First tetrapods',
      'Carboniferous':
          'Coal-swamp plants, Giant insects, Amphibians, Early reptiles, Crinoids, Brachiopods',
      'Permian':
          'Synapsids, Conifers, Seed ferns, Ammonoids, Fusulinids, Large terrestrial reptiles',
      'Triassic':
          'Early dinosaurs, Marine reptiles, Ammonites, Conifers, Early mammals, Pterosaurs',
      'Jurassic':
          'Dinosaurs, Pterosaurs, Marine reptiles, Ammonites, Cycads, Conifers, Early birds',
      'Cretaceous':
          'Flowering plants, Dinosaurs, Ammonites, Mosasaurs, Plesiosaurs, Birds, Early mammals',
      'Paleogene':
          'Mammals diversify, Birds diversify, Early whales, Grasses begin expanding, Foraminifera',
      'Neogene':
          'Grassland mammals, Horses, Antelope, Apes, Whales, Sharks, Modern bird groups',
      'Quaternary':
          'Mammoths, Mastodons, Sabre-toothed cats, Giant ground sloths, Humans, Ice Age megafauna',
    };
    final phanerozoicPeriods = {
      'Cambrian',
      'Ordovician',
      'Silurian',
      'Devonian',
      'Carboniferous',
      'Permian',
      'Triassic',
      'Jurassic',
      'Cretaceous',
      'Paleogene',
      'Neogene',
      'Quaternary',
    };

    final segments = <TimelineRowSegment>[];
    String? currentInterval;
    String? currentColorKey;
    double currentSpan = 0.0;
    double currentStartMa = 0.0;
    double currentEndMa = 0.0;

    void flush() {
      if (currentInterval == null) {
        return;
      }
      final label = rlifeData[currentInterval];
      if (label == null) {
        segments.add(
          TimelineRowSegment(
            id: -1,
            label: '',
            rank: GeologicRank.period,
            startMa: currentStartMa,
            endMa: currentEndMa,
            colorKey: '',
            isGap: true,
            unitSpan: currentSpan,
            secondaryLabel: null,
            explanation: null,
          ),
        );
      } else {
        segments.add(
          TimelineRowSegment(
            id: currentInterval.hashCode,
            label: label,
            rank: GeologicRank.period,
            startMa: currentStartMa,
            endMa: currentEndMa,
            colorKey: currentColorKey ?? '',
            isGap: false,
            unitSpan: currentSpan,
            secondaryLabel: null,
            explanation: null,
          ),
        );
      }
    }

    for (final slot in slots) {
      final period = slot.period;
      String interval;
      String? colorKey;
      double slotStart;
      double slotEnd;
      if (period != null && phanerozoicPeriods.contains(period.name)) {
        interval = period.name;
        colorKey = colorKeyForDivision(period, divisionById);
        slotStart = period.startMa;
        slotEnd = period.endMa;
      } else {
        interval = 'Precambrian';
        colorKey = _colorKeyForPrecambrian(slot);
        slotStart = slot.eon.startMa;
        slotEnd = slot.eon.endMa;
      }

      if (interval != currentInterval) {
        flush();
        currentInterval = interval;
        currentColorKey = colorKey;
        currentSpan = slot.weight;
        currentStartMa = slotStart;
        currentEndMa = slotEnd;
      } else {
        currentSpan += slot.weight;
        currentEndMa = slotEnd;
      }
    }
    flush();
    return segments;
  }

  List<TimelineRowSegment> buildRLifeRowFromPeriods(
    List<TimelineRowSegment> periodSegments,
  ) {
    const rlifeData = {
      'Precambrian':
          'Microbial mats, Stromatolites, Early eukaryotes, Ediacaran organisms',
      'Cambrian':
          'Trilobites, Archaeocyathids, Early arthropods, Early chordates, Small shelly fossils',
      'Ordovician':
          'Brachiopods, Bryozoans, Graptolites, Nautiloids, Trilobites, Early jawless fish',
      'Silurian':
          'Sea scorpions, Corals, Crinoids, Jawless fish, Early jawed fish, Early land plants',
      'Devonian':
          'Armoured fish, Lobe-finned fish, Early sharks, Ammonoids, Early forests, First tetrapods',
      'Carboniferous':
          'Coal-swamp plants, Giant insects, Amphibians, Early reptiles, Crinoids, Brachiopods',
      'Permian':
          'Synapsids, Conifers, Seed ferns, Ammonoids, Fusulinids, Large terrestrial reptiles',
      'Triassic':
          'Early dinosaurs, Marine reptiles, Ammonites, Conifers, Early mammals, Pterosaurs',
      'Jurassic':
          'Dinosaurs, Pterosaurs, Marine reptiles, Ammonites, Cycads, Conifers, Early birds',
      'Cretaceous':
          'Flowering plants, Dinosaurs, Ammonites, Mosasaurs, Plesiosaurs, Birds, Early mammals',
      'Paleogene':
          'Mammals diversify, Birds diversify, Early whales, Grasses begin expanding, Foraminifera',
      'Neogene':
          'Grassland mammals, Horses, Antelope, Apes, Whales, Sharks, Modern bird groups',
      'Quaternary':
          'Mammoths, Mastodons, Sabre-toothed cats, Giant ground sloths, Humans, Ice Age megafauna',
    };
    final phanerozoicPeriods = {
      'Cambrian',
      'Ordovician',
      'Silurian',
      'Devonian',
      'Carboniferous',
      'Permian',
      'Triassic',
      'Jurassic',
      'Cretaceous',
      'Paleogene',
      'Neogene',
      'Quaternary',
    };
    final segments = <TimelineRowSegment>[];
    String? currentInterval;
    String? currentColorKey;
    double currentSpan = 0.0;
    double currentStartMa = 0.0;
    double currentEndMa = 0.0;

    String precambrianColorKey() {
      final proterozoic = divisionById.values.firstWhere(
        (division) =>
            division.rank == GeologicRank.eon && division.name == 'Proterozoic',
        orElse: () => divisionById.values.first,
      );
      return colorKeyForDivision(proterozoic, divisionById);
    }

    void flush() {
      if (currentInterval == null) {
        return;
      }
      final label = rlifeData[currentInterval];
      if (label == null) {
        segments.add(
          TimelineRowSegment(
            id: -1,
            label: '',
            rank: GeologicRank.period,
            startMa: currentStartMa,
            endMa: currentEndMa,
            colorKey: '',
            isGap: true,
            unitSpan: currentSpan,
            secondaryLabel: null,
            explanation: null,
          ),
        );
      } else {
        segments.add(
          TimelineRowSegment(
            id: currentInterval.hashCode,
            label: label,
            rank: GeologicRank.period,
            startMa: currentStartMa,
            endMa: currentEndMa,
            colorKey: currentColorKey ?? '',
            isGap: false,
            unitSpan: currentSpan,
            secondaryLabel: null,
            explanation: null,
          ),
        );
      }
    }

    for (final segment in periodSegments) {
      String interval;
      String? colorKey;
      double segmentStart = segment.startMa;
      double segmentEnd = segment.endMa;
      if (!segment.isGap && phanerozoicPeriods.contains(segment.label)) {
        interval = segment.label;
        colorKey = segment.colorKey;
      } else {
        interval = 'Precambrian';
        colorKey = precambrianColorKey();
      }

      if (interval != currentInterval) {
        flush();
        currentInterval = interval;
        currentColorKey = colorKey;
        currentSpan = segment.unitSpan;
        currentStartMa = segmentStart;
        currentEndMa = segmentEnd;
      } else {
        currentSpan += segment.unitSpan;
        currentEndMa = segmentEnd;
      }
    }
    flush();
    return segments;
  }

  String _colorKeyForPrecambrian(TimelineSlot slot) {
    final proterozoic = divisionById.values.firstWhere(
      (division) =>
          division.rank == GeologicRank.eon && division.name == 'Proterozoic',
      orElse: () => slot.eon,
    );
    return colorKeyForDivision(proterozoic, divisionById);
  }
}

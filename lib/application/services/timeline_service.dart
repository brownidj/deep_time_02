import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/paleontology_taxon.dart';
import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/domain/models/fossil_range.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/domain/models/timeline_palette.dart';
import 'package:deep_time_2/domain/repositories/geologic_division_repository.dart';
import 'package:deep_time_2/domain/repositories/paleontology_repository.dart';
import 'package:deep_time_2/domain/repositories/clade_repository.dart';
import 'package:deep_time_2/domain/repositories/continent_repository.dart';
import 'package:deep_time_2/domain/repositories/waterway_repository.dart';
import 'package:deep_time_2/domain/repositories/timeline_marker_repository.dart';
import 'package:deep_time_2/domain/repositories/timeline_palette_repository.dart';
import 'package:deep_time_2/domain/repositories/paleo_ecology_repository.dart';

class TimelineSnapshot {
  const TimelineSnapshot({
    required this.divisions,
    required this.taxa,
    required this.ranges,
    required this.palette,
    required this.markers,
    required this.continents,
    required this.waterways,
    required this.paleoEcology,
    required this.clades,
  });

  final List<GeologicDivision> divisions;
  final List<PaleontologyTaxon> taxa;
  final List<FossilRange> ranges;
  final TimelinePalette palette;
  final TimelineMarkerCatalog markers;
  final List<TimelineEventDefinition> continents;
  final List<TimelineEventDefinition> waterways;
  final List<PaleoEcologyEntry> paleoEcology;
  final List<Clade> clades;
}

class TimelineService {
  TimelineService({
    required this.divisionRepository,
    required this.paleontologyRepository,
    required this.paletteRepository,
    required this.markerRepository,
    required this.cladeRepository,
    required this.continentRepository,
    required this.waterwayRepository,
    required this.paleoEcologyRepository,
  });

  final GeologicDivisionRepository divisionRepository;
  final PaleontologyRepository paleontologyRepository;
  final TimelinePaletteRepository paletteRepository;
  final TimelineMarkerRepository markerRepository;
  final CladeRepository cladeRepository;
  final ContinentRepository continentRepository;
  final WaterwayRepository waterwayRepository;
  final PaleoEcologyRepository paleoEcologyRepository;

  Future<TimelineSnapshot> loadSnapshot() async {
    final divisions = await divisionRepository.fetchAll();
    final taxa = await paleontologyRepository.fetchAllTaxa();
    final ranges = await paleontologyRepository.fetchRangesOverlapping(
      divisions.isEmpty ? 0 : divisions.first.startMa,
      0,
    );
    final palette = await paletteRepository.fetchPalette();
    final markers = await markerRepository.fetchMarkers();
    final continents = await continentRepository.fetchContinents();
    final waterways = await waterwayRepository.fetchWaterways();
    final paleoEcology = await paleoEcologyRepository.fetchEntries();
    final clades = await cladeRepository.fetchAll();
    _validatePaletteCoverage(palette, divisions);
    return TimelineSnapshot(
      divisions: divisions,
      taxa: taxa,
      ranges: ranges,
      palette: palette,
      markers: markers,
      continents: continents,
      waterways: waterways,
      paleoEcology: paleoEcology,
      clades: clades,
    );
  }

  Future<List<FossilRange>> rangesForDivision(GeologicDivision division) async {
    return paleontologyRepository.fetchRangesOverlapping(
      division.startMa,
      division.endMa,
    );
  }

  void _validatePaletteCoverage(
    TimelinePalette palette,
    List<GeologicDivision> divisions,
  ) {
    if (divisions.isEmpty) {
      return;
    }
    for (final division in divisions) {
      final key = _colorKeyForDivision(division, divisions);
      if (!palette.divisionColors.containsKey(key)) {
        throw StateError(
          'Missing palette color for ${division.rank.name} '
          '"${division.name}" (${division.startMa} Ma).',
        );
      }
    }
  }

  String _colorKeyForDivision(
    GeologicDivision division,
    List<GeologicDivision> divisions,
  ) {
    final divisionById = {for (final item in divisions) item.id: item};
    final parts = <GeologicDivision>[];
    GeologicDivision? current = division;
    while (current != null) {
      parts.add(current);
      final parentId = current.parentId;
      current = parentId == null ? null : divisionById[parentId];
    }
    var key = '';
    for (final part in parts.reversed) {
      key = divisionColorKey(
        name: part.name,
        rank: part.rank.name,
        parentKey: key.isEmpty ? null : key,
      );
    }
    return key;
  }
}

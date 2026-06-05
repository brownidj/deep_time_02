import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/application/services/timeline_service.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/paleontology_taxon.dart';
import 'package:deep_time_2/domain/models/fossil_range.dart';
import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/domain/models/timeline_palette.dart';
import 'package:deep_time_2/domain/repositories/clade_repository.dart';
import 'package:deep_time_2/domain/repositories/continent_repository.dart';
import 'package:deep_time_2/domain/repositories/geologic_division_repository.dart';
import 'package:deep_time_2/domain/repositories/paleontology_repository.dart';
import 'package:deep_time_2/domain/repositories/paleo_ecology_repository.dart';
import 'package:deep_time_2/domain/repositories/timeline_marker_repository.dart';
import 'package:deep_time_2/domain/repositories/timeline_palette_repository.dart';
import 'package:deep_time_2/domain/repositories/waterway_repository.dart';

class _FakeDivisionRepository implements GeologicDivisionRepository {
  _FakeDivisionRepository(this._divisions);

  final List<GeologicDivision> _divisions;

  @override
  Future<int> insert(GeologicDivision division) async {
    _divisions.add(division);
    return division.id;
  }

  @override
  Future<GeologicDivision?> fetchById(int id) async {
    return _divisions.where((division) => division.id == id).firstOrNull;
  }

  @override
  Future<List<GeologicDivision>> fetchAll() async => List.of(_divisions);

  @override
  Future<void> update(GeologicDivision division) async {
    final index = _divisions.indexWhere((item) => item.id == division.id);
    if (index >= 0) {
      _divisions[index] = division;
    }
  }

  @override
  Future<void> delete(int id) async {
    _divisions.removeWhere((division) => division.id == id);
  }
}

class _FakePaleontologyRepository implements PaleontologyRepository {
  _FakePaleontologyRepository(this._taxa, this._ranges);

  final List<PaleontologyTaxon> _taxa;
  final List<FossilRange> _ranges;

  @override
  Future<int> insertTaxon(PaleontologyTaxon taxon) async {
    _taxa.add(taxon);
    return taxon.id;
  }

  @override
  Future<PaleontologyTaxon?> fetchTaxonById(int id) async {
    return _taxa.where((taxon) => taxon.id == id).firstOrNull;
  }

  @override
  Future<List<PaleontologyTaxon>> fetchAllTaxa() async => List.of(_taxa);

  @override
  Future<void> updateTaxon(PaleontologyTaxon taxon) async {
    final index = _taxa.indexWhere((item) => item.id == taxon.id);
    if (index >= 0) {
      _taxa[index] = taxon;
    }
  }

  @override
  Future<void> deleteTaxon(int id) async {
    _taxa.removeWhere((taxon) => taxon.id == id);
  }

  @override
  Future<int> insertRange(FossilRange range) async {
    _ranges.add(range);
    return range.id;
  }

  @override
  Future<List<FossilRange>> fetchRangesForTaxon(int taxonId) async {
    return _ranges.where((range) => range.taxonId == taxonId).toList();
  }

  @override
  Future<List<FossilRange>> fetchRangesOverlapping(
    double startMa,
    double endMa,
  ) async {
    return _ranges
        .where((range) => range.startMa >= endMa && range.endMa <= startMa)
        .toList();
  }

  @override
  Future<void> updateRange(FossilRange range) async {
    final index = _ranges.indexWhere((item) => item.id == range.id);
    if (index >= 0) {
      _ranges[index] = range;
    }
  }

  @override
  Future<void> deleteRange(int id) async {
    _ranges.removeWhere((range) => range.id == id);
  }
}

class _FakePaletteRepository implements TimelinePaletteRepository {
  _FakePaletteRepository(this._palette);

  final TimelinePalette _palette;

  @override
  Future<TimelinePalette> fetchPalette() async => _palette;
}

class _FakeMarkerRepository implements TimelineMarkerRepository {
  _FakeMarkerRepository(this._markers);

  final TimelineMarkerCatalog _markers;

  @override
  Future<TimelineMarkerCatalog> fetchMarkers() async => _markers;
}

class _FakeCladeRepository implements CladeRepository {
  _FakeCladeRepository(this._clades);

  final List<Clade> _clades;

  @override
  Future<List<Clade>> fetchAll() async => _clades;
}

class _FakeContinentRepository implements ContinentRepository {
  _FakeContinentRepository(this._continents);

  final List<TimelineEventDefinition> _continents;

  @override
  Future<List<TimelineEventDefinition>> fetchContinents() async => _continents;
}

class _FakeWaterwayRepository implements WaterwayRepository {
  _FakeWaterwayRepository(this._waterways);

  final List<TimelineEventDefinition> _waterways;

  @override
  Future<List<TimelineEventDefinition>> fetchWaterways() async => _waterways;
}

class _FakePaleoEcologyRepository implements PaleoEcologyRepository {
  _FakePaleoEcologyRepository(this._entries);

  final List<PaleoEcologyEntry> _entries;

  @override
  Future<List<PaleoEcologyEntry>> fetchEntries() async => _entries;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}

void main() {
  final palette = TimelinePalette(
    divisionColors: {
      divisionColorKey(name: 'Cenozoic', rank: 'era', parentKey: null):
          0xFFE6DD5C,
      divisionColorKey(name: 'Jurassic', rank: 'period', parentKey: null):
          0xFF56A7CD,
    },
  );

  test('loadSnapshot collects divisions and taxa', () async {
    final divisions = [
      const GeologicDivision(
        id: 1,
        name: 'Cenozoic',
        rank: GeologicRank.era,
        startMa: 66.0,
        endMa: 0.0,
        parentId: null,
      ),
    ];
    final taxa = [
      const PaleontologyTaxon(id: 1, name: 'Mammals', summary: 'Example'),
    ];
    final ranges = [
      const FossilRange(id: 1, taxonId: 1, startMa: 66.0, endMa: 0.0),
    ];
    final service = TimelineService(
      divisionRepository: _FakeDivisionRepository(divisions),
      paleontologyRepository: _FakePaleontologyRepository(taxa, ranges),
      paletteRepository: _FakePaletteRepository(palette),
      markerRepository: _FakeMarkerRepository(
        const TimelineMarkerCatalog(events: [], extinctions: []),
      ),
      cladeRepository: _FakeCladeRepository(const []),
      continentRepository: _FakeContinentRepository(const []),
      waterwayRepository: _FakeWaterwayRepository(const []),
      paleoEcologyRepository: _FakePaleoEcologyRepository(const []),
    );

    final snapshot = await service.loadSnapshot();

    expect(snapshot.divisions, hasLength(1));
    expect(snapshot.taxa, hasLength(1));
    expect(snapshot.ranges, hasLength(1));
    expect(snapshot.palette, palette);
    expect(snapshot.markers.events, isEmpty);
  });

  test('rangesForDivision returns overlapping ranges', () async {
    final division = const GeologicDivision(
      id: 10,
      name: 'Jurassic',
      rank: GeologicRank.period,
      startMa: 201.3,
      endMa: 145.0,
      parentId: null,
    );
    final ranges = [
      const FossilRange(id: 1, taxonId: 1, startMa: 190.0, endMa: 150.0),
      const FossilRange(id: 2, taxonId: 2, startMa: 230.0, endMa: 210.0),
    ];
    final service = TimelineService(
      divisionRepository: _FakeDivisionRepository([division]),
      paleontologyRepository: _FakePaleontologyRepository(const [], ranges),
      paletteRepository: _FakePaletteRepository(palette),
      markerRepository: _FakeMarkerRepository(
        const TimelineMarkerCatalog(events: [], extinctions: []),
      ),
      cladeRepository: _FakeCladeRepository(const []),
      continentRepository: _FakeContinentRepository(const []),
      waterwayRepository: _FakeWaterwayRepository(const []),
      paleoEcologyRepository: _FakePaleoEcologyRepository(const []),
    );

    final results = await service.rangesForDivision(division);

    expect(results, hasLength(1));
    expect(results.first.id, 1);
  });
}

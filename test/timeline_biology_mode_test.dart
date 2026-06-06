import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/clade_zoom_level.dart';
import 'package:deep_time_2/domain/models/taxonomy_taxon.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/domain/repositories/taxonomy_repository.dart';
import 'package:deep_time_2/ui/models/biology_column_mode.dart';
import 'package:deep_time_2/ui/models/clade_label_mode.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';

import 'timeline_row_alignment_helpers.dart';

void main() {
  testWidgets('Taxonomy mode shows taxonomy drill-down column', (
    tester,
  ) async {
    await setLargeSurface(tester);
    final palette = testPalette();
    final layout = splitPeriodLayout();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);
    final repository = _FakeTaxonomyRepository(const [
      TaxonomyTaxon(id: 'life', name: 'Life', rank: 'root', hasChildren: true),
      TaxonomyTaxon(
        id: 'bacteria',
        parentId: 'life',
        name: 'Bacteria',
        rank: 'domain',
      ),
      TaxonomyTaxon(
        id: 'eukaryota',
        parentId: 'life',
        name: 'Eukaryota',
        rank: 'domain',
        hasChildren: true,
        displayDate: TaxonomyDisplayDate(
          startMa: 1850,
          basis: TaxonomyDateBasis.molecularClock,
        ),
      ),
      TaxonomyTaxon(
        id: 'animalia',
        parentId: 'eukaryota',
        name: 'Animalia',
        rank: 'kingdom',
      ),
      TaxonomyTaxon(
        id: 'fungi',
        parentId: 'eukaryota',
        name: 'Fungi',
        rank: 'kingdom',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 2000,
            height: 1200,
            child: Column(
              children: [
                TimelineBody(
                  layout: layout,
                  palette: palette,
                  markers: markers,
                  labelMode: TimeLabelMode.geologicTime,
                  scrollController: ScrollController(),
                  selectedId: null,
                  onBandSelect: (_) {},
                  onSelect: (_) {},
                  clades: const [],
                  taxonomyRepository: repository,
                  biologyColumnMode: BiologyColumnMode.taxonomic,
                  cladeViewMode: CladeViewMode.representativeOnly,
                  cladeLabelMode: CladeLabelMode.common,
                  cladeCategoryId: 'all',
                  cladeRepresentativeIds: const [],
                  cladeSearchQuery: '',
                  cladeSpotlightId: null,
                  onCladeSpotlight: (_) {},
                  visibleTracks: {...kDefaultTimelineTrackOrder}
                    ..remove(TimelineTrack.paleoEcology),
                  paleoEcology: const [],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Taxonomy'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('vertical-taxonomy-column')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('taxonomy-selected-name')), findsOneWidget);
    expect(find.text('Life'), findsWidgets);
    expect(find.byKey(const ValueKey('taxonomy-child-bacteria')), findsOneWidget);
    expect(find.byKey(const ValueKey('taxonomy-child-eukaryota')), findsOneWidget);
    expect(find.byKey(const ValueKey('vertical-clade-column')), findsNothing);
  });

  testWidgets('Cladistic mode filters clades without usable start dates', (
    tester,
  ) async {
    await setLargeSurface(tester);
    final palette = testPalette();
    final layout = splitPeriodLayout();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);
    const clades = [
      Clade(
        id: 'bad_nan',
        label: 'Bad NaN',
        scientificRank: 'test',
        startMa: double.nan,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 0,
        minZoomLevel: CladeZoomLevel.whole,
      ),
      Clade(
        id: 'bad_reverse',
        label: 'Bad Reverse',
        scientificRank: 'test',
        startMa: 20,
        endMa: 40,
        displayGroups: ['all'],
        displayPriority: 1,
        minZoomLevel: CladeZoomLevel.whole,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 2000,
            height: 1200,
            child: Column(
              children: [
                TimelineBody(
                  layout: layout,
                  palette: palette,
                  markers: markers,
                  labelMode: TimeLabelMode.geologicTime,
                  scrollController: ScrollController(),
                  selectedId: null,
                  onBandSelect: (_) {},
                  onSelect: (_) {},
                  clades: clades,
                  biologyColumnMode: BiologyColumnMode.cladistic,
                  cladeViewMode: CladeViewMode.representativeOnly,
                  cladeLabelMode: CladeLabelMode.common,
                  cladeCategoryId: 'all',
                  cladeRepresentativeIds: const [],
                  cladeSearchQuery: '',
                  cladeSpotlightId: null,
                  onCladeSpotlight: (_) {},
                  visibleTracks: {...kDefaultTimelineTrackOrder}
                    ..remove(TimelineTrack.paleoEcology),
                  paleoEcology: const [],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('vertical-clade-column')), findsOneWidget);
    expect(find.text('No clades with usable start dates'), findsOneWidget);
    expect(find.byKey(const ValueKey('vertical-clade-bad_nan')), findsNothing);
    expect(
      find.byKey(const ValueKey('vertical-clade-bad_reverse')),
      findsNothing,
    );
  });
}

class _FakeTaxonomyRepository implements TaxonomyRepository {
  const _FakeTaxonomyRepository(this._taxa);

  final List<TaxonomyTaxon> _taxa;

  @override
  Future<void> deleteTaxon(String id) async {}

  @override
  Future<List<TaxonomyTaxon>> fetchChildren(String parentTaxonId) async {
    return _taxa.where((taxon) => taxon.parentId == parentTaxonId).toList();
  }

  @override
  Future<List<TaxonomyTaxon>> fetchLineage(String taxonId) async {
    final lineage = <TaxonomyTaxon>[];
    var current = await fetchTaxonById(taxonId);
    while (current != null) {
      lineage.add(current);
      current = current.parentId == null
          ? null
          : await fetchTaxonById(current.parentId!);
    }
    return lineage.reversed.toList();
  }

  @override
  Future<List<TaxonomyTaxon>> fetchRootTaxa() async {
    return _taxa.where((taxon) => taxon.parentId == null).toList();
  }

  @override
  Future<TaxonomyTaxon?> fetchTaxonById(String id) async {
    for (final taxon in _taxa) {
      if (taxon.id == id) {
        return taxon;
      }
    }
    return null;
  }

  @override
  Future<TaxonomyTaxon?> fetchTaxonByOttId(int ottId) async {
    for (final taxon in _taxa) {
      if (taxon.sourceIds.ottId == ottId) {
        return taxon;
      }
    }
    return null;
  }

  @override
  Future<List<TaxonomyTaxon>> searchByName(String query, {int limit = 20}) async {
    return _taxa
        .where((taxon) => taxon.name.toLowerCase().contains(query.toLowerCase()))
        .take(limit)
        .toList();
  }

  @override
  Future<void> upsertTaxa(List<TaxonomyTaxon> taxa) async {}

  @override
  Future<void> upsertTaxon(TaxonomyTaxon taxon) async {}
}

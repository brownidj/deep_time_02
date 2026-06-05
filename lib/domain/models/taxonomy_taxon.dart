enum TaxonomyDateBasis {
  fossilFirstAppearance,
  molecularClock,
  combinedRange,
  manualCurated,
  proxy,
  unknown,
}

extension TaxonomyDateBasisMeta on TaxonomyDateBasis {
  String get id {
    switch (this) {
      case TaxonomyDateBasis.fossilFirstAppearance:
        return 'fossil_first_appearance';
      case TaxonomyDateBasis.molecularClock:
        return 'molecular_clock';
      case TaxonomyDateBasis.combinedRange:
        return 'combined_range';
      case TaxonomyDateBasis.manualCurated:
        return 'manual_curated';
      case TaxonomyDateBasis.proxy:
        return 'proxy';
      case TaxonomyDateBasis.unknown:
        return 'unknown';
    }
  }
}

TaxonomyDateBasis parseTaxonomyDateBasis(String? value) {
  switch (value) {
    case 'fossil_first_appearance':
      return TaxonomyDateBasis.fossilFirstAppearance;
    case 'molecular_clock':
      return TaxonomyDateBasis.molecularClock;
    case 'combined_range':
      return TaxonomyDateBasis.combinedRange;
    case 'manual_curated':
      return TaxonomyDateBasis.manualCurated;
    case 'proxy':
      return TaxonomyDateBasis.proxy;
    case 'unknown':
    default:
      return TaxonomyDateBasis.unknown;
  }
}

class TaxonomySourceIds {
  const TaxonomySourceIds({this.ottId, this.ncbiId, this.gbifId, this.pbdbId});

  final int? ottId;
  final int? ncbiId;
  final int? gbifId;
  final int? pbdbId;
}

class TaxonomyFossilDate {
  const TaxonomyFossilDate({
    this.firstAppearanceMa,
    this.source,
    this.confidence,
  });

  final double? firstAppearanceMa;
  final String? source;
  final String? confidence;
}

class TaxonomyMolecularDate {
  const TaxonomyMolecularDate({
    this.originMa,
    this.originMinMa,
    this.originMaxMa,
    this.source,
  });

  final double? originMa;
  final double? originMinMa;
  final double? originMaxMa;
  final String? source;
}

class TaxonomyDisplayDate {
  const TaxonomyDisplayDate({
    this.startMa,
    this.basis = TaxonomyDateBasis.unknown,
  });

  final double? startMa;
  final TaxonomyDateBasis basis;
}

class TaxonomyTaxon {
  const TaxonomyTaxon({
    required this.id,
    required this.name,
    required this.rank,
    this.parentId,
    this.commonName,
    this.summary,
    this.sourceIds = const TaxonomySourceIds(),
    this.synonyms = const [],
    this.fossilDate = const TaxonomyFossilDate(),
    this.molecularDate = const TaxonomyMolecularDate(),
    this.displayDate = const TaxonomyDisplayDate(),
    this.hasChildren = false,
    this.sourceBackbone,
    this.lastFetchedAt,
  });

  final String id;
  final String? parentId;
  final String name;
  final String rank;
  final String? commonName;
  final String? summary;
  final TaxonomySourceIds sourceIds;
  final List<String> synonyms;
  final TaxonomyFossilDate fossilDate;
  final TaxonomyMolecularDate molecularDate;
  final TaxonomyDisplayDate displayDate;
  final bool hasChildren;
  final String? sourceBackbone;
  final String? lastFetchedAt;
}

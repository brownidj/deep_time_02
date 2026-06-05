enum TimelineEventKind { bar, point }

class TimelineEventDefinition {
  const TimelineEventDefinition({
    this.id,
    required this.label,
    required this.shortLabel,
    required this.kind,
    this.explanation,
    this.image,
    this.sourcePage,
    this.imageLicense,
    this.imageLicenseUrl,
    this.imageAuthor,
    this.imageCredit,
    this.localAssetImage,
    this.startMa,
    this.endMa,
    this.atMa,
  });

  final String? id;
  final String label;
  final String shortLabel;
  final TimelineEventKind kind;
  final String? explanation;
  final String? image;
  final String? sourcePage;
  final String? imageLicense;
  final String? imageLicenseUrl;
  final String? imageAuthor;
  final String? imageCredit;
  final String? localAssetImage;
  final double? startMa;
  final double? endMa;
  final double? atMa;
}

enum ExtinctionAnchorType { period, stage, ma }

class ExtinctionAnchor {
  const ExtinctionAnchor({required this.type, this.label, this.ma});

  final ExtinctionAnchorType type;
  final String? label;
  final double? ma;
}

class ExtinctionDefinition {
  const ExtinctionDefinition({
    required this.label,
    required this.shortLabel,
    required this.isMajor,
    required this.anchor,
    this.explanation,
  });

  final String label;
  final String shortLabel;
  final bool isMajor;
  final ExtinctionAnchor anchor;
  final String? explanation;
}

class TimelineMarkerCatalog {
  const TimelineMarkerCatalog({
    required this.events,
    required this.extinctions,
  });

  final List<TimelineEventDefinition> events;
  final List<ExtinctionDefinition> extinctions;
}

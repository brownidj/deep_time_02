import 'package:deep_time_2/domain/models/clade_zoom_level.dart';

class Clade {
  const Clade({
    required this.id,
    required this.label,
    required this.scientificRank,
    required this.startMa,
    required this.endMa,
    required this.displayGroups,
    required this.displayPriority,
    required this.minZoomLevel,
    this.parentId,
    this.rangeNote,
    this.confidence,
    this.shortDescription,
    this.representativeTaxa,
    this.extinctionNote,
    this.tags,
    this.scientificLabel,
    this.openTreeName,
    this.ottId,
    this.branchPriority,
    this.cladisticRole,
    this.includeInMainTree,
    this.collapsedByDefault,
    this.openTree,
    this.zoomable = false,
    this.detailSource,
    this.detailScope,
    this.startMaDerivation,
    this.startMaNote,
    this.startMaSources,
  });

  final String id;
  final String label;
  final String scientificRank;
  final String? parentId;
  final double startMa;
  final double endMa;
  final String? rangeNote;
  final String? confidence;
  final List<String> displayGroups;
  final int displayPriority;
  final CladeZoomLevel minZoomLevel;
  final String? shortDescription;
  final List<String>? representativeTaxa;
  final String? extinctionNote;
  final List<String>? tags;
  final String? scientificLabel;
  final String? openTreeName;
  final int? ottId;
  final int? branchPriority;
  final String? cladisticRole;
  final bool? includeInMainTree;
  final bool? collapsedByDefault;
  final CladeOpenTreeMetadata? openTree;
  final bool zoomable;
  final String? detailSource;
  final String? detailScope;
  final String? startMaDerivation;
  final String? startMaNote;
  final List<CladeDateSource>? startMaSources;

  double get durationMa => startMa - endMa;
}

class CladeDateSource {
  const CladeDateSource({required this.label, this.url});

  final String label;
  final String? url;
}

class CladeOpenTreeMetadata {
  const CladeOpenTreeMetadata({
    this.ottId,
    this.matchedName,
    this.uniqueName,
    this.rank,
    this.flags,
    this.lineageIds,
    this.checkedAt,
  });

  final int? ottId;
  final String? matchedName;
  final String? uniqueName;
  final String? rank;
  final List<String>? flags;
  final List<int>? lineageIds;
  final String? checkedAt;
}

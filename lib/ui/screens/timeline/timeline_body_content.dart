import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/ui/models/biology_column_mode.dart';
import 'package:deep_time_2/ui/models/clade_label_mode.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_column_headers.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body_metrics.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_vertical_columns.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_vertical_overlays.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';

class TimelineBodyContent extends StatelessWidget {
  const TimelineBodyContent({
    super.key,
    required this.layout,
    required this.palette,
    required this.markers,
    required this.labelMode,
    required this.scrollController,
    required this.selectedId,
    required this.onBandSelect,
    required this.onSelect,
    required this.metrics,
    required this.clades,
    this.biologyColumnMode = BiologyColumnMode.cladistic,
    required this.cladeViewMode,
    required this.cladeCategoryId,
    required this.cladeLabelMode,
    required this.cladeRepresentativeIds,
    required this.cladeSearchQuery,
    required this.cladeSpotlightId,
    this.activeCladeRootId,
    this.childrenByParentId = const {},
    required this.onCladeSpotlight,
    this.onCladeRootChanged,
    required this.paleoEcology,
  });

  final TimelineLayoutSnapshot layout;
  final DeepTimePalette palette;
  final TimelineMarkerCatalog markers;
  final TimeLabelMode labelMode;
  final ScrollController scrollController;
  final int? selectedId;
  final ValueChanged<TimelineBandSegment> onBandSelect;
  final ValueChanged<TimelineRowSegment> onSelect;
  final TimelineBodyMetrics metrics;
  final List<Clade> clades;
  final BiologyColumnMode biologyColumnMode;
  final CladeViewMode cladeViewMode;
  final String cladeCategoryId;
  final CladeLabelMode cladeLabelMode;
  final List<String> cladeRepresentativeIds;
  final String cladeSearchQuery;
  final String? cladeSpotlightId;
  final String? activeCladeRootId;
  final Map<String, List<Clade>> childrenByParentId;
  final ValueChanged<Clade> onCladeSpotlight;
  final ValueChanged<String?>? onCladeRootChanged;
  final List<PaleoEcologyEntry> paleoEcology;

  @override
  Widget build(BuildContext context) {
    final cladeHeaderLabel = _cladeHeaderText();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TimelineColumnHeaders(
          metrics: metrics,
          labelMode: labelMode,
          cladeHeaderLabel: cladeHeaderLabel,
        ),
        Expanded(child: _buildVerticalCanvas()),
      ],
    );
  }

  String _cladeHeaderText() {
    if (biologyColumnMode == BiologyColumnMode.taxonomic) {
      return 'Taxonomy';
    }
    final rootId = activeCladeRootId?.trim();
    if (rootId == null || rootId.isEmpty) {
      return 'Clades';
    }
    for (final clade in clades) {
      if (clade.id == rootId) {
        return 'Clades: ${clade.label}';
      }
    }
    return 'Clades';
  }

  Widget _buildVerticalCanvas() {
    final contentHeight = math.max(metrics.minHeight, metrics.scrollHeight);
    return Scrollbar(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        child: SizedBox(
          height: contentHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              TimelineVerticalColumns(
                layout: layout,
                markers: markers,
                palette: palette,
                selectedId: selectedId,
                onBandSelect: onBandSelect,
                onSelect: onSelect,
                scrollController: scrollController,
                clades: clades,
                biologyColumnMode: biologyColumnMode,
                cladeViewMode: cladeViewMode,
                cladeCategoryId: cladeCategoryId,
                cladeLabelMode: cladeLabelMode,
                cladeRepresentativeIds: cladeRepresentativeIds,
                cladeSearchQuery: cladeSearchQuery,
                cladeSpotlightId: cladeSpotlightId,
                activeCladeRootId: activeCladeRootId,
                childrenByParentId: childrenByParentId,
                onCladeSpotlight: onCladeSpotlight,
                onCladeRootChanged: onCladeRootChanged ?? (_) {},
                metrics: metrics,
                paleoEcology: paleoEcology,
              ),
              Positioned.fill(
                child: TimelineVerticalOverlays(
                  metrics: metrics,
                  contentHeight: contentHeight,
                  markers: markers,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

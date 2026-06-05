import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:deep_time_2/app/app_debug.dart';
import 'package:deep_time_2/application/services/clade_search.dart';
import 'package:deep_time_2/application/services/clade_visibility_resolver.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/clade_bar.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';
import 'package:deep_time_2/ui/widgets/timeline_range_mapper.dart';
import 'package:deep_time_2/ui/widgets/time_range_format.dart';

class CladeLane extends StatelessWidget {
  const CladeLane({
    super.key,
    required this.layout,
    required this.scrollWidth,
    required this.totalUnits,
    required this.height,
    required this.scrollController,
    required this.clades,
    required this.viewMode,
    required this.displayGroupId,
    required this.representativeIds,
    required this.searchQuery,
    required this.spotlightId,
    required this.onSpotlight,
  });

  final TimelineLayoutSnapshot layout;
  final double scrollWidth;
  final double totalUnits;
  final double height;
  final ScrollController scrollController;
  final List<Clade> clades;
  final CladeViewMode viewMode;
  final String displayGroupId;
  final List<String> representativeIds;
  final String searchQuery;
  final String? spotlightId;
  final ValueChanged<Clade> onSpotlight;

  @override
  Widget build(BuildContext context) {
    if (clades.isEmpty || scrollWidth <= 0 || totalUnits <= 0) {
      return _emptyLane('No clades loaded');
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DeepTimePalette.timelineGapBackground,
        border: Border.all(color: DeepTimePalette.periodDivider),
      ),
      child: AnimatedBuilder(
        animation: scrollController,
        builder: (context, child) {
          final mapper = TimelineRangeMapper(
            segments: layout.periodSegments,
            totalUnits: totalUnits,
            scrollWidth: scrollWidth,
            oldestMa: layout.oldestMa,
            youngestMa: layout.youngestMa,
          );
          var viewportWidth = scrollWidth;
          var scrollOffset = 0.0;
          if (scrollController.hasClients) {
            final position = scrollController.position;
            if (position.hasContentDimensions) {
              viewportWidth = position.viewportDimension;
            }
            if (position.hasPixels) {
              scrollOffset = position.pixels;
            }
          }
          final visibleStart =
              mapper.maForX(scrollOffset) ?? layout.oldestMa;
          final visibleEnd =
              mapper.maForX(scrollOffset + viewportWidth) ?? layout.youngestMa;
          final resolver = CladeVisibilityResolver();
          final zoomLevel = resolver.zoomLevelForScale(
            AppDebug.timelineScale,
          );
          final filtered = _filterCladesForMode();
          final displayFilterId =
              viewMode == CladeViewMode.byCategory ? displayGroupId : null;
          final visible = resolver.resolve(
            clades: filtered,
            zoomLevel: zoomLevel,
            visibleStartMa: visibleStart,
            visibleEndMa: visibleEnd,
            displayGroupId: displayFilterId,
          );

          if (visible.isEmpty) {
            return _emptyLane(_emptyMessage());
          }
          return Stack(
            children: [
              for (final entry in _layoutBars(visible, mapper))
                Positioned(
                  left: entry.left,
                  top: entry.top,
                  child: Tooltip(
                    message: entry.tooltip,
                    child: GestureDetector(
                      onTap: () => onSpotlight(entry.clade),
                      child: CladeBar(
                        clade: entry.clade,
                        width: entry.width,
                        height: entry.height,
                        isDimmed:
                            spotlightId != null &&
                            spotlightId != entry.clade.id,
                        isHighlighted: spotlightId == entry.clade.id,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Clade> _filterCladesForMode() {
    if (viewMode == CladeViewMode.representativeOnly) {
      return _filterRepresentative(clades);
    }
    if (viewMode == CladeViewMode.searchSpotlight) {
      final query = searchQuery.trim();
      if (query.isEmpty) {
        return _filterRepresentative(clades);
      }
      return searchClades(clades, query);
    }
    return clades;
  }

  List<Clade> _filterRepresentative(List<Clade> source) {
    if (representativeIds.isEmpty) {
      return source;
    }
    final idSet = representativeIds.toSet();
    return source.where((clade) => idSet.contains(clade.id)).toList();
  }

  String _emptyMessage() {
    if (viewMode == CladeViewMode.searchSpotlight &&
        searchQuery.trim().isNotEmpty) {
      return 'No matching clades';
    }
    if (viewMode == CladeViewMode.byCategory &&
        displayGroupId.isNotEmpty &&
        displayGroupId != 'all') {
      return 'No clades in this category';
    }
    return 'No clades in view';
  }

  Widget _emptyLane(String message) {
    final style = const TextStyle(
      color: DeepTimePalette.panelText,
      fontSize: 12,
    );
    return Center(child: Text(message, style: style));
  }

  List<_CladeBarLayout> _layoutBars(
    List<Clade> visible,
    TimelineRangeMapper mapper,
  ) {
    const padding = 10.0;
    const spacing = 4.0;
    const minBarWidth = 12.0;
    final count = visible.length;
    final available =
        height - padding * 2 - math.max(0, count - 1) * spacing;
    final barHeight = count > 0 ? math.max(8.0, available / count) : 0.0;

    final layouts = <_CladeBarLayout>[];
    for (var i = 0; i < visible.length; i++) {
      final clade = visible[i];
      final xStart = mapper.xForMa(clade.startMa) ?? 0.0;
      final xEnd = mapper.xForMa(clade.endMa) ?? scrollWidth;
      final left = math.min(xStart, xEnd);
      final width = math.max(minBarWidth, (xEnd - xStart).abs());
      final top = padding + i * (barHeight + spacing);
      if (top + barHeight > height - padding) {
        break;
      }
      layouts.add(
        _CladeBarLayout(
          clade: clade,
          left: left,
          top: top,
          width: width,
          height: barHeight,
        ),
      );
    }
    return layouts;
  }
}

class _CladeBarLayout {
  const _CladeBarLayout({
    required this.clade,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final Clade clade;
  final double left;
  final double top;
  final double width;
  final double height;

  String get tooltip {
    final start = clade.startMa.toStringAsFixed(1);
    final end = clade.endMa.toStringAsFixed(1);
    final duration = (clade.startMa - clade.endMa).abs().toStringAsFixed(1);
    return '${clade.label} • '
        'Crown age: $start Ma - End $end Ma - Myr $duration';
  }
}

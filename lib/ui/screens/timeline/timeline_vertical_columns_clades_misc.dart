part of 'timeline_vertical_columns.dart';

String _emptyCladeMessage({
  required CladeViewMode viewMode,
  required String displayGroupId,
  required String searchQuery,
}) {
  if (viewMode == CladeViewMode.searchSpotlight && searchQuery.trim().isNotEmpty) {
    return 'No matching clades';
  }
  if (viewMode == CladeViewMode.byCategory &&
      displayGroupId.isNotEmpty &&
      displayGroupId != 'all') {
    return 'No clades in this category';
  }
  return 'No clades in view';
}

Widget _emptyCladeColumn(String message) {
  return Center(
    child: Text(
      message,
      style: const TextStyle(color: DeepTimePalette.panelText, fontSize: 12),
      textAlign: TextAlign.center,
    ),
  );
}

double _lucaTop(List<_VerticalCladeBarLayout> layouts, double maxHeight) {
  for (final entry in layouts) {
    if (entry.clade.id.toLowerCase() == 'luca') {
      return entry.top.clamp(0.0, maxHeight);
    }
  }
  return 0.0;
}

double _hadeanHeight({
  required List<TimelineBandSegment> eonSegments,
  required List<double> eonHeights,
}) {
  final last = math.min(eonSegments.length, eonHeights.length);
  for (var i = 0; i < last; i += 1) {
    final segment = eonSegments[i];
    if (segment.isGap) {
      continue;
    }
    if (segment.label.trim().toLowerCase() == 'hadean') {
      return math.max(0.0, eonHeights[i]);
    }
  }
  return 0.0;
}

double _pinnedRowCapHeight({
  required List<TimelineBandSegment> eonSegments,
  required List<double> eonHeights,
  required double scale,
}) {
  final hadeanHeight = _hadeanHeight(eonSegments: eonSegments, eonHeights: eonHeights);
  if (hadeanHeight <= 0) {
    return 0.0;
  }
  final boundedScale = scale <= 0 ? 1.0 : scale;
  return hadeanHeight * (AppDebug.minTimelineScale / boundedScale);
}

double _resolveTopStripHeight({
  required List<_VerticalCladeBarLayout> barLayouts,
  required double maxHeight,
  required double pinnedCapHeight,
  required bool hasActiveRoot,
}) {
  final lucaTop = _lucaTop(barLayouts, maxHeight);
  if (pinnedCapHeight <= 0) {
    return lucaTop;
  }
  if (lucaTop > 0) {
    return math.min(lucaTop, pinnedCapHeight);
  }
  if (hasActiveRoot && barLayouts.isNotEmpty) {
    return pinnedCapHeight;
  }
  return 0.0;
}

void _scheduleFocusedRootAutoScroll({
  required ScrollController scrollController,
  required String? activeCladeRootId,
  required String? pendingFocusedRootAutoScrollId,
  required ValueChanged<String> onFocusedRootAutoScrollHandled,
  required List<_VerticalCladeBarLayout> barLayouts,
  required double topStripHeight,
}) {
  final rootId = activeCladeRootId?.trim();
  final pendingRootId = pendingFocusedRootAutoScrollId?.trim();
  if (rootId == null || rootId.isEmpty || rootId != pendingRootId) {
    return;
  }
  _VerticalCladeBarLayout? rootEntry;
  for (final entry in barLayouts) {
    if (entry.clade.id == rootId) {
      rootEntry = entry;
      break;
    }
  }
  if (rootEntry == null) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!scrollController.hasClients) {
      return;
    }
    // Focused subtree views do not inherit the LUCA/Hadean top-space used by
    // the overview. This small offset restores a comparable visual buffer so
    // the focused root sits just below the pinned strip instead of touching it.
    final targetOffset = (rootEntry!.top - topStripHeight - 2.0).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );
    final currentOffset = scrollController.position.pixels;
    onFocusedRootAutoScrollHandled(rootId);
    if ((currentOffset - targetOffset).abs() <= 2.0) {
      return;
    }
    scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  });
}

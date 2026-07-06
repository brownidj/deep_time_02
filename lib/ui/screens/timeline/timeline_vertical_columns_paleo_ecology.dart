part of 'timeline_vertical_columns.dart';

class _VerticalPaleoEcologyColumn extends StatelessWidget {
  const _VerticalPaleoEcologyColumn({
    required this.width,
    required this.height,
    required this.layout,
    required this.entries,
    required this.palette,
    required this.stageHeights,
  });

  final double width;
  final double height;
  final TimelineLayoutSnapshot layout;
  final List<PaleoEcologyEntry> entries;
  final DeepTimePalette palette;
  final List<double> stageHeights;

  @override
  Widget build(BuildContext context) {
    if (width <= 0 || height <= 0) {
      return const SizedBox.shrink();
    }
    final blocks = _buildBlocks(
      layout,
      stageHeights: stageHeights,
      columnHeight: height,
    );
    final entriesByKey = {for (final entry in entries) entry.lookupKey: entry};

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: [
          for (final block in blocks)
            _buildBlock(
              context,
              block: block,
              width: width,
              entry: entriesByKey[block.sourceKey],
              entriesByKey: entriesByKey,
              palette: palette,
            ),
        ],
      ),
    );
  }

  Widget _buildBlock(
    BuildContext context, {
    required _PaleoBlock block,
    required double width,
    required PaleoEcologyEntry? entry,
    required Map<String, PaleoEcologyEntry> entriesByKey,
    required DeepTimePalette palette,
  }) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: DeepTimePalette.darkLabel,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    final displayResolution = entry == null
        ? null
        : resolvePaleoEcologyDisplay(entry, entriesByKey);
    final displayEntry = displayResolution?.entry;
    final isVisibleBlock = block.sourceKey != null;
    final summary = displayEntry == null
        ? null
        : paleoEcologySummaryText(
            displayEntry,
            showInheritedMarker: displayResolution?.inheritedFromRank != null,
          );
    final explanationMessage = displayEntry == null
        ? null
        : _paleoEcologyTooltipMessage(
            displayEntry,
            block,
            inheritedFromRank: displayResolution?.inheritedFromRank,
          );
    if (entry != null &&
        const {
          'Greenlandian',
          'Northgrippian',
          'Meghalayan',
        }.contains(entry.name)) {
      AppDebug.log(
        'Paleo ecology block ${entry.name}: '
        'height=${block.height.toStringAsFixed(2)} '
        'range=${block.startMa}->${block.endMa} summary=$summary',
      );
    }
    final backgroundColor = !isVisibleBlock
        ? Colors.transparent
        : block.colorKey == null
        ? DeepTimePalette.timelineGapBackground
        : _safeColorForKey(block.colorKey!, palette);
    final blockBody = SizedBox(
      key: block.sourceKey == null
          ? null
          : ValueKey('paleo-ecology-block-${block.sourceKey}'),
      width: width,
      height: block.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: isVisibleBlock
              ? Border(
                  right: BorderSide(color: DeepTimePalette.periodDivider),
                  bottom: BorderSide(color: DeepTimePalette.periodDivider),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: summary == null
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    summary,
                    style: textStyle,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
        ),
      ),
    );
    if (explanationMessage == null || explanationMessage.trim().isEmpty) {
      return blockBody;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => showTimelineExplanationDialog(
        context: context,
        title: entry?.name ?? 'Paleo-ecology',
        explanation: explanationMessage,
      ),
      child: blockBody,
    );
  }
}

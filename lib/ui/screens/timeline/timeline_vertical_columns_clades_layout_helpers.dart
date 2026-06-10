part of 'timeline_vertical_columns.dart';

String _formatCladeStartMa(double value) {
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _buildCladeDetailsText(_VerticalCladeBarLayout entry) {
  final clade = entry.clade;
  final scientific = (clade.scientificLabel ?? clade.openTreeName ?? '').trim();
  final parts = <String>[
    'Display name: ${clade.label}',
    'Scientific name: ${scientific.isEmpty ? '-' : scientific}',
    'Rank: ${clade.scientificRank}',
    'ID: ${clade.id}',
    'Parent: ${entry.parentLabel ?? '-'}',
    'Start: ${_formatCladeStartMa(clade.startMa)} Ma',
    'Start derivation: ${clade.startMaDerivation ?? '-'}',
    'End: ${_formatCladeStartMa(clade.endMa)} Ma',
    'Duration: ${_formatCladeStartMa(clade.durationMa)} Ma',
    'Confidence: ${clade.confidence ?? '-'}',
    'Zoomable: ${clade.zoomable ? 'yes' : 'no'}',
    'Minimum zoom level: ${clade.minZoomLevel.id}',
    'Display priority: ${clade.displayPriority}',
    'Branch priority: ${clade.branchPriority?.toString() ?? '-'}',
    'OpenTree OTT: ${clade.ottId?.toString() ?? '-'}',
    'Cladistic role: ${clade.cladisticRole ?? '-'}',
    'Detail source: ${clade.detailSource ?? '-'}',
    'Detail scope: ${clade.detailScope ?? '-'}',
    'Display groups: ${clade.displayGroups.isEmpty ? '-' : clade.displayGroups.join(', ')}',
    'Representative taxa: ${(clade.representativeTaxa == null || clade.representativeTaxa!.isEmpty) ? '-' : clade.representativeTaxa!.join(', ')}',
    'Tags: ${(clade.tags == null || clade.tags!.isEmpty) ? '-' : clade.tags!.join(', ')}',
    'Summary: ${clade.shortDescription ?? '-'}',
    'Range note: ${clade.rangeNote ?? '-'}',
    'Start note: ${clade.startMaNote ?? '-'}',
    'Extinction note: ${clade.extinctionNote ?? '-'}',
  ];
  if (clade.startMaSources != null && clade.startMaSources!.isNotEmpty) {
    parts.add('Start sources:');
    for (final source in clade.startMaSources!) {
      final url = source.url?.trim();
      parts.add(
        url == null || url.isEmpty
            ? '- ${source.label}'
            : '- ${source.label} ($url)',
      );
    }
  }
  final openTree = clade.openTree;
  if (openTree != null) {
    parts.addAll([
      'OpenTree matched name: ${openTree.matchedName?.trim().isNotEmpty == true ? openTree.matchedName!.trim() : '-'}',
      'OpenTree unique name: ${openTree.uniqueName?.trim().isNotEmpty == true ? openTree.uniqueName!.trim() : '-'}',
      'OpenTree rank: ${openTree.rank?.trim().isNotEmpty == true ? openTree.rank!.trim() : '-'}',
      'OpenTree flags: ${(openTree.flags == null || openTree.flags!.isEmpty) ? '-' : openTree.flags!.join(', ')}',
      'OpenTree lineage IDs: ${(openTree.lineageIds == null || openTree.lineageIds!.isEmpty) ? '-' : openTree.lineageIds!.join(', ')}',
      'OpenTree checked at: ${openTree.checkedAt?.trim().isNotEmpty == true ? openTree.checkedAt!.trim() : '-'}',
    ]);
  }
  return parts.join('\n');
}

List<Clade> _orderedTreeClades(
  List<Clade> visible, {
  required _StageRangeMapper mapper,
  required double columnHeight,
}) {
  final byId = {for (final clade in visible) clade.id: clade};
  final childrenByParentId = <String, List<Clade>>{};
  final roots = <Clade>[];
  for (final clade in visible) {
    final parentId = clade.parentId;
    if (parentId == null || !byId.containsKey(parentId)) {
      roots.add(clade);
      continue;
    }
    childrenByParentId.putIfAbsent(parentId, () => []).add(clade);
  }

  int compareClades(Clade a, Clade b) {
    final startCompare = b.startMa.compareTo(a.startMa);
    if (startCompare != 0) {
      return startCompare;
    }
    final priorityCompare = a.displayPriority.compareTo(b.displayPriority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    return a.label.compareTo(b.label);
  }

  (double, double) effectiveBounds(Clade clade) {
    var start = clade.startMa;
    var end = clade.endMa;
    if (start > end && (start - end).abs() > 0.0001) {
      return (start, end);
    }
    final visited = <String>{clade.id};
    var cursor = clade;
    while (cursor.parentId != null) {
      final parent = byId[cursor.parentId!];
      if (parent == null || !visited.add(parent.id)) {
        break;
      }
      if (parent.startMa > parent.endMa &&
          (parent.startMa - parent.endMa).abs() > 0.0001) {
        return (parent.startMa, parent.endMa);
      }
      cursor = parent;
    }
    return (start, end);
  }

  final subtreeOrderStatsById = <String, _OverviewCladeOrderStats>{};
  _OverviewCladeOrderStats computeSubtreeOrderStats(Clade clade) {
    final cached = subtreeOrderStatsById[clade.id];
    if (cached != null) {
      return cached;
    }
    final (startMa, endMa) = effectiveBounds(clade);
    final selfTop = math.min(
      (mapper.yForMa(startMa) ?? 0.0).toDouble(),
      (mapper.yForMa(endMa) ?? columnHeight).toDouble(),
    );
    final selfBottom = math.max(
      (mapper.yForMa(startMa) ?? 0.0).toDouble(),
      (mapper.yForMa(endMa) ?? columnHeight).toDouble(),
    );
    var minTop = selfTop;
    var maxBottom = selfBottom;
    var weightedCenterSum = (selfTop + selfBottom) / 2;
    var weightedCount = 1.0;

    final children = childrenByParentId[clade.id] ?? const <Clade>[];
    for (final child in children) {
      final childStats = computeSubtreeOrderStats(child);
      minTop = math.min(minTop, childStats.minTop);
      maxBottom = math.max(maxBottom, childStats.maxBottom);
      weightedCenterSum += childStats.centerY * childStats.weight;
      weightedCount += childStats.weight;
    }

    final stats = _OverviewCladeOrderStats(
      minTop: minTop,
      maxBottom: maxBottom,
      centerY: weightedCenterSum / weightedCount,
      weight: weightedCount,
    );
    subtreeOrderStatsById[clade.id] = stats;
    return stats;
  }

  void sortChildrenRecursively(Clade parent) {
    final children = childrenByParentId[parent.id];
    if (children == null || children.isEmpty) {
      return;
    }
    for (final child in children) {
      sortChildrenRecursively(child);
    }
    children.sort((a, b) {
      final aStats = computeSubtreeOrderStats(a);
      final bStats = computeSubtreeOrderStats(b);
      final centerCompare = aStats.centerY.compareTo(bStats.centerY);
      if (centerCompare != 0) {
        return centerCompare;
      }
      final topCompare = aStats.minTop.compareTo(bStats.minTop);
      if (topCompare != 0) {
        return topCompare;
      }
      return compareClades(a, b);
    });
  }

  for (final root in roots) {
    sortChildrenRecursively(root);
  }
  roots.sort((a, b) {
    final aStats = computeSubtreeOrderStats(a);
    final bStats = computeSubtreeOrderStats(b);
    final centerCompare = aStats.centerY.compareTo(bStats.centerY);
    if (centerCompare != 0) {
      return centerCompare;
    }
    final topCompare = aStats.minTop.compareTo(bStats.minTop);
    if (topCompare != 0) {
      return topCompare;
    }
    return compareClades(a, b);
  });

  final ordered = <Clade>[];
  void visit(Clade clade) {
    ordered.add(clade);
    for (final child in childrenByParentId[clade.id] ?? const <Clade>[]) {
      visit(child);
    }
  }

  for (final root in roots) {
    visit(root);
  }
  return ordered;
}

class _OverviewCladeOrderStats {
  const _OverviewCladeOrderStats({
    required this.minTop,
    required this.maxBottom,
    required this.centerY,
    required this.weight,
  });

  final double minTop;
  final double maxBottom;
  final double centerY;
  final double weight;
}

List<_VerticalCladeConnectorLayout> _layoutCladeConnectors(
  List<_VerticalCladeBarLayout> bars,
) {
  final byId = {for (final bar in bars) bar.clade.id: bar};
  final connectors = <_VerticalCladeConnectorLayout>[];
  for (final child in bars) {
    final parentId = child.clade.parentId;
    if (parentId == null) {
      continue;
    }
    final parent = byId[parentId];
    if (parent == null) {
      continue;
    }
    final parentX = parent.left;
    final childX = child.left;
    if ((parentX - childX).abs() < 1) {
      continue;
    }
    connectors.add(
      _VerticalCladeConnectorLayout(
        parent: parent.clade,
        child: child.clade,
        left: math.min(parentX, childX),
        top: child.top,
        width: (childX - parentX).abs(),
      ),
    );
  }
  return connectors;
}

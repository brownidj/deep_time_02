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
    'Extinction note: ${clade.extinctionNote ?? '-'}',
  ];
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

List<Clade> _orderedTreeClades(List<Clade> visible) {
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

  roots.sort(compareClades);
  for (final children in childrenByParentId.values) {
    children.sort(compareClades);
  }

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

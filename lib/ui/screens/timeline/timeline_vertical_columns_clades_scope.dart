part of 'timeline_vertical_columns.dart';

List<Clade> _filterRepresentativeClades(
  List<Clade> source,
  List<String> representativeIds,
) {
  if (representativeIds.isEmpty) {
    return source;
  }
  final byId = {for (final clade in source) clade.id: clade};
  final idSet = <String>{};
  void addWithAncestors(String id) {
    if (!idSet.add(id)) {
      return;
    }
    final parentId = byId[id]?.parentId;
    if (parentId != null) {
      addWithAncestors(parentId);
    }
  }

  for (final id in representativeIds) {
    addWithAncestors(id);
  }
  return source.where((clade) => idSet.contains(clade.id)).toList();
}

List<Clade> _collectDescendants({
  required String rootId,
  required Map<String, List<Clade>> childrenByParentId,
}) {
  final collected = <Clade>[];
  final visited = <String>{};

  void visit(String parentId) {
    final children = childrenByParentId[parentId] ?? const <Clade>[];
    for (final child in children) {
      if (!visited.add(child.id)) {
        continue;
      }
      collected.add(child);
      visit(child.id);
    }
  }

  visit(rootId);
  return collected;
}

List<Clade> _scopeCladesForActiveRoot({
  required List<Clade> source,
  required String? activeRootId,
  required Map<String, List<Clade>> childrenByParentId,
  int targetVisibleCount = 40,
}) {
  final rootId = activeRootId?.trim();
  if (rootId == null || rootId.isEmpty) {
    return source;
  }
  final byId = {for (final clade in source) clade.id: clade};
  final root = byId[rootId];
  if (root == null) {
    _debugCladeZoom(
      'activeRoot=$rootId not found in source (${source.length})',
    );
    return source;
  }
  int compareClades(Clade a, Clade b) {
    final priorityCompare = a.displayPriority.compareTo(b.displayPriority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    final durationCompare = b.durationMa.compareTo(a.durationMa);
    if (durationCompare != 0) {
      return durationCompare;
    }
    return a.label.compareTo(b.label);
  }

  final scopedIds = <String>{root.id};
  var frontier = List<Clade>.from(
    childrenByParentId[root.id] ?? const <Clade>[],
  )..sort(compareClades);
  _debugCladeZoom(
    'scope root=$rootId source=${source.length} directChildren=${frontier.length}',
  );
  var depth = 0;
  while (frontier.isNotEmpty && scopedIds.length < targetVisibleCount) {
    final nextFrontier = <Clade>[];
    var addedAtDepth = 0;
    for (final clade in frontier) {
      if (scopedIds.length >= targetVisibleCount) {
        break;
      }
      if (scopedIds.add(clade.id)) {
        addedAtDepth += 1;
        nextFrontier.addAll(childrenByParentId[clade.id] ?? const <Clade>[]);
      }
    }
    _debugCladeZoom(
      'scope root=$rootId depth=$depth frontier=${frontier.length} '
      'added=$addedAtDepth next=${nextFrontier.length} total=${scopedIds.length}',
    );
    nextFrontier.sort(compareClades);
    frontier = nextFrontier;
    depth += 1;
  }

  if (scopedIds.length < targetVisibleCount) {
    final descendants = _collectDescendants(
      rootId: rootId,
      childrenByParentId: childrenByParentId,
    );
    scopedIds.addAll(descendants.map((clade) => clade.id));
  }

  _debugCladeZoom(
    'activeRoot=$rootId target=$targetVisibleCount scoped=${scopedIds.length} '
    'sample=${scopedIds.take(10).join(",")}',
  );
  return source.where((clade) => scopedIds.contains(clade.id)).toList();
}

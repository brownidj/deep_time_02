part of 'timeline_screen.dart';

extension _TimelineScreenCladeDetail on _TimelineScreenState {
  Map<String, List<Clade>> _buildChildrenByParentId(List<Clade> source) {
    final index = <String, List<Clade>>{};
    final byId = {for (final clade in source) clade.id: clade};
    var rootLikeCount = 0;
    var orphanCount = 0;
    for (final clade in source) {
      final parentId = clade.parentId;
      if (parentId == null || parentId.isEmpty) {
        rootLikeCount += 1;
        continue;
      }
      if (!byId.containsKey(parentId)) {
        orphanCount += 1;
      }
      (index[parentId] ??= <Clade>[]).add(clade);
    }
    final densestParents = index.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final densestSummary = densestParents
        .take(10)
        .map((entry) => '${entry.key}:${entry.value.length}')
        .join(',');
    debugPrint(
      '[CLADE_DEBUG] childrenIndex total=${source.length} roots=$rootLikeCount '
      'orphans=$orphanCount parents=${index.length} densest=$densestSummary',
    );
    return index;
  }

  List<Clade> _resolveDisplayedClades({
    required List<Clade> yamlClades,
    required String? activeRootId,
  }) {
    final rootId = activeRootId?.trim();
    if (rootId == null || rootId.isEmpty) {
      return yamlClades;
    }
    final sqliteClades = _sqliteDetailCladeCache[rootId];
    if (sqliteClades == null || sqliteClades.isEmpty) {
      debugPrint(
        '[CLADE_DEBUG] resolve root=$rootId cache=missOrEmpty '
        'yamlSubtree=${_subtreeCount(yamlClades, rootId)} using=yaml',
      );
      return yamlClades;
    }

    final yamlCount = _subtreeCount(yamlClades, rootId);
    final sqliteCount = _subtreeCount(sqliteClades, rootId);
    if (sqliteCount <= yamlCount) {
      debugPrint(
        '[CLADE_DEBUG] resolve root=$rootId cache=hit sqliteLen=${sqliteClades.length} '
        'yamlSubtree=$yamlCount sqliteSubtree=$sqliteCount using=yaml',
      );
      return yamlClades;
    }

    final mergedById = <String, Clade>{
      for (final clade in yamlClades) clade.id: clade,
    };
    for (final clade in sqliteClades) {
      mergedById[clade.id] = clade;
    }
    debugPrint(
      '[CLADE_DEBUG] resolve root=$rootId cache=hit sqliteLen=${sqliteClades.length} '
      'yamlSubtree=$yamlCount sqliteSubtree=$sqliteCount using=merged '
      'mergedTotal=${mergedById.length}',
    );
    return mergedById.values.toList(growable: false);
  }

  int _subtreeCount(List<Clade> clades, String rootId) {
    final byId = {for (final clade in clades) clade.id: clade};
    if (!byId.containsKey(rootId)) {
      return 0;
    }
    final childrenByParent = _buildChildrenByParentId(clades);
    final visited = <String>{};
    final stack = <String>[rootId];
    while (stack.isNotEmpty) {
      final id = stack.removeLast();
      if (!visited.add(id)) {
        continue;
      }
      for (final child in childrenByParent[id] ?? const <Clade>[]) {
        stack.add(child.id);
      }
    }
    return visited.length;
  }

  Future<void> _handleCladeRootChanged(
    String? rootId,
    List<Clade> yamlClades,
  ) async {
    final normalizedRootId = rootId?.trim();
    final nextRootId = (normalizedRootId == null || normalizedRootId.isEmpty)
        ? null
        : normalizedRootId;
    debugPrint('[CLADE_DEBUG] rootChange requested=${nextRootId ?? 'null'}');
    _updateScreenState(() {
      _activeCladeRootId = nextRootId;
      _pendingFocusedRootAutoScrollId = nextRootId;
    });
    if (!_isFocusedCladeMode) {
      debugPrint('[CLADE_DEBUG] rootChange cleared');
      return;
    }
    final activeRootId = _focusedCladeRootId!;
    if (_sqliteDetailCladeCache.containsKey(activeRootId)) {
      final cachedLen = _sqliteDetailCladeCache[activeRootId]?.length ?? 0;
      debugPrint(
        '[CLADE_DEBUG] rootChange root=$activeRootId cacheHit len=$cachedLen',
      );
      return;
    }
    Clade? root;
    for (final clade in yamlClades) {
      if (clade.id == activeRootId) {
        root = clade;
        break;
      }
    }
    if (root == null || root.detailSource != 'sqlite') {
      debugPrint(
        '[CLADE_DEBUG] rootChange root=$activeRootId fetchSkipped '
        'rootFound=${root != null} detailSource=${root?.detailSource ?? 'n/a'}',
      );
      return;
    }
    try {
      await _loadSqliteDetailSubtree(rootId: activeRootId);
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to load SQLite detail clades for root $activeRootId; using YAML fallback',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _ensureActiveRootDetailLoaded(List<Clade> yamlClades) {
    final rootId = _focusedCladeRootId;
    if (rootId == null) {
      return;
    }
    if (_sqliteDetailCladeCache.containsKey(rootId) ||
        _sqliteDetailLoadInFlight.contains(rootId)) {
      return;
    }
    Clade? root;
    for (final clade in yamlClades) {
      if (clade.id == rootId) {
        root = clade;
        break;
      }
    }
    if (root == null || root.detailSource != 'sqlite') {
      debugPrint(
        '[CLADE_DEBUG] ensureActiveRoot root=$rootId skipped '
        'rootFound=${root != null} detailSource=${root?.detailSource ?? 'n/a'}',
      );
      return;
    }
    debugPrint('[CLADE_DEBUG] ensureActiveRoot root=$rootId schedulingFetch');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadSqliteDetailSubtree(rootId: rootId);
    });
  }

  Future<void> _loadSqliteDetailSubtree({required String rootId}) async {
    if (_sqliteDetailCladeCache.containsKey(rootId) ||
        _sqliteDetailLoadInFlight.contains(rootId)) {
      return;
    }
    _sqliteDetailLoadInFlight.add(rootId);
    try {
      debugPrint('[CLADE_DEBUG] sqliteLoad root=$rootId start');
      final detail = await widget.dependencies.cladeDetailRepository
          .fetchSubtreeForRoot(rootId);
      debugPrint(
        '[CLADE_DEBUG] sqliteLoad root=$rootId done len=${detail.length} mounted=$mounted',
      );
      if (!mounted || detail.isEmpty) {
        debugPrint(
          '[CLADE_DEBUG] sqliteLoad root=$rootId cacheSkipped '
          'mounted=$mounted empty=${detail.isEmpty}',
        );
        return;
      }
      _updateScreenState(() {
        _sqliteDetailCladeCache[rootId] = detail;
      });
      debugPrint(
        '[CLADE_DEBUG] sqliteLoad root=$rootId cacheStore len=${detail.length}',
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to load SQLite detail clades for root $rootId; using YAML fallback',
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('[CLADE_DEBUG] sqliteLoad root=$rootId error=$error');
    } finally {
      _sqliteDetailLoadInFlight.remove(rootId);
    }
  }
}

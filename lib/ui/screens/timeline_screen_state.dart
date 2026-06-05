part of 'timeline_screen.dart';

class _TimelineScreenState extends State<TimelineScreen>
    with _TimelineScreenPreferences, _TimelineScreenCladeData {
  late final Future<TimelineSnapshot> _snapshotFuture;
  final TimelineLayoutService _layoutService = TimelineLayoutService();
  final ScrollController _timelineScrollController = ScrollController();
  SelectedDivision? _selectedDivision;
  @override
  TimeLabelMode _labelMode = TimeLabelMode.geologicTime;
  @override
  CladeViewMode _cladeViewMode = CladeViewMode.representativeOnly;
  CladeLabelMode _cladeLabelMode = CladeLabelMode.common;
  @override
  String _cladeCategoryId = 'all';
  @override
  List<CladeDisplayGroup> _cladeDisplayGroups = const [];
  @override
  List<String> _cladeRepresentativeIds = const [];
  String _cladeSearchQuery = '';
  String? _cladeSpotlightId;
  String? _activeCladeRootId;
  final Map<String, List<Clade>> _sqliteDetailCladeCache = {};
  final Set<String> _sqliteDetailLoadInFlight = <String>{};
  @override
  Set<TimelineTrack> _visibleTracks = Set<TimelineTrack>.from(
    kDefaultTimelineTrackOrder,
  );
  @override
  bool _labelModeRetryScheduled = false;
  @override
  int _labelModeRetryCount = 0;
  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.dependencies.timelineService.loadSnapshot();
    _loadCladeDisplayGroups();
    _loadCladeRepresentativeIds();
    if (widget.enablePreferences) {
      _loadPreferences();
    }
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TimelineSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const TimelineLoadingView();
        }
        if (snapshot.hasError) {
          return TimelineErrorView(error: snapshot.error!);
        }
        if (!snapshot.hasData) {
          return const TimelineEmptyView();
        }

        final divisions = snapshot.data!.divisions;
        final palette = DeepTimePalette(snapshot.data!.palette);
        final markers = snapshot.data!.markers;
        final continents = snapshot.data!.continents;
        final waterways = snapshot.data!.waterways;
        final paleoEcology = snapshot.data!.paleoEcology;
        final clades = snapshot.data!.clades;
        _ensureActiveRootDetailLoaded(clades);
        final displayedClades = _resolveDisplayedClades(
          yamlClades: clades,
          activeRootId: _activeCladeRootId,
        );
        final childrenByParentId = _buildChildrenByParentId(displayedClades);
        final layout = _layoutService.build(
          divisions,
          markers,
          continents,
          waterways,
        );
        _primeSelection(
          layout.periodSegments,
          layout.epochSegments,
          layout.stageSegments,
        );
        final selected = _selectedDivision;
        final searchMatches = _cladeSearchQuery.trim().isEmpty
            ? const <Clade>[]
            : searchClades(displayedClades, _cladeSearchQuery);

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DeepTimePalette.appBackgroundAccent,
                  DeepTimePalette.appBackground,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TimelineHeader(
                    onSettings: () => _showLabelSettings(context),
                    scale: AppDebug.timelineScale,
                    minScale: AppDebug.minTimelineScale,
                    maxScale: AppDebug.maxTimelineScale,
                    onScaleChanged: (value) {
                      setState(() {
                        AppDebug.timelineScale = value;
                      });
                      _saveTimelineScale(value);
                    },
                  ),
                  if (_cladeViewMode == CladeViewMode.searchSpotlight)
                    CladeSearchPanel(
                      query: _cladeSearchQuery,
                      matches: searchMatches,
                      spotlightId: _cladeSpotlightId,
                      onQueryChanged: (value) {
                        setState(() {
                          _cladeSearchQuery = value;
                          if (_cladeSpotlightId != null &&
                              value.trim().isNotEmpty) {
                            final matches = searchClades(clades, value);
                            if (!matches.any(
                              (clade) => clade.id == _cladeSpotlightId,
                            )) {
                              _cladeSpotlightId = null;
                            }
                          }
                        });
                      },
                      onSelect: (clade) {
                        setState(() {
                          _cladeSearchQuery = clade.label;
                          _cladeSpotlightId = clade.id;
                        });
                      },
                    ),
                  if (selected != null)
                    TimelineSelectionPanel(selection: selected),
                  TimelineBody(
                    layout: layout,
                    palette: palette,
                    markers: markers,
                    labelMode: _labelMode,
                    scrollController: _timelineScrollController,
                    selectedId: selected?.id,
                    onBandSelect: (segment) {
                      setState(() {
                        _selectedDivision = SelectedDivision.fromBand(segment);
                      });
                    },
                    onSelect: (segment) {
                      setState(() {
                        _selectedDivision = SelectedDivision.fromRow(segment);
                      });
                    },
                    clades: displayedClades,
                    cladeViewMode: _cladeViewMode,
                    cladeCategoryId: _cladeCategoryId,
                    cladeLabelMode: _cladeLabelMode,
                    cladeRepresentativeIds: _cladeRepresentativeIds,
                    cladeSearchQuery: _cladeSearchQuery,
                    cladeSpotlightId: _cladeSpotlightId,
                    activeCladeRootId: _activeCladeRootId,
                    childrenByParentId: childrenByParentId,
                    onCladeSpotlight: (clade) {
                      if (_cladeViewMode != CladeViewMode.searchSpotlight) {
                        return;
                      }
                      setState(() {
                        _cladeSpotlightId = clade.id;
                        _cladeSearchQuery = clade.label;
                      });
                    },
                    onCladeRootChanged: (rootId) =>
                        _handleCladeRootChanged(rootId, clades),
                    visibleTracks: _visibleTracks,
                    paleoEcology: paleoEcology,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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

    // SQLite detail should enrich the active subtree. If it is smaller than
    // YAML, keep YAML to avoid collapsing active-root zoom to a tiny subset.
    if (sqliteCount <= yamlCount) {
      debugPrint(
        '[CLADE_DEBUG] resolve root=$rootId cache=hit sqliteLen=${sqliteClades.length} '
        'yamlSubtree=$yamlCount sqliteSubtree=$sqliteCount using=yaml',
      );
      return yamlClades;
    }

    final mergedById = <String, Clade>{for (final clade in yamlClades) clade.id: clade};
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
    debugPrint('[CLADE_DEBUG] rootChange requested=${rootId ?? 'null'}');
    setState(() {
      _activeCladeRootId = rootId;
    });
    if (rootId == null || rootId.isEmpty) {
      debugPrint('[CLADE_DEBUG] rootChange cleared');
      return;
    }
    if (_sqliteDetailCladeCache.containsKey(rootId)) {
      final cachedLen = _sqliteDetailCladeCache[rootId]?.length ?? 0;
      debugPrint('[CLADE_DEBUG] rootChange root=$rootId cacheHit len=$cachedLen');
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
        '[CLADE_DEBUG] rootChange root=$rootId fetchSkipped '
        'rootFound=${root != null} detailSource=${root?.detailSource ?? 'n/a'}',
      );
      return;
    }
    try {
      await _loadSqliteDetailSubtree(rootId: rootId);
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to load SQLite detail clades for root $rootId; using YAML fallback',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _ensureActiveRootDetailLoaded(List<Clade> yamlClades) {
    final rootId = _activeCladeRootId?.trim();
    if (rootId == null || rootId.isEmpty) {
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
      setState(() {
        _sqliteDetailCladeCache[rootId] = detail;
      });
      debugPrint('[CLADE_DEBUG] sqliteLoad root=$rootId cacheStore len=${detail.length}');
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

  void _primeSelection(
    List<TimelineRowSegment> periods,
    List<TimelineRowSegment> epochs,
    List<TimelineRowSegment> stages,
  ) {
    final firstSegment =
        periods.firstNonGap ?? epochs.firstNonGap ?? stages.firstNonGap;
    if (_selectedDivision != null || firstSegment == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedDivision = SelectedDivision.fromRow(firstSegment);
      });
    });
  }
}

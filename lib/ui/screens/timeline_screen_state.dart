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
  BiologyColumnMode _biologyColumnMode = BiologyColumnMode.cladistic;
  @override
  CladeViewMode _cladeViewMode = CladeViewMode.representativeOnly;
  @override
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
                    biologyColumnMode: _biologyColumnMode,
                    onScaleChanged: (value) {
                      setState(() {
                        AppDebug.timelineScale = value;
                      });
                      _saveTimelineScale(value);
                    },
                    onBiologyColumnModeChanged: (mode) {
                      setState(() {
                        _biologyColumnMode = mode;
                      });
                      _saveBiologyColumnMode(mode);
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
                    biologyColumnMode: _biologyColumnMode,
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

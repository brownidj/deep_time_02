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
  final List<String> _cladeFocusPath = <String>[];
  String? _activeCladeRootId;
  String? _pendingFocusedRootAutoScrollId;
  String? _activeTaxonomyTaxonId;
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

  String? get _focusedCladeRootId {
    final rootId = _cladeFocusPath.isEmpty
        ? _activeCladeRootId?.trim()
        : _cladeFocusPath.last.trim();
    if (rootId == null || rootId.isEmpty) {
      return null;
    }
    return rootId;
  }

  bool get _isFocusedCladeMode => _focusedCladeRootId != null;

  void _updateScreenState(VoidCallback update) {
    setState(update);
  }

  Set<TimelineTrack> get _effectiveVisibleTracks {
    final tracks = Set<TimelineTrack>.from(_visibleTracks);
    if (_biologyColumnMode == BiologyColumnMode.cladistic && _isFocusedCladeMode) {
      tracks.remove(TimelineTrack.rlife);
      tracks.remove(TimelineTrack.events);
    }
    return tracks;
  }

  String? _cladeLabelForId(List<Clade> clades, String? cladeId) {
    final targetId = cladeId?.trim();
    if (targetId == null || targetId.isEmpty) {
      return null;
    }
    for (final clade in clades) {
      if (clade.id == targetId) {
        return clade.label;
      }
    }
    return targetId;
  }

  void _updateCladeSearch({
    required String value,
    required List<Clade> displayedClades,
    required List<Clade> yamlClades,
  }) {
    final query = value.trim();
    final matches = query.isEmpty
        ? const <Clade>[]
        : searchClades(displayedClades, query);
    final firstZoomableMatch = matches.cast<Clade?>().firstWhere(
      (clade) => clade?.zoomable == true,
      orElse: () => null,
    );
    setState(() {
      _cladeSearchQuery = value;
      _cladeSpotlightId = null;
    });
    if (firstZoomableMatch == null) {
      return;
    }
    if (firstZoomableMatch.id == _focusedCladeRootId) {
      return;
    }
    _handleCladeRootChanged(firstZoomableMatch.id, yamlClades);
  }

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
}

part of 'timeline_screen.dart';

mixin _TimelineScreenPreferences on State<TimelineScreen> {
  TimeLabelMode get _labelMode;
  set _labelMode(TimeLabelMode value);
  BiologyColumnMode get _biologyColumnMode;
  set _biologyColumnMode(BiologyColumnMode value);
  CladeViewMode get _cladeViewMode;
  set _cladeViewMode(CladeViewMode value);
  CladeLabelMode get _cladeLabelMode;
  set _cladeLabelMode(CladeLabelMode value);
  String get _cladeCategoryId;
  set _cladeCategoryId(String value);
  Set<TimelineTrack> get _visibleTracks;
  set _visibleTracks(Set<TimelineTrack> value);
  List<CladeDisplayGroup> get _cladeDisplayGroups;
  bool get _labelModeRetryScheduled;
  set _labelModeRetryScheduled(bool value);
  int get _labelModeRetryCount;
  set _labelModeRetryCount(int value);
  Future<void> _loadPreferences() async {
    if (!widget.enablePreferences) {
      return;
    }
    if (_labelModeRetryCount >= _maxLabelModeRetries) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_labelModeKey);
      final storedScale = prefs.getDouble(_timelineScaleKey);
      final storedBiologyColumnMode = prefs.getString(_biologyColumnModeKey);
      final storedCladeView = prefs.getString(_cladeViewModeKey);
      final storedCladeCategory = prefs.getString(_cladeCategoryKey);
      final storedCladeLabelMode = prefs.getString(_cladeLabelModeKey);
      final storedContinentVisible = prefs.getBool(_continentColumnVisibleKey);
      final storedWaterwayVisible = prefs.getBool(_waterwayColumnVisibleKey);
      final storedPaleoEcologyVisible = prefs.getBool(
        _paleoEcologyColumnVisibleKey,
      );
      final storedRLifeVisible = prefs.getBool(_rlifeColumnVisibleKey);
      if (!mounted) {
        return;
      }
      setState(() {
        _labelMode = parseTimeLabelMode(stored);
        _biologyColumnMode = parseBiologyColumnMode(storedBiologyColumnMode);
        _cladeViewMode = parseCladeViewMode(storedCladeView);
        _cladeLabelMode = parseCladeLabelMode(storedCladeLabelMode);
        if (storedCladeCategory != null && storedCladeCategory.isNotEmpty) {
          _cladeCategoryId = storedCladeCategory;
        }
        if (storedScale != null) {
          AppDebug.timelineScale = storedScale.clamp(
            AppDebug.minTimelineScale,
            AppDebug.maxTimelineScale,
          );
        }
        if (storedContinentVisible != null) {
          final nextVisible = Set<TimelineTrack>.from(_visibleTracks);
          if (!storedContinentVisible) {
            nextVisible.remove(TimelineTrack.continents);
          }
          _visibleTracks = nextVisible;
        }
        if (storedWaterwayVisible != null) {
          final nextVisible = Set<TimelineTrack>.from(_visibleTracks);
          if (!storedWaterwayVisible) {
            nextVisible.remove(TimelineTrack.waterways);
          }
          _visibleTracks = nextVisible;
        }
        if (storedPaleoEcologyVisible != null) {
          final nextVisible = Set<TimelineTrack>.from(_visibleTracks);
          if (!storedPaleoEcologyVisible) {
            nextVisible.remove(TimelineTrack.paleoEcology);
          }
          _visibleTracks = nextVisible;
        }
        if (storedRLifeVisible != null) {
          final nextVisible = Set<TimelineTrack>.from(_visibleTracks);
          if (!storedRLifeVisible) {
            nextVisible.remove(TimelineTrack.rlife);
          }
          _visibleTracks = nextVisible;
        }
      });
    } on PlatformException catch (error, stackTrace) {
      _scheduleLabelModeRetry(error);
      AppDebug.log(
        'Failed to load preferences',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to load preferences',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _showLabelSettings(BuildContext context) async {
    final selected = await showDialog<TimeLabelMode>(
      context: context,
      builder: (context) {
        return TimelineSettingsDialog(
          labelMode: _labelMode,
          onScaleChanged: (value) {
            setState(() {
              AppDebug.timelineScale = value;
            });
            _saveTimelineScale(value);
          },
          cladeViewMode: _cladeViewMode,
          cladeCategoryId: _cladeCategoryId,
          cladeLabelMode: _cladeLabelMode,
          cladeDisplayGroups: _cladeDisplayGroups,
          onCladeViewModeChanged: (mode) {
            setState(() {
              _cladeViewMode = mode;
            });
            _saveCladeViewMode(mode);
          },
          onCladeCategoryChanged: (id) {
            setState(() {
              _cladeCategoryId = id;
            });
            _saveCladeCategory(id);
          },
          onCladeLabelModeChanged: (mode) {
            setState(() {
              _cladeLabelMode = mode;
            });
            _saveCladeLabelMode(mode);
          },
          visibleTracks: _visibleTracks,
          onTrackVisibilityChanged: (track, visible) {
            setState(() {
              final next = Set<TimelineTrack>.from(_visibleTracks);
              if (visible) {
                next.add(track);
              } else {
                next.remove(track);
              }
              _visibleTracks = next;
            });
            if (track == TimelineTrack.continents) {
              _saveContinentColumnVisible(visible);
            }
            if (track == TimelineTrack.waterways) {
              _saveWaterwayColumnVisible(visible);
            }
            if (track == TimelineTrack.paleoEcology) {
              _savePaleoEcologyColumnVisible(visible);
            }
            if (track == TimelineTrack.rlife) {
              _saveRLifeColumnVisible(visible);
            }
          },
        );
      },
    );

    if (selected == null || selected == _labelMode) {
      return;
    }

    setState(() {
      _labelMode = selected;
    });
    await _saveLabelMode(selected);
  }
}

mixin _TimelineScreenCladeData on State<TimelineScreen> {
  set _cladeDisplayGroups(List<CladeDisplayGroup> value);
  set _cladeRepresentativeIds(List<String> value);
  Future<void> _loadCladeDisplayGroups() async {
    try {
      final groups = await widget.dependencies.cladeDisplayGroupRepository
          .fetchDisplayGroups();
      if (!mounted) {
        return;
      }
      setState(() {
        _cladeDisplayGroups = groups;
      });
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to load clade display groups',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadCladeRepresentativeIds() async {
    try {
      final ids = await widget.dependencies.cladeRepresentativeRepository
          .fetchRepresentativeIds();
      if (!mounted) {
        return;
      }
      setState(() {
        _cladeRepresentativeIds = ids;
      });
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to load clade representative ids',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

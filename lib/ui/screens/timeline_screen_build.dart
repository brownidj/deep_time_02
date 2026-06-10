part of 'timeline_screen.dart';

extension _TimelineScreenBuild on _TimelineScreenState {
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
          activeRootId: _focusedCladeRootId,
        );
        final activeCladeRootLabel = _cladeLabelForId(
          displayedClades,
          _focusedCladeRootId,
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
                    cladeSearchQuery: _cladeSearchQuery,
                    onCladeSearchChanged: (value) => _updateCladeSearch(
                      value: value,
                      displayedClades: displayedClades,
                      yamlClades: clades,
                    ),
                    activeCladeRootLabel: _biologyColumnMode ==
                                BiologyColumnMode.cladistic &&
                            _isFocusedCladeMode
                        ? _cladeLabelForId(clades, _focusedCladeRootId)
                        : null,
                    onClearCladeRoot: _biologyColumnMode ==
                                BiologyColumnMode.cladistic &&
                            _isFocusedCladeMode
                        ? () => _handleCladeRootChanged(null, clades)
                        : null,
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
                    taxonomyRepository: widget.dependencies.taxonomyRepository,
                    biologyColumnMode: _biologyColumnMode,
                    cladeViewMode: _cladeViewMode,
                    cladeCategoryId: _cladeCategoryId,
                    cladeLabelMode: _cladeLabelMode,
                    cladeRepresentativeIds: _cladeRepresentativeIds,
                    cladeSearchQuery: _cladeSearchQuery,
                    cladeSpotlightId: _cladeSpotlightId,
                    activeCladeRootId: _focusedCladeRootId,
                    pendingFocusedRootAutoScrollId: _pendingFocusedRootAutoScrollId,
                    activeCladeRootLabel: activeCladeRootLabel,
                    childrenByParentId: childrenByParentId,
                    onCladeSpotlight: (clade) {
                      setState(() {
                        _cladeSpotlightId = clade.id;
                        _cladeSearchQuery = clade.label;
                      });
                    },
                    onCladeRootChanged: (rootId) =>
                        _handleCladeRootChanged(rootId, clades),
                    onFocusedRootAutoScrollHandled: (rootId) {
                      if (_pendingFocusedRootAutoScrollId != rootId) {
                        return;
                      }
                      setState(() {
                        _pendingFocusedRootAutoScrollId = null;
                      });
                    },
                    activeTaxonomyTaxonId: _activeTaxonomyTaxonId,
                    onTaxonomyTaxonSelected: (taxonId) {
                      setState(() {
                        _activeTaxonomyTaxonId = taxonId;
                      });
                    },
                    visibleTracks: _effectiveVisibleTracks,
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

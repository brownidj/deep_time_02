part of 'timeline_screen.dart';

extension _TimelineScreenPreferencesStorage on _TimelineScreenPreferences {
  Future<void> _saveLabelMode(TimeLabelMode mode) async {
    if (!widget.enablePreferences) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_labelModeKey, mode.id);
    } on PlatformException catch (error, stackTrace) {
      _scheduleLabelModeRetry(error);
      AppDebug.log(
        'Failed to save label mode',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to save label mode',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveTimelineScale(double scale) async {
    if (!widget.enablePreferences) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_timelineScaleKey, scale);
    } on PlatformException catch (error, stackTrace) {
      _scheduleLabelModeRetry(error);
      AppDebug.log(
        'Failed to save timeline scale',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to save timeline scale',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveCladeViewMode(CladeViewMode mode) async {
    if (!widget.enablePreferences) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cladeViewModeKey, mode.id);
    } on PlatformException catch (error, stackTrace) {
      _scheduleLabelModeRetry(error);
      AppDebug.log(
        'Failed to save clade view mode',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to save clade view mode',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveCladeCategory(String id) async {
    if (!widget.enablePreferences) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cladeCategoryKey, id);
    } on PlatformException catch (error, stackTrace) {
      _scheduleLabelModeRetry(error);
      AppDebug.log(
        'Failed to save clade category',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to save clade category',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveCladeLabelMode(CladeLabelMode mode) async {
    if (!widget.enablePreferences) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cladeLabelModeKey, mode.id);
    } on PlatformException catch (error, stackTrace) {
      _scheduleLabelModeRetry(error);
      AppDebug.log(
        'Failed to save clade label mode',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to save clade label mode',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveContinentColumnVisible(bool visible) async {
    if (!widget.enablePreferences) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_continentColumnVisibleKey, visible);
    } on PlatformException catch (error, stackTrace) {
      _scheduleLabelModeRetry(error);
      AppDebug.log(
        'Failed to save continent column visibility',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to save continent column visibility',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveWaterwayColumnVisible(bool visible) async {
    if (!widget.enablePreferences) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_waterwayColumnVisibleKey, visible);
    } on PlatformException catch (error, stackTrace) {
      _scheduleLabelModeRetry(error);
      AppDebug.log(
        'Failed to save waterway column visibility',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to save waterway column visibility',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _savePaleoEcologyColumnVisible(bool visible) async {
    if (!widget.enablePreferences) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_paleoEcologyColumnVisibleKey, visible);
    } on PlatformException catch (error, stackTrace) {
      _scheduleLabelModeRetry(error);
      AppDebug.log(
        'Failed to save paleo-ecology column visibility',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to save paleo-ecology column visibility',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveRLifeColumnVisible(bool visible) async {
    if (!widget.enablePreferences) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rlifeColumnVisibleKey, visible);
    } on PlatformException catch (error, stackTrace) {
      _scheduleLabelModeRetry(error);
      AppDebug.log(
        'Failed to save representative life column visibility',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to save representative life column visibility',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _scheduleLabelModeRetry(PlatformException error) {
    if (_labelModeRetryScheduled || !widget.enablePreferences) {
      return;
    }
    if (error.code != 'channel-error') {
      return;
    }
    if (_labelModeRetryCount >= _maxLabelModeRetries) {
      return;
    }
    _labelModeRetryCount += 1;
    _labelModeRetryScheduled = true;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || !widget.enablePreferences) {
        return;
      }
      _labelModeRetryScheduled = false;
      _loadPreferences();
    });
  }
}

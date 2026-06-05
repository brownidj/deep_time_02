import 'package:flutter/material.dart';
import 'package:deep_time_2/domain/models/clade_display_group.dart';
import 'package:deep_time_2/ui/models/clade_label_mode.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';

class TimelineSettingsDialog extends StatefulWidget {
  const TimelineSettingsDialog({
    super.key,
    required this.labelMode,
    required this.onScaleChanged,
    required this.cladeViewMode,
    required this.cladeLabelMode,
    required this.cladeCategoryId,
    required this.cladeDisplayGroups,
    required this.onCladeViewModeChanged,
    required this.onCladeCategoryChanged,
    required this.onCladeLabelModeChanged,
    required this.visibleTracks,
    required this.onTrackVisibilityChanged,
  });

  final TimeLabelMode labelMode;
  final ValueChanged<double> onScaleChanged;
  final CladeViewMode cladeViewMode;
  final CladeLabelMode cladeLabelMode;
  final String cladeCategoryId;
  final List<CladeDisplayGroup> cladeDisplayGroups;
  final ValueChanged<CladeViewMode> onCladeViewModeChanged;
  final ValueChanged<String> onCladeCategoryChanged;
  final ValueChanged<CladeLabelMode> onCladeLabelModeChanged;
  final Set<TimelineTrack> visibleTracks;
  final void Function(TimelineTrack track, bool visible)
  onTrackVisibilityChanged;

  @override
  State<TimelineSettingsDialog> createState() => _TimelineSettingsDialogState();
}

class _TimelineSettingsDialogState extends State<TimelineSettingsDialog> {
  late Set<TimelineTrack> _localVisibleTracks;
  late CladeLabelMode _localCladeLabelMode;

  @override
  void initState() {
    super.initState();
    _localVisibleTracks = Set<TimelineTrack>.from(widget.visibleTracks);
    _localCladeLabelMode = widget.cladeLabelMode;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Timescale settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<TimeLabelMode>(
              groupValue: widget.labelMode,
              onChanged: (value) {
                Navigator.of(context).pop(value);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: TimeLabelMode.values
                    .map(
                      (mode) => RadioListTile<TimeLabelMode>(
                        title: Text(mode.displayName),
                        value: mode,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Clade view',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 4),
            RadioGroup<CladeViewMode>(
              groupValue: widget.cladeViewMode,
              onChanged: (value) {
                if (value != null) {
                  widget.onCladeViewModeChanged(value);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: CladeViewMode.values
                    .map(
                      (mode) => RadioListTile<CladeViewMode>(
                        title: Text(mode.label),
                        value: mode,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Clade labels',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 4),
            RadioGroup<CladeLabelMode>(
              groupValue: _localCladeLabelMode,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _localCladeLabelMode = value;
                  });
                  widget.onCladeLabelModeChanged(value);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: CladeLabelMode.values
                    .map(
                      (mode) => RadioListTile<CladeLabelMode>(
                        title: Text(mode.label),
                        value: mode,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Category',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: widget.cladeCategoryId,
              items: [
                const DropdownMenuItem<String>(
                  value: 'all',
                  child: Text('All'),
                ),
                ...widget.cladeDisplayGroups.map(
                  (group) => DropdownMenuItem<String>(
                    value: group.id,
                    child: Text(group.label),
                  ),
                ),
              ],
              onChanged: widget.cladeViewMode == CladeViewMode.byCategory
                  ? (value) {
                      if (value != null) {
                        widget.onCladeCategoryChanged(value);
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Columns',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            _VisibilitySwitchTile(
              title: 'Land',
              value: _localVisibleTracks.contains(TimelineTrack.continents),
              onChanged: (value) {
                setState(() {
                  if (value) {
                    _localVisibleTracks.add(TimelineTrack.continents);
                  } else {
                    _localVisibleTracks.remove(TimelineTrack.continents);
                  }
                });
                widget.onTrackVisibilityChanged(
                  TimelineTrack.continents,
                  value,
                );
              },
            ),
            _VisibilitySwitchTile(
              title: 'Seas',
              value: _localVisibleTracks.contains(TimelineTrack.waterways),
              onChanged: (value) {
                setState(() {
                  if (value) {
                    _localVisibleTracks.add(TimelineTrack.waterways);
                  } else {
                    _localVisibleTracks.remove(TimelineTrack.waterways);
                  }
                });
                widget.onTrackVisibilityChanged(TimelineTrack.waterways, value);
              },
            ),
            _VisibilitySwitchTile(
              title: 'Paleo-ecology',
              value: _localVisibleTracks.contains(TimelineTrack.paleoEcology),
              onChanged: (value) {
                setState(() {
                  if (value) {
                    _localVisibleTracks.add(TimelineTrack.paleoEcology);
                  } else {
                    _localVisibleTracks.remove(TimelineTrack.paleoEcology);
                  }
                });
                widget.onTrackVisibilityChanged(
                  TimelineTrack.paleoEcology,
                  value,
                );
              },
            ),
            _VisibilitySwitchTile(
              title: 'Representative life',
              value: _localVisibleTracks.contains(TimelineTrack.rlife),
              onChanged: (value) {
                setState(() {
                  if (value) {
                    _localVisibleTracks.add(TimelineTrack.rlife);
                  } else {
                    _localVisibleTracks.remove(TimelineTrack.rlife);
                  }
                });
                widget.onTrackVisibilityChanged(TimelineTrack.rlife, value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _VisibilitySwitchTile extends StatelessWidget {
  const _VisibilitySwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

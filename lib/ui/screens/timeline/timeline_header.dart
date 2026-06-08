import 'package:flutter/material.dart';
import 'package:deep_time_2/ui/models/biology_column_mode.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';

class TimelineHeader extends StatefulWidget {
  const TimelineHeader({
    super.key,
    required this.onSettings,
    required this.scale,
    required this.onScaleChanged,
    required this.minScale,
    required this.maxScale,
    required this.biologyColumnMode,
    required this.onBiologyColumnModeChanged,
    required this.cladeSearchQuery,
    required this.onCladeSearchChanged,
    this.activeCladeRootLabel,
    this.onClearCladeRoot,
  });

  final VoidCallback onSettings;
  final double scale;
  final ValueChanged<double> onScaleChanged;
  final double minScale;
  final double maxScale;
  final BiologyColumnMode biologyColumnMode;
  final ValueChanged<BiologyColumnMode> onBiologyColumnModeChanged;
  final String cladeSearchQuery;
  final ValueChanged<String> onCladeSearchChanged;
  final String? activeCladeRootLabel;
  final VoidCallback? onClearCladeRoot;

  @override
  State<TimelineHeader> createState() => _TimelineHeaderState();
}

class _TimelineHeaderState extends State<TimelineHeader> {
  late final TextEditingController _searchController;

  String _scaleLabel() {
    final offset = widget.minScale - 1.0;
    final displayScale = (widget.scale - offset).clamp(
      1.0,
      widget.maxScale - offset,
    );
    return displayScale.toStringAsFixed(1);
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.cladeSearchQuery);
  }

  @override
  void didUpdateWidget(covariant TimelineHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cladeSearchQuery != widget.cladeSearchQuery &&
        _searchController.text != widget.cladeSearchQuery) {
      _searchController.text = widget.cladeSearchQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: widget.cladeSearchQuery.length,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logos/desktop_logo.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Deep Time 2',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: DeepTimePalette.panelText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (widget.biologyColumnMode == BiologyColumnMode.cladistic &&
              widget.activeCladeRootLabel != null) ...[
            IconButton(
              tooltip: 'Previous clade view',
              onPressed: widget.onClearCladeRoot,
              icon: const Icon(Icons.arrow_back),
              color: DeepTimePalette.panelText,
            ),
            const SizedBox(width: 8),
          ],
          SegmentedButton<BiologyColumnMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: BiologyColumnMode.cladistic,
                label: Text('Clades'),
              ),
              ButtonSegment(
                value: BiologyColumnMode.taxonomic,
                label: Text('Taxonomy'),
              ),
            ],
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.black;
                }
                return Colors.white;
              }),
            ),
            selected: {widget.biologyColumnMode},
            onSelectionChanged: (selection) {
              final nextMode = selection.first;
              if (nextMode != widget.biologyColumnMode) {
                widget.onBiologyColumnModeChanged(nextMode);
              }
            },
          ),
          const SizedBox(width: 30),
          if (widget.biologyColumnMode == BiologyColumnMode.cladistic)
            SizedBox(
              width: 240,
              child: TextField(
                controller: _searchController,
                onChanged: widget.onCladeSearchChanged,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DeepTimePalette.panelText,
                ),
                decoration: InputDecoration(
                  hintText: 'Search clades',
                  hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DeepTimePalette.panelText.withValues(alpha: 0.7),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: widget.cladeSearchQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => widget.onCladeSearchChanged(''),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                  filled: true,
                  fillColor: DeepTimePalette.frameBorder,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: DeepTimePalette.periodDivider,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: DeepTimePalette.periodDivider,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: DeepTimePalette.panelText,
                    ),
                  ),
                  isDense: true,
                ),
              ),
            ),
          if (widget.biologyColumnMode == BiologyColumnMode.cladistic)
            const SizedBox(width: 30),
          SizedBox(
            width: 220,
            child: Row(
              children: [
                Text(
                  'Scale:',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: DeepTimePalette.panelText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 0),
                Expanded(
                  child: Slider(
                    min: widget.minScale,
                    max: widget.maxScale,
                    divisions: 12,
                    padding: const EdgeInsets.only(left: 4),
                    value: widget.scale.clamp(widget.minScale, widget.maxScale),
                    label: _scaleLabel(),
                    onChanged: widget.onScaleChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 30),
          IconButton(
            tooltip: 'Settings',
            onPressed: widget.onSettings,
            icon: const Icon(Icons.settings),
            color: DeepTimePalette.panelText,
          ),
        ],
      ),
    );
  }
}

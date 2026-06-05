import 'package:flutter/material.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';
import 'package:deep_time_2/ui/widgets/time_range_format.dart';

class CladeSearchPanel extends StatefulWidget {
  const CladeSearchPanel({
    super.key,
    required this.query,
    required this.matches,
    required this.spotlightId,
    required this.onQueryChanged,
    required this.onSelect,
  });

  final String query;
  final List<Clade> matches;
  final String? spotlightId;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Clade> onSelect;

  @override
  State<CladeSearchPanel> createState() => _CladeSearchPanelState();
}

class _CladeSearchPanelState extends State<CladeSearchPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(CladeSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
      _controller.selection = TextSelection.collapsed(
        offset: widget.query.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(
      color: DeepTimePalette.panelText,
      fontWeight: FontWeight.w600,
    );
    final hintStyle = textTheme.bodySmall?.copyWith(
      color: DeepTimePalette.panelText.withValues(alpha: 0.7),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spotlight a clade', style: titleStyle),
          const SizedBox(height: 6),
          TextField(
            onChanged: widget.onQueryChanged,
            controller: _controller,
            style: textTheme.bodyMedium?.copyWith(
              color: DeepTimePalette.panelText,
            ),
            decoration: InputDecoration(
              hintText: 'Search: mammals, trilobites, flowering plants',
              hintStyle: hintStyle,
              filled: true,
              fillColor: DeepTimePalette.frameBorder,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: DeepTimePalette.periodDivider,
                ),
              ),
              isDense: true,
            ),
          ),
          if (widget.query.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _MatchList(
              matches: widget.matches,
              spotlightId: widget.spotlightId,
              onSelect: widget.onSelect,
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({
    required this.matches,
    required this.spotlightId,
    required this.onSelect,
  });

  final List<Clade> matches;
  final String? spotlightId;
  final ValueChanged<Clade> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final emptyStyle = textTheme.bodySmall?.copyWith(
      color: DeepTimePalette.panelText.withValues(alpha: 0.8),
    );
    if (matches.isEmpty) {
      return Text('No matches yet', style: emptyStyle);
    }
    final display = matches.take(6).toList();
    return Column(
      children: [
        for (final clade in display)
          _MatchRow(
            clade: clade,
            isSelected: spotlightId == clade.id,
            onSelect: onSelect,
          ),
      ],
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.clade,
    required this.isSelected,
    required this.onSelect,
  });

  final Clade clade;
  final bool isSelected;
  final ValueChanged<Clade> onSelect;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: DeepTimePalette.panelText,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
    );
    final durationLabel = formatTimeRange(
      startMa: clade.startMa,
      endMa: clade.endMa,
      startPrecision: 0,
      endPrecision: 0,
      durationPrecision: 0,
    );
    return InkWell(
      onTap: () => onSelect(clade),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(clade.label, style: style),
            ),
            Text(
              durationLabel,
              style: style,
            ),
          ],
        ),
      ),
    );
  }
}

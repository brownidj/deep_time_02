import 'package:flutter/material.dart';
import 'package:deep_time_2/domain/repositories/taxonomy_repository.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_taxonomy_column_content.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';

class TimelineTaxonomyColumn extends StatefulWidget {
  const TimelineTaxonomyColumn({
    super.key,
    required this.width,
    required this.height,
    required this.repository,
    required this.activeTaxonomyTaxonId,
    required this.onTaxonomyTaxonSelected,
  });

  final double width;
  final double height;
  final TaxonomyRepository repository;
  final String? activeTaxonomyTaxonId;
  final ValueChanged<String?> onTaxonomyTaxonSelected;

  @override
  State<TimelineTaxonomyColumn> createState() => _TimelineTaxonomyColumnState();
}

class _TimelineTaxonomyColumnState extends State<TimelineTaxonomyColumn> {
  late Future<TaxonomyColumnData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  @override
  void didUpdateWidget(covariant TimelineTaxonomyColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.activeTaxonomyTaxonId != widget.activeTaxonomyTaxonId) {
      _dataFuture = _load();
    }
  }

  Future<TaxonomyColumnData> _load() async {
    final targetId = widget.activeTaxonomyTaxonId?.trim().isNotEmpty == true
        ? widget.activeTaxonomyTaxonId!.trim()
        : 'life';
    final selected = await widget.repository.fetchTaxonById(targetId);
    if (selected == null) {
      return const TaxonomyColumnData.missing();
    }
    final lineage = await widget.repository.fetchLineage(selected.id);
    final children = await widget.repository.fetchChildren(selected.id);
    return TaxonomyColumnData(
      selected: selected,
      lineage: lineage,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('vertical-taxonomy-column'),
      width: widget.width,
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DeepTimePalette.timelineGapBackground,
          border: Border.all(color: DeepTimePalette.periodDivider, width: 1),
        ),
        child: FutureBuilder<TaxonomyColumnData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return TaxonomyMessage(
                message: 'Unable to load taxonomy data',
                detail: snapshot.error.toString(),
              );
            }
            final data = snapshot.data;
            if (data == null || data.selected == null) {
              return const TaxonomyMessage(
                message: 'No taxonomy data available',
              );
            }
            return TaxonomyColumnContent(
              data: data,
              onTaxonomyTaxonSelected: widget.onTaxonomyTaxonSelected,
            );
          },
        ),
      ),
    );
  }
}

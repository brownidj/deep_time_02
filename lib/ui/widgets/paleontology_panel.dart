import 'package:flutter/material.dart';
import 'package:deep_time_2/domain/models/fossil_range.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/paleontology_taxon.dart';

class PaleontologyPanel extends StatelessWidget {
  const PaleontologyPanel({
    super.key,
    required this.selectedDivision,
    required this.taxa,
    required this.ranges,
  });

  final GeologicDivision? selectedDivision;
  final List<PaleontologyTaxon> taxa;
  final List<FossilRange> ranges;

  @override
  Widget build(BuildContext context) {
    final selected = selectedDivision;
    if (selected == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final taxaById = {for (final taxon in taxa) taxon.id: taxon};
    final tiles = ranges
        .map(
          (range) => _RangeView(taxon: taxaById[range.taxonId], range: range),
        )
        .where((view) => view.taxon != null)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selected.name,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '${selected.rank.name.toUpperCase()} · '
            '${selected.startMa.toStringAsFixed(2)}–'
            '${selected.endMa.toStringAsFixed(2)} Ma',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Paleontology Highlights',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tiles.isEmpty
                ? _EmptyState(division: selected)
                : ListView.separated(
                    itemCount: tiles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final view = tiles[index];
                      return _PaleoCard(view: view);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RangeView {
  const _RangeView({required this.taxon, required this.range});

  final PaleontologyTaxon? taxon;
  final FossilRange range;
}

class _PaleoCard extends StatelessWidget {
  const _PaleoCard({required this.view});

  final _RangeView view;

  @override
  Widget build(BuildContext context) {
    final taxon = view.taxon!;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taxon.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(taxon.summary, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              'Range: ${view.range.startMa.toStringAsFixed(2)}–'
              '${view.range.endMa.toStringAsFixed(2)} Ma',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.division});

  final GeologicDivision division;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F1F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'No paleontology entries overlap the ${division.name} range yet.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

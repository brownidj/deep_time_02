import 'package:flutter/material.dart';
import 'package:deep_time_2/domain/models/taxonomy_taxon.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';

class TaxonomyColumnContent extends StatelessWidget {
  const TaxonomyColumnContent({
    super.key,
    required this.data,
    required this.onTaxonomyTaxonSelected,
  });

  final TaxonomyColumnData data;
  final ValueChanged<String?> onTaxonomyTaxonSelected;

  @override
  Widget build(BuildContext context) {
    final selected = data.selected!;
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            key: const ValueKey('taxonomy-breadcrumb'),
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final taxon in data.lineage)
                  ActionChip(
                    key: ValueKey('taxonomy-breadcrumb-${taxon.id}'),
                    label: Text(taxon.name),
                    onPressed: () => onTaxonomyTaxonSelected(taxon.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _rankLabel(selected.rank),
            style: textTheme.labelMedium?.copyWith(
              color: DeepTimePalette.panelText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selected.name,
            key: const ValueKey('taxonomy-selected-name'),
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if ((selected.commonName ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              selected.commonName!,
              style: textTheme.bodyMedium?.copyWith(
                color: DeepTimePalette.panelText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if ((selected.summary ?? '').trim().isNotEmpty)
            Text(
              selected.summary!,
              style: textTheme.bodyMedium?.copyWith(
                color: DeepTimePalette.panelText,
              ),
            ),
          if (_dateSummary(selected) case final summary?) ...[
            const SizedBox(height: 10),
            Text(
              summary,
              key: const ValueKey('taxonomy-selected-date'),
              style: textTheme.bodySmall?.copyWith(
                color: DeepTimePalette.panelText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Children',
            style: textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (data.children.isEmpty)
            Text(
              'No child taxa',
              style: textTheme.bodyMedium?.copyWith(
                color: DeepTimePalette.panelText,
              ),
            ),
          for (final child in data.children)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                key: ValueKey('taxonomy-child-${child.id}'),
                onTap: () => onTaxonomyTaxonSelected(child.id),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: DeepTimePalette.periodDivider.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                child.name,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _rankLabel(child.rank),
                                style: textTheme.bodySmall?.copyWith(
                                  color: DeepTimePalette.panelText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_datePill(child) case final pill?)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              pill,
                              style: textTheme.labelSmall?.copyWith(
                                color: DeepTimePalette.panelText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _rankLabel(String rank) {
    if (rank.trim().isEmpty) {
      return 'Taxon';
    }
    final normalized = rank.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String? _dateSummary(TaxonomyTaxon taxon) {
    if (taxon.displayDate.startMa != null) {
      return 'Display date: ${_formatMa(taxon.displayDate.startMa!)} Ma'
          ' (${taxon.displayDate.basis.id.replaceAll('_', ' ')})';
    }
    if (taxon.fossilDate.firstAppearanceMa != null) {
      return 'Fossil evidence: ${_formatMa(taxon.fossilDate.firstAppearanceMa!)} Ma';
    }
    if (taxon.molecularDate.originMa != null) {
      return 'Molecular estimate: ${_formatMa(taxon.molecularDate.originMa!)} Ma';
    }
    return null;
  }

  String? _datePill(TaxonomyTaxon taxon) {
    final value = taxon.displayDate.startMa ?? taxon.fossilDate.firstAppearanceMa;
    return value == null ? null : '${_formatMa(value)} Ma';
  }

  String _formatMa(double value) {
    if (value >= 100) {
      return value.toStringAsFixed(0);
    }
    if (value >= 10) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }
}

class TaxonomyMessage extends StatelessWidget {
  const TaxonomyMessage({super.key, required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DeepTimePalette.panelText,
                fontWeight: FontWeight.w600,
              ),
            ),
            if ((detail ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DeepTimePalette.panelText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TaxonomyColumnData {
  const TaxonomyColumnData({
    required this.selected,
    required this.lineage,
    required this.children,
  });

  const TaxonomyColumnData.missing()
    : selected = null,
      lineage = const [],
      children = const [];

  final TaxonomyTaxon? selected;
  final List<TaxonomyTaxon> lineage;
  final List<TaxonomyTaxon> children;
}

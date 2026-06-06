part of 'timeline_vertical_columns.dart';

class _VerticalTaxonomyPlaceholderColumn extends StatelessWidget {
  const _VerticalTaxonomyPlaceholderColumn({
    this.width = double.infinity,
    this.height = double.infinity,
    this.message = 'Taxonomy view coming next',
  });

  final double width;
  final double height;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('vertical-taxonomy-column'),
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DeepTimePalette.timelineGapBackground,
          border: Border.all(color: DeepTimePalette.periodDivider, width: 1),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DeepTimePalette.panelText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

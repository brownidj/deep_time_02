part of 'timeline_vertical_columns.dart';

bool _hasUsableCladeStartMa(Clade clade) {
  return clade.startMa.isFinite &&
      clade.endMa.isFinite &&
      clade.startMa >= 0 &&
      clade.endMa >= 0 &&
      clade.startMa >= clade.endMa;
}

List<Clade> _filterDateableClades(List<Clade> source) {
  final filtered = source.where(_hasUsableCladeStartMa).toList();
  _debugCladeZoom(
    'dateable source=${source.length} filtered=${filtered.length} '
    'excluded=${source.length - filtered.length}',
  );
  return filtered;
}

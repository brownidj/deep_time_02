part of 'timeline_vertical_columns.dart';

List<String>? _pathForDivision(
  int id,
  Map<int, GeologicDivision> divisionById,
) {
  final path = <String>[];
  var current = divisionById[id];
  while (current != null) {
    path.add(current.name);
    final parentId = current.parentId;
    current = parentId == null ? null : divisionById[parentId];
  }
  return path.isEmpty ? null : path.reversed.toList(growable: false);
}

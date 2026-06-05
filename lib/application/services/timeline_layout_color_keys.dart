import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/timeline_palette.dart';

String colorKeyForDivision(
  GeologicDivision division,
  Map<int, GeologicDivision> divisionById,
) {
  final parts = <GeologicDivision>[];
  GeologicDivision? current = division;
  while (current != null) {
    parts.add(current);
    final parentId = current.parentId;
    current = parentId == null ? null : divisionById[parentId];
  }
  var key = '';
  for (final part in parts.reversed) {
    key = divisionColorKey(
      name: part.name,
      rank: part.rank.name,
      parentKey: key.isEmpty ? null : key,
    );
  }
  return key;
}

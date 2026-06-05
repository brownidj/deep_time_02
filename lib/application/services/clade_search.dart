import 'package:deep_time_2/domain/models/clade.dart';

List<Clade> searchClades(List<Clade> clades, String query) {
  final normalized = _normalizeQuery(query);
  if (normalized.isEmpty) {
    return const [];
  }
  final tokens = normalized.split(' ');
  final matches = clades.where((clade) => cladeMatches(clade, tokens)).toList();
  matches.sort((a, b) {
    final priority = a.displayPriority.compareTo(b.displayPriority);
    if (priority != 0) {
      return priority;
    }
    return a.label.compareTo(b.label);
  });
  return matches;
}

bool cladeMatches(Clade clade, List<String> tokens) {
  if (tokens.isEmpty) {
    return false;
  }
  final buffer = StringBuffer()
    ..write(clade.id)
    ..write(' ')
    ..write(clade.label);
  final description = clade.shortDescription;
  if (description != null && description.isNotEmpty) {
    buffer.write(' ');
    buffer.write(description);
  }
  final tags = clade.tags;
  if (tags != null && tags.isNotEmpty) {
    buffer.write(' ');
    buffer.write(tags.join(' '));
  }
  final taxa = clade.representativeTaxa;
  if (taxa != null && taxa.isNotEmpty) {
    buffer.write(' ');
    buffer.write(taxa.join(' '));
  }
  final haystack = _normalizeQuery(buffer.toString());
  if (haystack.isEmpty) {
    return false;
  }
  return tokens.every(haystack.contains);
}

String _normalizeQuery(String query) {
  return query
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\\s]+'), ' ')
      .split(RegExp(r'\\s+'))
      .where((part) => part.isNotEmpty)
      .join(' ');
}

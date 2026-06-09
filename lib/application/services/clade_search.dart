import 'package:deep_time_2/domain/models/clade.dart';

List<Clade> searchClades(List<Clade> clades, String query) {
  final normalized = _normalizeQuery(query);
  if (normalized.isEmpty) {
    return const [];
  }
  final tokens = normalized.split(' ');
  final matches = clades.where((clade) => cladeMatches(clade, tokens)).toList();
  matches.sort((a, b) {
    final scoreCompare = _cladeSearchScore(a, normalized, tokens).compareTo(
      _cladeSearchScore(b, normalized, tokens),
    );
    if (scoreCompare != 0) {
      return scoreCompare;
    }
    final priorityCompare = a.displayPriority.compareTo(b.displayPriority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    return a.label.compareTo(b.label);
  });
  return matches;
}

int _cladeSearchScore(Clade clade, String normalizedQuery, List<String> tokens) {
  final id = _normalizeQuery(clade.id);
  final label = _normalizeQuery(clade.label);
  final scientific = _normalizeQuery(clade.scientificLabel ?? '');
  final openTree = _normalizeQuery(clade.openTreeName ?? '');

  if (label == normalizedQuery || id == normalizedQuery) {
    return 0;
  }
  if (label.startsWith(normalizedQuery) || id.startsWith(normalizedQuery)) {
    return 1;
  }
  if (label.contains(normalizedQuery) || id.contains(normalizedQuery)) {
    return 2;
  }
  if (scientific == normalizedQuery || openTree == normalizedQuery) {
    return 3;
  }
  if (scientific.startsWith(normalizedQuery) || openTree.startsWith(normalizedQuery)) {
    return 4;
  }
  if (scientific.contains(normalizedQuery) || openTree.contains(normalizedQuery)) {
    return 5;
  }
  final description = _normalizeQuery(clade.shortDescription ?? '');
  final tags = _normalizeQuery((clade.tags ?? const <String>[]).join(' '));
  final taxa = _normalizeQuery(
    (clade.representativeTaxa ?? const <String>[]).join(' '),
  );
  final combinedSupport = '$description $tags $taxa'.trim();
  if (combinedSupport.isEmpty) {
    return 6;
  }
  final supportStarts = tokens.every(
    (token) =>
        description.startsWith(token) ||
        tags.startsWith(token) ||
        taxa.startsWith(token),
  );
  if (supportStarts) {
    return 6;
  }
  return 7;
}

bool cladeMatches(Clade clade, List<String> tokens) {
  if (tokens.isEmpty) {
    return false;
  }
  final buffer = StringBuffer()
    ..write(clade.id)
    ..write(' ')
    ..write(clade.label);
  final scientific = clade.scientificLabel;
  if (scientific != null && scientific.isNotEmpty) {
    buffer.write(' ');
    buffer.write(scientific);
  }
  final openTree = clade.openTreeName;
  if (openTree != null && openTree.isNotEmpty) {
    buffer.write(' ');
    buffer.write(openTree);
  }
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

part of 'timeline_seed.dart';

int _countDivisionNodes(Object? value) {
  if (value is! YamlList) {
    return 0;
  }
  var count = 0;
  for (final entry in value) {
    if (entry is! YamlMap) {
      continue;
    }
    count += 1;
    count += _countDivisionNodes(entry['children']);
  }
  return count;
}

String _stableFNVHash(String value) {
  const int fnvOffset = 0x811c9dc5;
  const int fnvPrime = 0x01000193;
  var hash = fnvOffset;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * fnvPrime) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

class _DivisionNode {
  _DivisionNode({
    required this.name,
    required this.rank,
    required this.startMa,
    required this.uncertaintyMa,
    required this.children,
    required this.explanation,
  });

  factory _DivisionNode.fromYaml(YamlMap map) {
    final name = map['name'] as String? ?? 'Unnamed';
    final rank = map['rank'] as String? ?? 'unknown';
    final startMa = _parseDouble(map['start_ma'] ?? map['end_ma']);
    final uncertaintyMa = _parseOptionalDouble(map['uncertainty_ma']);
    final explanation = map['explanation'] as String?;
    final children = TimelineSeeder._readNodes(map['children']);

    return _DivisionNode(
      name: name,
      rank: rank,
      startMa: TimelineSeeder._normMa(startMa),
      uncertaintyMa: uncertaintyMa,
      explanation: explanation,
      children: children,
    );
  }

  final String name;
  final String rank;
  final double startMa;
  final double? uncertaintyMa;
  final List<_DivisionNode> children;
  final String? explanation;
  double endMa = 0.0;

  static double _parseDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw StateError('Invalid numeric value for start/end Ma: $value');
  }

  static double? _parseOptionalDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed == null ? null : TimelineSeeder._normMa(parsed);
    }
    return null;
  }
}

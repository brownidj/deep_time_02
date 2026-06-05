class TimelinePalette {
  const TimelinePalette({required this.divisionColors});

  final Map<String, int> divisionColors;
}

String divisionColorKey({
  required String name,
  required String rank,
  String? parentKey,
}) {
  final normalizedName = name.trim().toLowerCase();
  final normalizedRank = rank.trim().toLowerCase();
  final segment = '$normalizedRank|$normalizedName';
  if (parentKey == null || parentKey.isEmpty) {
    return segment;
  }
  return '$parentKey/$segment';
}

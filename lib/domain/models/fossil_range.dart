class FossilRange {
  const FossilRange({
    required this.id,
    required this.taxonId,
    required this.startMa,
    required this.endMa,
  });

  final int id;
  final int taxonId;
  final double startMa;
  final double endMa;

  bool overlaps(double rangeStartMa, double rangeEndMa) {
    return startMa >= rangeEndMa && endMa <= rangeStartMa;
  }
}

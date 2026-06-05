import 'package:deep_time_2/domain/models/geologic_rank.dart';

class GeologicDivision {
  const GeologicDivision({
    required this.id,
    required this.name,
    required this.rank,
    required this.startMa,
    required this.endMa,
    this.startMaUncertainty,
    this.parentId,
    this.explanation,
  });

  final int id;
  final String name;
  final GeologicRank rank;
  final double startMa;
  final double endMa;
  final double? startMaUncertainty;
  final int? parentId;
  final String? explanation;

  double get durationMa => startMa - endMa;
}

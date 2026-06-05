import 'package:deep_time_2/domain/models/clade.dart';

abstract class CladeRepository {
  Future<List<Clade>> fetchAll();
}

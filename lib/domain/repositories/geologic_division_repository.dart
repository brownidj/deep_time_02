import 'package:deep_time_2/domain/models/geologic_division.dart';

abstract class GeologicDivisionRepository {
  Future<int> insert(GeologicDivision division);
  Future<GeologicDivision?> fetchById(int id);
  Future<List<GeologicDivision>> fetchAll();
  Future<void> update(GeologicDivision division);
  Future<void> delete(int id);
}

import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';

abstract class PaleoEcologyRepository {
  Future<List<PaleoEcologyEntry>> fetchEntries();
}

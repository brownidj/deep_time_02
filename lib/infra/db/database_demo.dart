import 'package:deep_time_2/domain/models/fossil_range.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/paleontology_taxon.dart';
import 'package:deep_time_2/infra/db/app_database.dart';
import 'package:deep_time_2/infra/repositories/sqlite_geologic_division_repository.dart';
import 'package:deep_time_2/infra/repositories/sqlite_paleontology_repository.dart';

Future<void> runDatabaseDemo() async {
  final database = await AppDatabase.open();
  final divisionRepo = SqliteGeologicDivisionRepository(database);
  final paleoRepo = SqlitePaleontologyRepository(database);

  final newDivisionId = await divisionRepo.insert(
    const GeologicDivision(
      id: 0,
      name: 'Demo Period',
      rank: GeologicRank.period,
      startMa: 120.0,
      endMa: 100.0,
      parentId: null,
    ),
  );

  final division = await divisionRepo.fetchById(newDivisionId);
  if (division != null) {
    await divisionRepo.update(
      GeologicDivision(
        id: division.id,
        name: '${division.name} Updated',
        rank: division.rank,
        startMa: division.startMa,
        endMa: division.endMa,
        parentId: division.parentId,
      ),
    );
  }

  final taxonId = await paleoRepo.insertTaxon(
    const PaleontologyTaxon(
      id: 0,
      name: 'Demo Taxon',
      summary: 'Example taxon inserted through the demo flow.',
    ),
  );

  final rangeId = await paleoRepo.insertRange(
    FossilRange(id: 0, taxonId: taxonId, startMa: 110.0, endMa: 95.0),
  );

  await paleoRepo.updateRange(
    FossilRange(id: rangeId, taxonId: taxonId, startMa: 112.0, endMa: 95.0),
  );

  await paleoRepo.deleteRange(rangeId);
  await paleoRepo.deleteTaxon(taxonId);
  await divisionRepo.delete(newDivisionId);

  database.close();
}

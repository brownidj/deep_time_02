import 'package:deep_time_2/domain/models/fossil_range.dart';
import 'package:deep_time_2/domain/models/paleontology_taxon.dart';

abstract class PaleontologyRepository {
  Future<int> insertTaxon(PaleontologyTaxon taxon);
  Future<PaleontologyTaxon?> fetchTaxonById(int id);
  Future<List<PaleontologyTaxon>> fetchAllTaxa();
  Future<void> updateTaxon(PaleontologyTaxon taxon);
  Future<void> deleteTaxon(int id);

  Future<int> insertRange(FossilRange range);
  Future<List<FossilRange>> fetchRangesForTaxon(int taxonId);
  Future<List<FossilRange>> fetchRangesOverlapping(
    double startMa,
    double endMa,
  );
  Future<void> updateRange(FossilRange range);
  Future<void> deleteRange(int id);
}

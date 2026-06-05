import 'package:deep_time_2/domain/models/taxonomy_taxon.dart';

abstract class TaxonomyRepository {
  Future<TaxonomyTaxon?> fetchTaxonById(String id);
  Future<TaxonomyTaxon?> fetchTaxonByOttId(int ottId);
  Future<List<TaxonomyTaxon>> fetchRootTaxa();
  Future<List<TaxonomyTaxon>> fetchChildren(String parentTaxonId);
  Future<List<TaxonomyTaxon>> fetchLineage(String taxonId);
  Future<List<TaxonomyTaxon>> searchByName(String query, {int limit = 20});

  Future<void> upsertTaxon(TaxonomyTaxon taxon);
  Future<void> upsertTaxa(List<TaxonomyTaxon> taxa);
  Future<void> deleteTaxon(String id);
}

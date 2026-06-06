import 'package:deep_time_2/app/app_debug.dart';
import 'package:deep_time_2/application/services/timeline_service.dart';
import 'package:deep_time_2/infra/db/app_database.dart';
import 'package:deep_time_2/infra/db/taxonomy_database.dart';
import 'package:deep_time_2/domain/repositories/clade_display_group_repository.dart';
import 'package:deep_time_2/domain/repositories/clade_repository.dart';
import 'package:deep_time_2/domain/repositories/clade_representative_repository.dart';
import 'package:deep_time_2/domain/repositories/taxonomy_repository.dart';
import 'package:deep_time_2/infra/repositories/sqlite_geologic_division_repository.dart';
import 'package:deep_time_2/infra/repositories/sqlite_paleontology_repository.dart';
import 'package:deep_time_2/infra/repositories/sqlite_clade_detail_repository.dart';
import 'package:deep_time_2/infra/repositories/sqlite_taxonomy_repository.dart';
import 'package:deep_time_2/infra/repositories/yaml_clade_repository.dart';
import 'package:deep_time_2/infra/repositories/yaml_continent_repository.dart';
import 'package:deep_time_2/infra/repositories/yaml_paleo_ecology_repository.dart';
import 'package:deep_time_2/infra/repositories/yaml_clade_display_group_repository.dart';
import 'package:deep_time_2/infra/repositories/yaml_clade_representative_repository.dart';
import 'package:deep_time_2/infra/repositories/yaml_timeline_marker_repository.dart';
import 'package:deep_time_2/infra/repositories/yaml_timeline_palette_repository.dart';
import 'package:deep_time_2/infra/repositories/yaml_waterway_repository.dart';

class AppDependencies {
  AppDependencies({
    required this.database,
    required this.taxonomyDatabase,
    required this.timelineService,
    required this.cladeDisplayGroupRepository,
    required this.cladeRepresentativeRepository,
    required this.cladeRepository,
    required this.cladeDetailRepository,
    required this.taxonomyRepository,
  });

  final AppDatabase database;
  final TaxonomyDatabase taxonomyDatabase;
  final TimelineService timelineService;
  final CladeDisplayGroupRepository cladeDisplayGroupRepository;
  final CladeRepresentativeRepository cladeRepresentativeRepository;
  final CladeRepository cladeRepository;
  final SqliteCladeDetailRepository cladeDetailRepository;
  final TaxonomyRepository taxonomyRepository;

  static Future<AppDependencies> build() async {
    try {
      final database = await AppDatabase.open();
      final taxonomyDatabase = await TaxonomyDatabase.open();
      final divisionRepository = SqliteGeologicDivisionRepository(database);
      final paleontologyRepository = SqlitePaleontologyRepository(database);
      final taxonomyRepository = SqliteTaxonomyRepository(taxonomyDatabase);
      final paletteRepository = YamlTimelinePaletteRepository(
        assetPath: 'data/time_divisions.yaml',
      );
      final markerRepository = YamlTimelineMarkerRepository(
        assetPath: 'data/timeline_markers.yaml',
      );
      final cladeDisplayGroupRepository = YamlCladeDisplayGroupRepository(
        assetPath: 'data/clade_display_groups.yaml',
      );
      final cladeRepresentativeRepository = YamlCladeRepresentativeRepository(
        assetPath: 'data/clade_representative_ids.yaml',
      );
      final cladeRepository = YamlCladeRepository(
        assetPath: 'data/clades.yaml',
      );
      final cladeDetailRepository = SqliteCladeDetailRepository(
        assetPath: 'data/clades_detail_progressive_opentree.sqlite',
      );
      final continentRepository = YamlContinentRepository(
        assetPath: 'data/continents.yaml',
      );
      final waterwayRepository = YamlWaterwayRepository(
        assetPath: 'data/waterways.yaml',
      );
      final timelineService = TimelineService(
        divisionRepository: divisionRepository,
        paleontologyRepository: paleontologyRepository,
        paletteRepository: paletteRepository,
        markerRepository: markerRepository,
        cladeRepository: cladeRepository,
        continentRepository: continentRepository,
        waterwayRepository: waterwayRepository,
        paleoEcologyRepository: YamlPaleoEcologyRepository(
          assetPath: 'data/paleo_ecology.yaml',
        ),
      );
      return AppDependencies(
        database: database,
        taxonomyDatabase: taxonomyDatabase,
        timelineService: timelineService,
        cladeDisplayGroupRepository: cladeDisplayGroupRepository,
        cladeRepresentativeRepository: cladeRepresentativeRepository,
        cladeRepository: cladeRepository,
        cladeDetailRepository: cladeDetailRepository,
        taxonomyRepository: taxonomyRepository,
      );
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to build AppDependencies',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> close() async {
    database.close();
    taxonomyDatabase.close();
  }
}

import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';

abstract class TimelineMarkerRepository {
  Future<TimelineMarkerCatalog> fetchMarkers();
}

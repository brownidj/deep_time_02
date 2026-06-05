import 'package:deep_time_2/application/services/timeline_layout_builder.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';

export 'package:deep_time_2/application/services/timeline_layout_models.dart';

class TimelineLayoutService {
  TimelineLayoutSnapshot build(
    List<GeologicDivision> divisions,
    TimelineMarkerCatalog markers,
    List<TimelineEventDefinition> continents,
    List<TimelineEventDefinition> waterways,
  ) {
    final builder = TimelineLayoutBuilder();
    return builder.build(divisions, markers, continents, waterways);
  }
}

import 'package:deep_time_2/domain/models/timeline_palette.dart';

abstract class TimelinePaletteRepository {
  Future<TimelinePalette> fetchPalette();
}

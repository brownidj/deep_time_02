import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:deep_time_2/app/app_debug.dart';
import 'package:deep_time_2/application/services/clade_visibility_resolver.dart';
import 'package:deep_time_2/application/services/clade_search.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/clade_zoom_level.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/ui/models/biology_column_mode.dart';
import 'package:deep_time_2/ui/models/clade_label_mode.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body_metrics.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_min_height_helpers.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_track_widths.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';
import 'package:deep_time_2/ui/widgets/time_range_format.dart';
import 'package:deep_time_2/ui/widgets/timeline_explanation_dialog.dart';

part 'timeline_vertical_columns_segments.dart';
part 'timeline_vertical_columns_widget.dart';
part 'timeline_vertical_segment_tile.dart';
part 'timeline_vertical_columns_segment_heights.dart';
part 'timeline_vertical_columns_ma.dart';
part 'timeline_vertical_columns_events.dart';
part 'timeline_vertical_columns_extinctions.dart';
part 'timeline_vertical_columns_painters.dart';
part 'timeline_vertical_columns_clades.dart';
part 'timeline_vertical_columns_clades_viewport.dart';
part 'timeline_vertical_columns_continent_gradients.dart';
part 'timeline_vertical_columns_paleo_ecology.dart';
part 'timeline_vertical_columns_paleo_ecology_tooltip.dart';
part 'timeline_vertical_columns_clades_helpers.dart';
part 'timeline_vertical_columns_clades_dateability.dart';
part 'timeline_vertical_columns_clades_labels.dart';
part 'timeline_vertical_columns_clades_scope.dart';
part 'timeline_vertical_columns_clades_visibility.dart';
part 'timeline_vertical_columns_clades_mapper.dart';
part 'timeline_vertical_columns_clades_widgets.dart';
part 'timeline_vertical_columns_clades_scrollbar.dart';
part 'timeline_vertical_columns_clades_layout_helpers.dart';
part 'timeline_vertical_columns_clades_misc.dart';
part 'timeline_vertical_columns_taxonomy_placeholder.dart';
part 'timeline_vertical_columns_biology_track.dart';
part 'timeline_vertical_columns_events_track.dart';
part 'timeline_vertical_columns_paleo_ecology_helpers.dart';
part 'timeline_vertical_columns_tracks.dart';
part 'timeline_vertical_columns_events_widgets.dart';

Color _darken(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness * amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}

Color _safeColorForKey(String key, DeepTimePalette palette) {
  final fallback = const Color(0xFFFFD978);
  if (key.trim().isEmpty) {
    return fallback;
  }
  try {
    return palette.colorForKey(key);
  } catch (_) {
    return fallback;
  }
}

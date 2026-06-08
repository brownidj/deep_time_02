import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:deep_time_2/app/app_debug.dart';
import 'package:deep_time_2/app/app_dependencies.dart';
import 'package:deep_time_2/application/services/clade_search.dart';
import 'package:deep_time_2/application/services/timeline_layout_service.dart';
import 'package:deep_time_2/application/services/timeline_service.dart';
import 'package:deep_time_2/domain/models/clade_display_group.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/ui/models/biology_column_mode.dart';
import 'package:deep_time_2/ui/models/clade_label_mode.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_header.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_selection_panel.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_selection.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_settings_dialog.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_state_views.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'timeline_screen_state.dart';
part 'timeline_screen_prefs.dart';
part 'timeline_screen_prefs_storage.dart';
part 'timeline_screen_clade_detail.dart';

const String _labelModeKey = 'time_label_mode';
const String _timelineScaleKey = 'timeline_scale';
const String _biologyColumnModeKey = 'biology_column_mode';
const String _cladeViewModeKey = 'clade_view_mode';
const String _cladeCategoryKey = 'clade_category_id';
const String _cladeLabelModeKey = 'clade_label_mode';
const String _continentColumnVisibleKey = 'continent_column_visible';
const String _waterwayColumnVisibleKey = 'waterway_column_visible';
const String _paleoEcologyColumnVisibleKey = 'paleo_ecology_column_visible';
const String _rlifeColumnVisibleKey = 'rlife_column_visible';
const int _maxLabelModeRetries = 2;

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({
    super.key,
    required this.dependencies,
    required this.enablePreferences,
  });

  final AppDependencies dependencies;
  final bool enablePreferences;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

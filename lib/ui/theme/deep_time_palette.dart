import 'package:flutter/material.dart';
import 'package:deep_time_2/domain/models/timeline_palette.dart';

class DeepTimePalette {
  DeepTimePalette(this._palette);

  final TimelinePalette _palette;

  static const Color appBackground = Color(0xFF060707);
  static const Color appBackgroundAccent = Color(0xFF111414);
  static const Color frameBorder = Color(0xFF2A2E2E);
  static const Color panelBackground = Color(0xFF8F9292);
  static const Color panelText = Color(0xFFE2E7E7);
  static const Color darkLabel = Color(0xFF1B2325);
  static const Color periodDivider = Color(0xFF3C3F41);
  static const Color selectedOutline = Color(0xFFFFD978);
  static const Color timelineGapBackground = Color(0xFF3E4141);

  Color colorForKey(String key) {
    final value = _palette.divisionColors[key];
    if (value == null) {
      throw StateError('Missing color for "$key"');
    }
    return Color(value);
  }
}

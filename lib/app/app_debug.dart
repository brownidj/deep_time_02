import 'package:flutter/foundation.dart';

class AppDebug {
  const AppDebug._();

  static const bool _appDebug = false;
  static bool _overrideEnabled = false;
  static const double minTimelineScale = 1.3;
  static const double maxTimelineScale = 4.0;
  static double timelineScale = 3.4;
  static const bool showTimelineConnectorAnchors = false;
  static const bool logTimelineConnectorGeometry = false;
  static const bool showTimelineConnectorExtents = true;

  static bool get enabled => (_appDebug || _overrideEnabled) && kDebugMode;

  static void configure({required bool enabled}) {
    _overrideEnabled = enabled;
  }

  static void log(Object message, {Object? error, StackTrace? stackTrace}) {
    if (!enabled && !logTimelineConnectorGeometry) {
      return;
    }
    debugPrint('[APP_DEBUG] $message');
    if (error != null) {
      debugPrint('[APP_DEBUG][error] $error');
    }
    if (stackTrace != null) {
      debugPrint('[APP_DEBUG][stack] $stackTrace');
    }
  }
}

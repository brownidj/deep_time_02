import 'dart:io';

import 'package:flutter/material.dart';
import 'package:deep_time_2/app/app_debug.dart';
import 'package:deep_time_2/app/time_app.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const bool enableAppDebug = true;
  const bool enablePreferences = true;
  AppDebug.configure(enabled: enableAppDebug);
  await _prepareInitialWindow();
  runApp(TimeApp(enablePreferences: enablePreferences));
}

Future<void> _prepareInitialWindow() async {
  if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
    return;
  }
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    titleBarStyle: TitleBarStyle.normal,
    center: true,
    size: Size(400, 400),
    minimumSize: Size(400, 400),
    maximumSize: Size(400, 400),
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

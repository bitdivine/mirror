import 'package:flutter/material.dart';

import 'camera/camera_service.dart';
import 'diagnostics.dart';
import 'settings/settings_store.dart';
import 'ui/mirror_screen.dart';

class MirrorApp extends StatelessWidget {
  MirrorApp({
    required this.cameraService,
    required this.diagnostics,
    SettingsStore? settingsStore,
    super.key,
  }) : settingsStore = settingsStore ?? FileSettingsStore();

  final CameraService cameraService;
  final Diagnostics diagnostics;
  final SettingsStore settingsStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mirror',
      home: MirrorScreen(
        cameraService: cameraService,
        diagnostics: diagnostics,
        settingsStore: settingsStore,
      ),
    );
  }
}

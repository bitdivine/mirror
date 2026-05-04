import 'package:flutter/material.dart';

import 'ai/appearance_analysis.dart';
import 'ai/openai_appearance_analysis_service.dart';
import 'camera/camera_service.dart';
import 'diagnostics.dart';
import 'settings/settings_store.dart';
import 'ui/mirror_screen.dart';

class MirrorApp extends StatelessWidget {
  MirrorApp({
    required this.cameraService,
    required this.diagnostics,
    AppearanceAnalysisService? appearanceAnalysisService,
    SettingsStore? settingsStore,
    super.key,
  })  : appearanceAnalysisService =
            appearanceAnalysisService ?? OpenAiAppearanceAnalysisService(),
        settingsStore = settingsStore ?? FileSettingsStore();

  final CameraService cameraService;
  final Diagnostics diagnostics;
  final AppearanceAnalysisService appearanceAnalysisService;
  final SettingsStore settingsStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mirror',
      home: MirrorScreen(
        cameraService: cameraService,
        diagnostics: diagnostics,
        appearanceAnalysisService: appearanceAnalysisService,
        settingsStore: settingsStore,
      ),
    );
  }
}

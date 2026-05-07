import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'camera/camera_service.dart';
import 'diagnostics.dart';
import 'platform/fullscreen_service.dart';
import 'settings/settings_store.dart';
import 'version.dart' as version;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const diagnostics = Diagnostics(appVersion: version.appVersion);
  final fullscreenService = FullscreenService.forCurrentPlatform(
    diagnostics: diagnostics,
  );
  runZonedGuarded(
    () async {
      await runMirror(
        fullscreenService: fullscreenService,
        diagnostics: diagnostics,
        startApp: () {
          runApp(
            MirrorApp(
              cameraService: FlutterCameraService(diagnostics: diagnostics),
              diagnostics: diagnostics,
              settingsStore: FileSettingsStore(),
            ),
          );
        },
      );
    },
    diagnostics.logStartupError,
  );
}

/// Runs the Mirror app startup sequence.
///
/// Applies fullscreen via [fullscreenService] before invoking [startApp]
/// (DD-SRS-F-FBD.15). Errors from the fullscreen call are guarded so they
/// cannot prevent [startApp] from running (DD-SRS-F-FBD.16). Logs a startup
/// phase via [diagnostics] before the app starts.
@visibleForTesting
Future<void> runMirror({
  required FullscreenService fullscreenService,
  required Diagnostics diagnostics,
  required void Function() startApp,
}) async {
  try {
    await fullscreenService.enterFullscreen();
  } catch (error, stackTrace) {
    diagnostics.logStartupError(error, stackTrace);
  }
  diagnostics.logStartupPhase('before-run-app');
  startApp();
}

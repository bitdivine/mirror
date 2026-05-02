import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'camera/camera_service.dart';
import 'diagnostics.dart';

void main() {
  const diagnostics = Diagnostics(appVersion: '0.1.0');
  runZonedGuarded(
    () {
      diagnostics.logStartupPhase('before-run-app');
      runApp(
        MirrorApp(
          cameraService: FlutterCameraService(diagnostics: diagnostics),
          diagnostics: diagnostics,
        ),
      );
    },
    diagnostics.logStartupError,
  );
}

import 'package:flutter/material.dart';

import 'camera/camera_service.dart';
import 'diagnostics.dart';
import 'ui/mirror_screen.dart';

class MirrorApp extends StatelessWidget {
  const MirrorApp({
    required this.cameraService,
    required this.diagnostics,
    super.key,
  });

  final CameraService cameraService;
  final Diagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mirror',
      home: MirrorScreen(
        cameraService: cameraService,
        diagnostics: diagnostics,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../camera/camera_service.dart';

class MirroredCameraPreview extends StatelessWidget {
  const MirroredCameraPreview({required this.controller, super.key});

  final MirrorCameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.isReady) {
      return const Center(child: Text('Starting camera...'));
    }

    final aspectRatio =
        controller.aspectRatio <= 0 ? 1.0 : controller.aspectRatio;
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: aspectRatio,
            height: 1,
            child: controller.isPreviewMirrored
                ? controller.buildPreview()
                : Transform.flip(
                    flipX: true,
                    child: controller.buildPreview(),
                  ),
          ),
        ),
      ),
    );
  }
}

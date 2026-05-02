import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../diagnostics.dart';

enum MirrorCameraStatus {
  starting,
  ready,
  permissionDenied,
  cameraUnavailable,
  failed,
}

abstract class MirrorCameraController {
  bool get isReady;

  double get aspectRatio;

  bool get isPreviewMirrored;

  Widget buildPreview();

  Future<void> dispose();
}

class MirrorCameraOption {
  const MirrorCameraOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class MirrorCameraState {
  const MirrorCameraState._({
    required this.status,
    this.controller,
    this.selectedCameraId,
    this.cameras = const [],
    this.error,
  });

  const MirrorCameraState.starting()
      : this._(status: MirrorCameraStatus.starting);

  const MirrorCameraState.ready(
    MirrorCameraController controller, {
    required String selectedCameraId,
    required List<MirrorCameraOption> cameras,
  }) : this._(
          status: MirrorCameraStatus.ready,
          controller: controller,
          selectedCameraId: selectedCameraId,
          cameras: cameras,
        );

  const MirrorCameraState.permissionDenied()
      : this._(status: MirrorCameraStatus.permissionDenied);

  const MirrorCameraState.cameraUnavailable()
      : this._(status: MirrorCameraStatus.cameraUnavailable);

  const MirrorCameraState.failed(Object error)
      : this._(status: MirrorCameraStatus.failed, error: error);

  final MirrorCameraStatus status;
  final MirrorCameraController? controller;
  final String? selectedCameraId;
  final List<MirrorCameraOption> cameras;
  final Object? error;
}

abstract class CameraService {
  Future<MirrorCameraState> start({String? cameraId});

  Future<void> stop();
}

class FlutterCameraService implements CameraService {
  FlutterCameraService({required this.diagnostics});

  final Diagnostics diagnostics;
  CameraControllerAdapter? _activeController;

  @override
  Future<MirrorCameraState> start({String? cameraId}) async {
    diagnostics.logCameraPhase('start-requested');
    await stop();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        diagnostics.logCameraPhase('unavailable');
        return const MirrorCameraState.cameraUnavailable();
      }

      final cameraOptions =
          cameras.map(_toCameraOption).toList(growable: false);
      CameraException? lastCameraException;
      StackTrace? lastCameraStackTrace;

      for (final selectedCamera in _startupCameraOrder(cameras, cameraId)) {
        for (final resolutionPreset in _startupResolutionPresets()) {
          diagnostics.logCameraPhase(
            'initialize ${selectedCamera.name} preset=${resolutionPreset.name}',
          );
          final controller = CameraController(
            selectedCamera,
            resolutionPreset,
            enableAudio: false,
          );

          try {
            await controller.initialize();
            _activeController = CameraControllerAdapter(controller);
            diagnostics.logCameraPhase('ready');
            return MirrorCameraState.ready(
              _activeController!,
              selectedCameraId: selectedCamera.name,
              cameras: cameraOptions,
            );
          } on CameraException catch (error, stackTrace) {
            lastCameraException = error;
            lastCameraStackTrace = stackTrace;
            diagnostics.logCameraError(
              _cameraExceptionCategory(error),
              error,
              stackTrace,
            );
            await controller.dispose();
          }
        }
      }

      if (lastCameraException != null) {
        if (_cameraExceptionCategory(lastCameraException) ==
            'permission-denied') {
          return const MirrorCameraState.permissionDenied();
        }
        return MirrorCameraState.failed(lastCameraException);
      }
      if (lastCameraStackTrace != null) {
        diagnostics.logCameraError(
          'startup-failed',
          'Camera initialization failed without an exception',
          lastCameraStackTrace,
        );
      }
      return MirrorCameraState.failed('Camera initialization failed');
    } on CameraException catch (error, stackTrace) {
      final category = _cameraExceptionCategory(error);
      diagnostics.logCameraError(category, error, stackTrace);
      if (category == 'permission-denied') {
        return const MirrorCameraState.permissionDenied();
      }
      return MirrorCameraState.failed(error);
    } catch (error, stackTrace) {
      diagnostics.logCameraError('startup-failed', error, stackTrace);
      return MirrorCameraState.failed(error);
    }
  }

  @override
  Future<void> stop() async {
    final controller = _activeController;
    _activeController = null;
    if (controller == null) {
      return;
    }

    diagnostics.logCameraPhase('stop');
    await controller.dispose();
  }

  List<ResolutionPreset> _startupResolutionPresets() {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      return const [
        ResolutionPreset.low,
        ResolutionPreset.medium,
      ];
    }
    return const [ResolutionPreset.high];
  }

  List<CameraDescription> _startupCameraOrder(
    List<CameraDescription> cameras,
    String? cameraId,
  ) {
    final ordered = <CameraDescription>[];
    if (cameraId != null) {
      for (final camera in cameras) {
        if (camera.name == cameraId) {
          ordered.add(camera);
          break;
        }
      }
    }

    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front &&
          !ordered.contains(camera)) {
        ordered.add(camera);
      }
    }
    for (final camera in cameras) {
      if (!ordered.contains(camera)) {
        ordered.add(camera);
      }
    }
    return ordered;
  }

  MirrorCameraOption _toCameraOption(CameraDescription camera) {
    return MirrorCameraOption(
      id: camera.name,
      label: '${_cameraDirectionLabel(camera)} camera (${camera.name})',
    );
  }

  String _cameraDirectionLabel(CameraDescription camera) {
    switch (camera.lensDirection) {
      case CameraLensDirection.front:
        return 'Front';
      case CameraLensDirection.back:
        return 'Back';
      case CameraLensDirection.external:
        return 'External';
    }
  }

  String _cameraExceptionCategory(CameraException error) {
    final code = error.code.toLowerCase();
    if (code.contains('accessdenied') ||
        code.contains('permission') ||
        code.contains('restricted')) {
      return 'permission-denied';
    }
    return code.isEmpty ? 'camera-error' : code;
  }
}

class CameraControllerAdapter implements MirrorCameraController {
  CameraControllerAdapter(this.controller);

  final CameraController controller;

  @override
  bool get isReady => controller.value.isInitialized;

  @override
  double get aspectRatio => controller.value.aspectRatio;

  @override
  bool get isPreviewMirrored {
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows =>
        true,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS =>
        false,
    };
  }

  @override
  Widget buildPreview() => CameraPreview(controller);

  @override
  Future<void> dispose() => controller.dispose();
}

import 'package:flutter/material.dart';

import '../camera/camera_service.dart';
import '../diagnostics.dart';
import '../settings/settings_store.dart';
import 'mirrored_camera_preview.dart';

class MirrorScreen extends StatefulWidget {
  const MirrorScreen({
    required this.cameraService,
    required this.diagnostics,
    required this.settingsStore,
    super.key,
  });

  final CameraService cameraService;
  final Diagnostics diagnostics;
  final SettingsStore settingsStore;

  @override
  State<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends State<MirrorScreen>
    with WidgetsBindingObserver {
  MirrorCameraState _cameraState = const MirrorCameraState.starting();
  Future<void>? _cameraStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.cameraService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      widget.cameraService.stop();
      setState(() {
        _cameraState = const MirrorCameraState.starting();
      });
      return;
    }

    if (state == AppLifecycleState.resumed &&
        _cameraState.status != MirrorCameraStatus.ready) {
      _startCamera();
    }
  }

  Future<void> _startCamera({String? cameraId}) async {
    if (_cameraStart != null) {
      return _cameraStart;
    }
    final start = _startCameraOnce(cameraId: cameraId);
    _cameraStart = start;
    try {
      await start;
    } finally {
      if (_cameraStart == start) {
        _cameraStart = null;
      }
    }
  }

  Future<void> _startCameraOnce({String? cameraId}) async {
    widget.diagnostics.logCameraPhase('screen-start');
    setState(() {
      _cameraState = const MirrorCameraState.starting();
    });

    final preferredCameraId =
        cameraId ?? await widget.settingsStore.loadLastCameraId();
    if (!mounted) {
      return;
    }

    final nextState =
        await widget.cameraService.start(cameraId: preferredCameraId);
    if (!mounted) {
      return;
    }

    setState(() {
      _cameraState = nextState;
    });

    final selectedCameraId = nextState.selectedCameraId;
    if (nextState.status == MirrorCameraStatus.ready &&
        selectedCameraId != null) {
      await widget.settingsStore.saveLastCameraId(selectedCameraId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    switch (_cameraState.status) {
      case MirrorCameraStatus.starting:
        return const Center(child: CircularProgressIndicator());
      case MirrorCameraStatus.ready:
        final controller = _cameraState.controller;
        if (controller == null) {
          return _buildFailure();
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            MirroredCameraPreview(controller: controller),
            if (_cameraState.cameras.length > 1)
              _buildCameraSelector(_cameraState),
          ],
        );
      case MirrorCameraStatus.permissionDenied:
        return const Center(
          child: Text('Camera access is required to use the mirror.'),
        );
      case MirrorCameraStatus.cameraUnavailable:
        return const Center(
          child: Text('No camera is available on this device.'),
        );
      case MirrorCameraStatus.failed:
        return _buildFailure();
    }
  }

  Widget _buildFailure() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Camera failed to start.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startCamera,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSelector(MirrorCameraState state) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                key: const ValueKey('camera-selector'),
                dropdownColor: Colors.black87,
                value: state.selectedCameraId,
                iconEnabledColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox.shrink(),
                items: [
                  for (final camera in state.cameras)
                    DropdownMenuItem(
                      value: camera.id,
                      child: Text(camera.label),
                    ),
                ],
                onChanged: (cameraId) {
                  if (cameraId == null || cameraId == state.selectedCameraId) {
                    return;
                  }
                  _startCamera(cameraId: cameraId);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

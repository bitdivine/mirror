import 'package:flutter/material.dart';

import '../camera/camera_service.dart';
import '../diagnostics.dart';
import 'mirrored_camera_preview.dart';

class MirrorScreen extends StatefulWidget {
  const MirrorScreen({
    required this.cameraService,
    required this.diagnostics,
    super.key,
  });

  final CameraService cameraService;
  final Diagnostics diagnostics;

  @override
  State<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends State<MirrorScreen>
    with WidgetsBindingObserver {
  MirrorCameraState _cameraState = const MirrorCameraState.starting();

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

  Future<void> _startCamera() async {
    widget.diagnostics.logCameraPhase('screen-start');
    setState(() {
      _cameraState = const MirrorCameraState.starting();
    });

    final nextState = await widget.cameraService.start();
    if (!mounted) {
      return;
    }

    setState(() {
      _cameraState = nextState;
    });
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
        return MirroredCameraPreview(controller: controller);
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
}

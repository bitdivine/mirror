import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror/app.dart';
import 'package:mirror/camera/camera_service.dart';
import 'package:mirror/diagnostics.dart';
import 'package:mirror/ui/mirrored_camera_preview.dart';

void main() {
  const frontCamera = MirrorCameraOption(id: 'front', label: 'Front camera');
  const backCamera = MirrorCameraOption(id: 'back', label: 'Back camera');

  testWidgets('renders mirrored preview when camera is ready', (tester) async {
    final cameraService = FakeCameraService(
      const MirrorCameraState.ready(
        FakeMirrorCameraController(),
        selectedCameraId: 'front',
        cameras: [frontCamera],
      ),
    );

    await tester.pumpWidget(
      MirrorApp(
        cameraService: cameraService,
        diagnostics: const Diagnostics(appVersion: 'test'),
      ),
    );
    await tester.pump();

    expect(find.text('camera-preview'), findsOneWidget);
    expect(cameraService.startCalls, 1);
  });

  testWidgets('shows permission denied message', (tester) async {
    await tester.pumpWidget(
      MirrorApp(
        cameraService: FakeCameraService(
          const MirrorCameraState.permissionDenied(),
        ),
        diagnostics: const Diagnostics(appVersion: 'test'),
      ),
    );
    await tester.pump();

    expect(
      find.text('Camera access is required to use the mirror.'),
      findsOneWidget,
    );
  });

  testWidgets('shows no camera message', (tester) async {
    await tester.pumpWidget(
      MirrorApp(
        cameraService: FakeCameraService(
          const MirrorCameraState.cameraUnavailable(),
        ),
        diagnostics: const Diagnostics(appVersion: 'test'),
      ),
    );
    await tester.pump();

    expect(
      find.text('No camera is available on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('shows retry action after camera failure', (tester) async {
    final cameraService = FakeCameraService(
      MirrorCameraState.failed(Exception('boom')),
    );

    await tester.pumpWidget(
      MirrorApp(
        cameraService: cameraService,
        diagnostics: const Diagnostics(appVersion: 'test'),
      ),
    );
    await tester.pump();

    expect(find.text('Camera failed to start.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(cameraService.startCalls, 2);
  });

  testWidgets('shows camera selector when multiple cameras are available',
      (tester) async {
    final cameraService = FakeCameraService(
      const MirrorCameraState.ready(
        FakeMirrorCameraController(),
        selectedCameraId: 'front',
        cameras: [frontCamera, backCamera],
      ),
    );

    await tester.pumpWidget(
      MirrorApp(
        cameraService: cameraService,
        diagnostics: const Diagnostics(appVersion: 'test'),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('camera-selector')), findsOneWidget);
    expect(find.text('Front camera'), findsOneWidget);
  });

  testWidgets('changing selected camera restarts selected camera',
      (tester) async {
    final cameraService = FakeCameraService(
      const MirrorCameraState.ready(
        FakeMirrorCameraController(),
        selectedCameraId: 'front',
        cameras: [frontCamera, backCamera],
      ),
    );

    await tester.pumpWidget(
      MirrorApp(
        cameraService: cameraService,
        diagnostics: const Diagnostics(appVersion: 'test'),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('camera-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back camera').last);
    await tester.pump();

    expect(cameraService.startCalls, 2);
    expect(cameraService.selectedCameraIds.last, 'back');
  });

  testWidgets('mirrored preview applies horizontal transform', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MirroredCameraPreview(
          controller: FakeMirrorCameraController(),
        ),
      ),
    );

    final transform = tester.widget<Transform>(find.byType(Transform));
    expect(transform.transform.storage[0], -1);
  });

  testWidgets('mirrored platform preview is not flipped again', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MirroredCameraPreview(
          controller: FakeMirrorCameraController(isPreviewMirrored: true),
        ),
      ),
    );

    expect(find.byType(Transform), findsNothing);
    expect(find.text('camera-preview'), findsOneWidget);
  });
}

class FakeCameraService implements CameraService {
  FakeCameraService(this.state);

  final MirrorCameraState state;
  int startCalls = 0;
  int stopCalls = 0;
  final List<String?> selectedCameraIds = [];

  @override
  Future<MirrorCameraState> start({String? cameraId}) async {
    startCalls += 1;
    selectedCameraIds.add(cameraId);
    return state;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }
}

class FakeMirrorCameraController implements MirrorCameraController {
  const FakeMirrorCameraController({
    this.ready = true,
    this.isPreviewMirrored = false,
  });

  final bool ready;

  @override
  bool get isReady => ready;

  @override
  final bool isPreviewMirrored;

  @override
  double get aspectRatio => 1;

  @override
  Widget buildPreview() => const Text('camera-preview');

  @override
  Future<void> dispose() async {}
}

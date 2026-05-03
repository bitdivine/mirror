import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror/ai/appearance_analysis.dart';
import 'package:mirror/app.dart';
import 'package:mirror/camera/camera_service.dart';
import 'package:mirror/diagnostics.dart';
import 'package:mirror/settings/settings_store.dart';
import 'package:mirror/ui/mirrored_camera_preview.dart';

void main() {
  const frontCamera = MirrorCameraOption(id: 'front', label: 'Front camera');
  const backCamera = MirrorCameraOption(id: 'back', label: 'Back camera');

  testWidgets('renders mirrored preview when camera is ready', (tester) async {
    final cameraService = FakeCameraService(
      MirrorCameraState.ready(
        FakeMirrorCameraController(),
        selectedCameraId: 'front',
        cameras: [frontCamera],
      ),
    );

    await tester.pumpWidget(
      MirrorApp(
        cameraService: cameraService,
        diagnostics: const Diagnostics(appVersion: 'test'),
        settingsStore: FakeSettingsStore(),
      ),
    );
    await tester.pump();

    expect(find.text('camera-preview'), findsOneWidget);
    expect(cameraService.startCalls, 1);
  });

  testWidgets('starts remembered camera when one is stored', (tester) async {
    final cameraService = FakeCameraService(
      MirrorCameraState.ready(
        FakeMirrorCameraController(),
        selectedCameraId: 'front',
        cameras: [frontCamera, backCamera],
      ),
    );

    await tester.pumpWidget(
      MirrorApp(
        cameraService: cameraService,
        diagnostics: const Diagnostics(appVersion: 'test'),
        settingsStore: FakeSettingsStore(cameraId: 'back'),
      ),
    );
    await tester.pump();

    expect(cameraService.selectedCameraIds.first, 'back');
  });

  testWidgets('remembers camera after successful startup', (tester) async {
    final settingsStore = FakeSettingsStore();

    await tester.pumpWidget(
      MirrorApp(
        cameraService: FakeCameraService(
          MirrorCameraState.ready(
            FakeMirrorCameraController(),
            selectedCameraId: 'front',
            cameras: [frontCamera],
          ),
        ),
        diagnostics: const Diagnostics(appVersion: 'test'),
        settingsStore: settingsStore,
      ),
    );
    await tester.pump();

    expect(settingsStore.savedCameraIds, ['front']);
  });

  testWidgets('shows permission denied message', (tester) async {
    await tester.pumpWidget(
      MirrorApp(
        cameraService: FakeCameraService(
          const MirrorCameraState.permissionDenied(),
        ),
        diagnostics: const Diagnostics(appVersion: 'test'),
        settingsStore: FakeSettingsStore(),
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
        settingsStore: FakeSettingsStore(),
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
        settingsStore: FakeSettingsStore(),
      ),
    );
    await tester.pump();

    expect(find.text('Camera failed to start.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(cameraService.startCalls, 2);
  });

  testWidgets('hides camera selector until video is tapped', (tester) async {
    final cameraService = FakeCameraService(
      MirrorCameraState.ready(
        FakeMirrorCameraController(),
        selectedCameraId: 'front',
        cameras: [frontCamera, backCamera],
      ),
    );

    await tester.pumpWidget(
      MirrorApp(
        cameraService: cameraService,
        diagnostics: const Diagnostics(appVersion: 'test'),
        settingsStore: FakeSettingsStore(),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('camera-selector')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('mirror-video-surface')));
    await tester.pump();

    expect(find.byKey(const ValueKey('camera-selector')), findsOneWidget);
    expect(find.text('Front camera'), findsOneWidget);
  });

  testWidgets('tapping video toggles camera selector visibility',
      (tester) async {
    final cameraService = FakeCameraService(
      MirrorCameraState.ready(
        FakeMirrorCameraController(),
        selectedCameraId: 'front',
        cameras: [frontCamera, backCamera],
      ),
    );

    await tester.pumpWidget(
      MirrorApp(
        cameraService: cameraService,
        diagnostics: const Diagnostics(appVersion: 'test'),
        settingsStore: FakeSettingsStore(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('mirror-video-surface')));
    await tester.pump();
    expect(find.byKey(const ValueKey('camera-selector')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mirror-video-surface')));
    await tester.pump();
    expect(find.byKey(const ValueKey('camera-selector')), findsNothing);
  });

  testWidgets('changing selected camera restarts selected camera',
      (tester) async {
    final cameraService = FakeCameraService(
      MirrorCameraState.ready(
        FakeMirrorCameraController(),
        selectedCameraId: 'front',
        cameras: [frontCamera, backCamera],
      ),
      useRequestedCamera: true,
    );
    final settingsStore = FakeSettingsStore();

    await tester.pumpWidget(
      MirrorApp(
        cameraService: cameraService,
        diagnostics: const Diagnostics(appVersion: 'test'),
        settingsStore: settingsStore,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('mirror-video-surface')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('camera-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back camera').last);
    await tester.pump();

    expect(cameraService.startCalls, 2);
    expect(cameraService.selectedCameraIds.last, 'back');
    expect(settingsStore.savedCameraIds.last, 'back');
  });

  testWidgets('analyzes a captured still and shows appearance detail',
      (tester) async {
    final controller = FakeMirrorCameraController(stillPath: 'still.jpg');
    final appearanceAnalysisService = FakeAppearanceAnalysisService();

    await tester.pumpWidget(
      MirrorApp(
        cameraService: FakeCameraService(
          MirrorCameraState.ready(
            controller,
            selectedCameraId: 'front',
            cameras: const [frontCamera],
          ),
        ),
        diagnostics: const Diagnostics(appVersion: 'test'),
        appearanceAnalysisService: appearanceAnalysisService,
        settingsStore: FakeSettingsStore(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('mirror-video-surface')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('analyze-appearance-button')));
    await tester.pump();
    await tester.pump();

    expect(controller.takeStillCalls, 1);
    expect(appearanceAnalysisService.imageFiles.single.path, 'still.jpg');
    expect(find.byKey(const ValueKey('appearance-analysis-result')), findsOne);
    expect(find.textContaining('CEO'), findsWidgets);
    expect(find.textContaining('senior'), findsWidgets);
  });

  testWidgets('mirrored preview applies horizontal transform', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
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
      MaterialApp(
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
  FakeCameraService(this.state, {this.useRequestedCamera = false});

  final MirrorCameraState state;
  final bool useRequestedCamera;
  int startCalls = 0;
  int stopCalls = 0;
  final List<String?> selectedCameraIds = [];

  @override
  Future<MirrorCameraState> start({String? cameraId}) async {
    startCalls += 1;
    selectedCameraIds.add(cameraId);
    if (useRequestedCamera &&
        state.status == MirrorCameraStatus.ready &&
        cameraId != null &&
        state.controller != null) {
      return MirrorCameraState.ready(
        state.controller!,
        selectedCameraId: cameraId,
        cameras: state.cameras,
      );
    }
    return state;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }
}

class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore({this.cameraId});

  String? cameraId;
  final List<String> savedCameraIds = [];

  @override
  Future<String?> loadLastCameraId() async => cameraId;

  @override
  Future<void> saveLastCameraId(String cameraId) async {
    this.cameraId = cameraId;
    savedCameraIds.add(cameraId);
  }
}

class FakeMirrorCameraController implements MirrorCameraController {
  FakeMirrorCameraController({
    this.ready = true,
    this.isPreviewMirrored = false,
    this.stillPath = 'test-still.jpg',
  });

  final bool ready;
  final String stillPath;
  int takeStillCalls = 0;

  @override
  bool get isReady => ready;

  @override
  final bool isPreviewMirrored;

  @override
  double get aspectRatio => 1;

  @override
  Widget buildPreview() => const Text('camera-preview');

  @override
  Future<MirrorCameraStill> takeStill() async {
    takeStillCalls += 1;
    return MirrorCameraStill(path: stillPath);
  }

  @override
  Future<void> dispose() async {}
}

class FakeAppearanceAnalysisService implements AppearanceAnalysisService {
  final List<File> imageFiles = [];

  @override
  Future<AppearanceAnalysis> analyzeStill(File imageFile) async {
    imageFiles.add(imageFile);
    return const AppearanceAnalysis(
      overallDescription: 'Polished, tidy, and executive in presentation.',
      visibleAppearance: 'The person appears composed and deliberate.',
      groomingAndTidiness: 'The presentation looks tidy.',
      clothingAndAccessories: 'The outfit reads as formal.',
      styleAndPresentation: 'The style suggests a CEO or senior manager.',
      demeanorAndVibe: 'The still gives a calm, confident impression.',
      likelyOccupationSignals: 'Likely CEO, founder, or senior operator.',
      likelySenioritySignals: 'Signals appear senior rather than junior.',
      impressionLabels: ['tidy', 'executive', 'senior'],
      uncertaintyNotes: 'This is an appearance-based impression only.',
    );
  }
}

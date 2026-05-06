import 'package:flutter_test/flutter_test.dart';
import 'package:mirror/diagnostics.dart';
import 'package:mirror/main.dart' show runMirror;
import 'package:mirror/platform/fullscreen_service.dart';

void main() {
  const diagnostics = Diagnostics(appVersion: 'test');

  group('runMirror', () {
    test('applies fullscreen and then runs the app', () async {
      final service = _RecordingFullscreenService();
      var startAppCalls = 0;

      await runMirror(
        fullscreenService: service,
        diagnostics: diagnostics,
        startApp: () {
          expect(
            service.enterFullscreenCalls,
            1,
            reason:
                'Fullscreen MUST be applied before runApp (DD-SRS-F-FBD.15).',
          );
          startAppCalls += 1;
        },
      );

      expect(service.enterFullscreenCalls, 1);
      expect(startAppCalls, 1);
    });

    test('still runs the app when the fullscreen service throws', () async {
      final service = _ThrowingFullscreenService();
      var startAppCalls = 0;

      await runMirror(
        fullscreenService: service,
        diagnostics: diagnostics,
        startApp: () {
          startAppCalls += 1;
        },
      );

      expect(
        startAppCalls,
        1,
        reason:
            'A fullscreen failure MUST NOT prevent the app from starting '
            '(DD-SRS-F-FBD.16).',
      );
    });
  });

  group('UnsupportedFullscreenService', () {
    test('completes without throwing and logs', () async {
      final service =
          const UnsupportedFullscreenService(diagnostics: diagnostics);

      await expectLater(service.enterFullscreen(), completes);
    });
  });

  group('ImmersiveFullscreenService', () {
    test('requests immersiveSticky system UI mode on success', () async {
      final modes = <Object>[];
      final service = ImmersiveFullscreenService(
        diagnostics: diagnostics,
        setEnabledSystemUIMode: (mode) async {
          modes.add(mode);
        },
      );

      await service.enterFullscreen();

      expect(modes, hasLength(1));
      expect(modes.single.toString(), contains('immersiveSticky'));
    });

    test(
      'swallows errors so startup is not blocked (DD-SRS-F-FBD.4)',
      () async {
        final service = ImmersiveFullscreenService(
          diagnostics: diagnostics,
          setEnabledSystemUIMode: (mode) async {
            throw StateError('boom');
          },
        );

        await expectLater(service.enterFullscreen(), completes);
      },
    );
  });
}

class _RecordingFullscreenService implements FullscreenService {
  int enterFullscreenCalls = 0;

  @override
  Future<void> enterFullscreen() async {
    enterFullscreenCalls += 1;
  }
}

class _ThrowingFullscreenService implements FullscreenService {
  @override
  Future<void> enterFullscreen() async {
    throw StateError('fullscreen unavailable');
  }
}

import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../diagnostics.dart';

/// Cross-platform contract for putting the Mirror app into fullscreen at
/// startup.
///
/// The Flutter UI layer MUST NOT call platform fullscreen APIs directly; it
/// MUST go through this service (DD-SRS-F-FBD.6).
///
/// Implementations are expected to be invoked exactly once per app launch,
/// from `main()` before `runApp(MirrorApp)` (DD-SRS-F-FBD.5,
/// DD-SRS-F-FBD.15).
abstract class FullscreenService {
  /// Puts the current native surface into fullscreen for the current
  /// platform.
  ///
  /// MUST NOT throw on unsupported platforms (DD-SRS-F-FBD.4). Failures are
  /// logged via [Diagnostics] and the future completes normally.
  Future<void> enterFullscreen();

  /// Returns the fullscreen service appropriate for the current platform.
  ///
  /// Desktop platforms (Linux, macOS, Windows) get a window-based
  /// implementation. Mobile platforms (Android, iOS) get an immersive system
  /// UI implementation. Anything else gets a no-op implementation that only
  /// logs.
  factory FullscreenService.forCurrentPlatform({
    required Diagnostics diagnostics,
  }) {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return WindowFullscreenService(diagnostics: diagnostics);
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return ImmersiveFullscreenService(diagnostics: diagnostics);
    }
    return UnsupportedFullscreenService(diagnostics: diagnostics);
  }
}

/// Desktop implementation of [FullscreenService].
///
/// Uses the `window_manager` plugin to put the main app window into
/// fullscreen on Linux, macOS, and Windows (DD-SRS-F-FBD.7).
class WindowFullscreenService implements FullscreenService {
  WindowFullscreenService({
    required this.diagnostics,
    WindowManager? windowManagerOverride,
  }) : _windowManager = windowManagerOverride ?? windowManager;

  final Diagnostics diagnostics;
  final WindowManager _windowManager;

  @override
  Future<void> enterFullscreen() async {
    try {
      await _windowManager.ensureInitialized();
      await _windowManager.setFullScreen(true);
      diagnostics.logFullscreenApplied();
    } catch (error, stackTrace) {
      diagnostics.logFullscreenFailed(error, stackTrace);
    }
  }
}

/// Mobile implementation of [FullscreenService].
///
/// Uses Flutter's built-in `SystemChrome.setEnabledSystemUIMode` to enter
/// immersive presentation on Android and iPhone (DD-SRS-F-FBD.11).
class ImmersiveFullscreenService implements FullscreenService {
  ImmersiveFullscreenService({
    required this.diagnostics,
    Future<void> Function(SystemUiMode mode)? setEnabledSystemUIMode,
  }) : _setEnabledSystemUIMode =
            setEnabledSystemUIMode ?? SystemChrome.setEnabledSystemUIMode;

  final Diagnostics diagnostics;
  final Future<void> Function(SystemUiMode mode) _setEnabledSystemUIMode;

  @override
  Future<void> enterFullscreen() async {
    try {
      await _setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      diagnostics.logFullscreenApplied();
    } catch (error, stackTrace) {
      diagnostics.logFullscreenFailed(error, stackTrace);
    }
  }
}

/// Fallback implementation for platforms where programmatic fullscreen is
/// not supported. Logs and returns without doing anything else
/// (DD-SRS-F-FBD.4).
class UnsupportedFullscreenService implements FullscreenService {
  const UnsupportedFullscreenService({required this.diagnostics});

  final Diagnostics diagnostics;

  @override
  Future<void> enterFullscreen() async {
    diagnostics.logFullscreenUnsupported();
  }
}

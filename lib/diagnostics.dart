import 'dart:developer' as developer;

import 'diagnostics_platform.dart';

class Diagnostics {
  const Diagnostics({required this.appVersion});

  final String appVersion;

  void logStartupPhase(String phase) {
    _log(
      'startup phase=$phase appVersion=$appVersion '
      'os=$operatingSystemName architecture=$processorArchitecture',
      name: 'mirror.startup',
    );
  }

  void logStartupError(Object error, StackTrace stackTrace) {
    _log(
      'startup phase=startup-error appVersion=$appVersion '
      'os=$operatingSystemName architecture=$processorArchitecture',
      name: 'mirror.startup',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logCameraPhase(String phase) {
    _log(
      'camera phase=$phase appVersion=$appVersion '
      'os=$operatingSystemName',
      name: 'mirror.camera',
    );
  }

  void logFullscreenApplied() {
    _log(
      'startup phase=fullscreen-applied appVersion=$appVersion '
      'os=$operatingSystemName',
      name: 'mirror.startup',
    );
  }

  void logFullscreenFailed(Object error, StackTrace stackTrace) {
    _log(
      'startup phase=fullscreen-failed appVersion=$appVersion '
      'os=$operatingSystemName',
      name: 'mirror.startup',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logFullscreenUnsupported() {
    _log(
      'startup phase=fullscreen-unsupported appVersion=$appVersion '
      'os=$operatingSystemName',
      name: 'mirror.startup',
    );
  }

  void logCameraError(String category, Object error, StackTrace stackTrace) {
    _log(
      'camera phase=error category=$category appVersion=$appVersion '
      'os=$operatingSystemName',
      name: 'mirror.camera',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log(
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
    print('[$name] $message');
    if (error != null) {
      print('[$name] error=$error');
    }
    if (stackTrace != null) {
      print(stackTrace);
    }
  }
}

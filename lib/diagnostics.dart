import 'dart:developer' as developer;

import 'diagnostics_platform.dart';

class Diagnostics {
  const Diagnostics({required this.appVersion});

  final String appVersion;

  void logStartupPhase(String phase) {
    developer.log(
      'startup phase=$phase appVersion=$appVersion '
      'os=$operatingSystemName architecture=$processorArchitecture',
      name: 'mirror.startup',
    );
  }

  void logStartupError(Object error, StackTrace stackTrace) {
    developer.log(
      'startup phase=startup-error appVersion=$appVersion '
      'os=$operatingSystemName architecture=$processorArchitecture',
      name: 'mirror.startup',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logCameraPhase(String phase) {
    developer.log(
      'camera phase=$phase appVersion=$appVersion '
      'os=$operatingSystemName',
      name: 'mirror.camera',
    );
  }

  void logCameraError(String category, Object error, StackTrace stackTrace) {
    developer.log(
      'camera phase=error category=$category appVersion=$appVersion '
      'os=$operatingSystemName',
      name: 'mirror.camera',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

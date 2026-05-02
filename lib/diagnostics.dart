import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

class StartupDiagnostics {
  const StartupDiagnostics({required this.appVersion});

  final String appVersion;

  void logPhase(String phase) {
    developer.log(
      'startup phase=$phase appVersion=$appVersion '
      'os=${Platform.operatingSystem} architecture=${Abi.current()}',
      name: 'mirror.startup',
    );
  }

  void logError(Object error, StackTrace stackTrace) {
    developer.log(
      'startup phase=startup-error appVersion=$appVersion '
      'os=${Platform.operatingSystem} architecture=${Abi.current()}',
      name: 'mirror.startup',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

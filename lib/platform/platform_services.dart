import '../diagnostics.dart';

abstract class PlatformServices {
  void logStartupPhase(String phase);

  void logStartupError(Object error, StackTrace stackTrace);
}

class DefaultPlatformServices implements PlatformServices {
  const DefaultPlatformServices({
    this.diagnostics = const StartupDiagnostics(appVersion: '0.1.0'),
  });

  final StartupDiagnostics diagnostics;

  @override
  void logStartupPhase(String phase) {
    diagnostics.logPhase(phase);
  }

  @override
  void logStartupError(Object error, StackTrace stackTrace) {
    diagnostics.logError(error, stackTrace);
  }
}

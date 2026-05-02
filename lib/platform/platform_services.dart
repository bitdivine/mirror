import '../diagnostics.dart';

abstract class PlatformServices {
  void logStartupPhase(String phase);

  void logStartupError(Object error, StackTrace stackTrace);
}

class DefaultPlatformServices implements PlatformServices {
  const DefaultPlatformServices({
    this.diagnostics = const Diagnostics(appVersion: '0.1.0'),
  });

  final Diagnostics diagnostics;

  @override
  void logStartupPhase(String phase) {
    diagnostics.logStartupPhase(phase);
  }

  @override
  void logStartupError(Object error, StackTrace stackTrace) {
    diagnostics.logStartupError(error, stackTrace);
  }
}

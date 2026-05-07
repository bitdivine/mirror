import '../diagnostics.dart';
import '../version.dart' as version;

abstract class PlatformServices {
  void logStartupPhase(String phase);

  void logStartupError(Object error, StackTrace stackTrace);
}

class DefaultPlatformServices implements PlatformServices {
  const DefaultPlatformServices({
    this.diagnostics = const Diagnostics(appVersion: version.appVersion),
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

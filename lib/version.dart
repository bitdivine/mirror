/// Build-time application version.
///
/// Set via `--dart-define=MIRROR_VERSION=<semver>+<commit>` during
/// `flutter build` or `flutter run`.  Falls back to `'dev'` when no
/// define is supplied (local development).
const String appVersion =
    String.fromEnvironment('MIRROR_VERSION', defaultValue: 'dev');

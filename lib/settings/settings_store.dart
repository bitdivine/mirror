import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract class SettingsStore {
  Future<String?> loadLastCameraId();

  Future<void> saveLastCameraId(String cameraId);
}

class FileSettingsStore implements SettingsStore {
  FileSettingsStore({
    Future<Directory> Function()? configDirectory,
  }) : _configDirectory = configDirectory ?? defaultConfigDirectory;

  static const _settingsFileName = 'settings.json';
  static const _lastCameraIdKey = 'lastCameraId';

  final Future<Directory> Function() _configDirectory;

  @override
  Future<String?> loadLastCameraId() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return null;
    }

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?>) {
      return null;
    }

    final cameraId = decoded[_lastCameraIdKey];
    if (cameraId is String && cameraId.isNotEmpty) {
      return cameraId;
    }
    return null;
  }

  @override
  Future<void> saveLastCameraId(String cameraId) async {
    final file = await _settingsFile();
    final settings = {_lastCameraIdKey: cameraId};
    await file.writeAsString('${jsonEncode(settings)}\n');
  }

  Future<File> _settingsFile() async {
    final directory = await _configDirectory();
    await directory.create(recursive: true);
    return File(_joinPath(directory.path, _settingsFileName));
  }

  static Future<Directory> defaultConfigDirectory() async {
    if (Platform.isLinux) {
      final configHome = Platform.environment['XDG_CONFIG_HOME'];
      if (configHome != null && configHome.isNotEmpty) {
        return Directory(_joinPath(configHome, 'mirror'));
      }

      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory(_joinPath(home, '.config', 'mirror'));
      }
    }

    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory(
          _joinPath(home, 'Library', 'Application Support', 'Mirror'),
        );
      }
    }

    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory(_joinPath(appData, 'Mirror'));
      }
    }

    return getApplicationSupportDirectory();
  }

  static String _joinPath(String first, String second,
      [String? third, String? fourth]) {
    final segments = [
      first,
      second,
      if (third != null) third,
      if (fourth != null) fourth,
    ];
    return segments
        .map((segment) => segment.replaceAll(RegExp(r'[\\/]+$'), ''))
        .join(Platform.pathSeparator);
  }
}

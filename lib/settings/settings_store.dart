import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract class SettingsStore {
  Future<String?> loadLastCameraId();

  Future<void> saveLastCameraId(String cameraId);

  Future<AppearanceCapture> createAppearanceCapture(File screenshotFile);

  Future<File> saveAppearanceAnalysisText(
    AppearanceCapture capture,
    String analysisText,
  );
}

class AppearanceCapture {
  const AppearanceCapture({
    required this.directory,
    required this.screenshotFile,
    required this.analysisFile,
  });

  final Directory directory;
  final File screenshotFile;
  final File analysisFile;
}

class FileSettingsStore implements SettingsStore {
  FileSettingsStore({
    Future<Directory> Function()? configDirectory,
    DateTime Function()? clock,
  })  : _configDirectory = configDirectory ?? defaultConfigDirectory,
        _clock = clock ?? DateTime.now;

  static const _settingsFileName = 'settings.json';
  static const _appearanceDirectoryName = 'appearance';
  static const _latestAppearanceLinkName = 'latest';
  static const _screenshotFileName = 'screenshot.jpg';
  static const _analysisFileName = 'analysis.txt';
  static const _lastCameraIdKey = 'lastCameraId';

  final Future<Directory> Function() _configDirectory;
  final DateTime Function() _clock;

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

  @override
  Future<AppearanceCapture> createAppearanceCapture(File screenshotFile) async {
    final directory = await _appearanceDirectory(_timestamp(_clock()));
    await directory.create(recursive: true);

    final copiedScreenshot = await screenshotFile
        .copy(_joinPath(directory.path, _screenshotFileName));
    await _updateLatestAppearanceLink(directory);

    return AppearanceCapture(
      directory: directory,
      screenshotFile: copiedScreenshot,
      analysisFile: File(_joinPath(directory.path, _analysisFileName)),
    );
  }

  @override
  Future<File> saveAppearanceAnalysisText(
    AppearanceCapture capture,
    String analysisText,
  ) async {
    await capture.analysisFile.writeAsString('$analysisText\n');
    return capture.analysisFile;
  }

  Future<File> _settingsFile() async {
    final directory = await _ensureConfigDirectory();
    return File(_joinPath(directory.path, _settingsFileName));
  }

  Future<Directory> _ensureConfigDirectory() async {
    final directory = await _configDirectory();
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _appearanceRootDirectory() async {
    final directory = await _ensureConfigDirectory();
    return Directory(_joinPath(directory.path, _appearanceDirectoryName));
  }

  Future<Directory> _appearanceDirectory(String timestamp) async {
    final directory = await _appearanceRootDirectory();
    return Directory(_joinPath(directory.path, timestamp));
  }

  Future<void> _updateLatestAppearanceLink(Directory target) async {
    final appearanceRoot = await _appearanceRootDirectory();
    await appearanceRoot.create(recursive: true);

    final latest = Link(_joinPath(
      appearanceRoot.path,
      _latestAppearanceLinkName,
    ));
    final latestType = await FileSystemEntity.type(
      latest.path,
      followLinks: false,
    );
    if (latestType == FileSystemEntityType.link ||
        latestType == FileSystemEntityType.file) {
      await latest.delete();
    } else if (latestType == FileSystemEntityType.directory) {
      throw FileSystemException(
        'Cannot replace appearance/latest because it is a directory.',
        latest.path,
      );
    }
    await latest.create(target.path);
  }

  static String _timestamp(DateTime timestamp) {
    return [
      timestamp.year.toString().padLeft(4, '0'),
      timestamp.month.toString().padLeft(2, '0'),
      timestamp.day.toString().padLeft(2, '0'),
      timestamp.hour.toString().padLeft(2, '0'),
      timestamp.minute.toString().padLeft(2, '0'),
      timestamp.second.toString().padLeft(2, '0'),
    ].join();
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

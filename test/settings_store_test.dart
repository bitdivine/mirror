import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirror/settings/settings_store.dart';

void main() {
  test('file settings store persists the last camera id', () async {
    final directory = await Directory.systemTemp.createTemp('mirror-settings-');
    addTearDown(() => directory.delete(recursive: true));

    final settingsStore = FileSettingsStore(configDirectory: () async {
      return directory;
    });

    await settingsStore.saveLastCameraId('camera-1');

    final reloadedSettingsStore = FileSettingsStore(configDirectory: () async {
      return directory;
    });

    expect(await reloadedSettingsStore.loadLastCameraId(), 'camera-1');
    expect(await File('${directory.path}/settings.json').exists(), isTrue);
  });

  test('file settings store saves the latest appearance analysis', () async {
    final directory = await Directory.systemTemp.createTemp('mirror-settings-');
    addTearDown(() => directory.delete(recursive: true));

    final settingsStore = FileSettingsStore(configDirectory: () async {
      return directory;
    });

    final file = await settingsStore.saveAppearanceAnalysisText(
      'Likely occupation signals: CEO or senior manager.',
    );

    expect(file.path, '${directory.path}/appearance-analysis.txt');
    expect(
      await file.readAsString(),
      'Likely occupation signals: CEO or senior manager.\n',
    );
  });
}

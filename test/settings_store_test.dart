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

  test('file settings store saves an appearance capture directory', () async {
    final directory = await Directory.systemTemp.createTemp('mirror-settings-');
    addTearDown(() => directory.delete(recursive: true));
    final sourceScreenshot = File('${directory.path}/source.jpg');
    await sourceScreenshot.writeAsString('image-bytes');

    final settingsStore = FileSettingsStore(
      configDirectory: () async {
        return directory;
      },
      clock: () => DateTime(2026, 5, 4, 10, 8, 9),
    );

    final capture = await settingsStore.createAppearanceCapture(
      sourceScreenshot,
    );
    final analysisFile = await settingsStore.saveAppearanceAnalysisText(
      capture,
      'Likely occupation signals: CEO or senior manager.',
    );

    final captureDirectory = '${directory.path}/appearance/20260504100809';
    expect(capture.directory.path, captureDirectory);
    expect(capture.screenshotFile.path, '$captureDirectory/screenshot.jpg');
    expect(await capture.screenshotFile.readAsString(), 'image-bytes');
    expect(analysisFile.path, '$captureDirectory/analysis.txt');
    expect(
      await analysisFile.readAsString(),
      'Likely occupation signals: CEO or senior manager.\n',
    );

    final latest = Link('${directory.path}/appearance/latest');
    expect(await latest.target(), captureDirectory);
  });
}

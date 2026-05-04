import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirror/ai/openai_appearance_analysis_service.dart';

void main() {
  test('loads OpenAI config from dotenv contents', () {
    final values = DotEnvOpenAiConfigLoader.parseDotEnv('''
# Comment
export OPENAI_API_KEY="test-key"
OPENAI_MODEL='test-model'
COMMENTED_VALUE=abc # local note
QUOTED_COMMENT="abc # still value"
IGNORED
''');

    expect(values['OPENAI_API_KEY'], 'test-key');
    expect(values['OPENAI_MODEL'], 'test-model');
    expect(values['COMMENTED_VALUE'], 'abc');
    expect(values['QUOTED_COMMENT'], 'abc # still value');
  });

  test('sends image to OpenAI and parses appearance analysis', () async {
    final image = await File('${Directory.systemTemp.path}/mirror-test.jpg')
        .create(recursive: true);
    addTearDown(() => image.delete());
    await image.writeAsBytes([1, 2, 3]);

    late Uri requestedEndpoint;
    late Map<String, String> requestedHeaders;
    late Map<String, Object?> requestedBody;

    final service = OpenAiAppearanceAnalysisService(
      configLoader: const FakeOpenAiConfigLoader(),
      endpoint: Uri.parse('https://example.test/openai'),
      postJson: (endpoint, headers, body) async {
        requestedEndpoint = endpoint;
        requestedHeaders = headers;
        requestedBody = body;
        return {
          'choices': [
            {
              'message': {
                'content': '''
{
  "overallDescription": "Polished and deliberate.",
  "visibleAppearance": "The person appears composed in the still.",
  "groomingAndTidiness": "Hair and clothing appear tidy.",
  "clothingAndAccessories": "The outfit reads as professional.",
  "styleAndPresentation": "The presentation feels executive.",
  "demeanorAndVibe": "The expression appears calm.",
  "likelyOccupationSignals": "Could plausibly read as a CEO or senior manager.",
  "likelySenioritySignals": "Signals lean senior rather than junior.",
  "ctoInterviewRecommendations": "For a CTO interview, keep the polished baseline and add a slightly sharper jacket or structured layer.",
  "impressionLabels": ["tidy", "executive"],
  "uncertaintyNotes": "This is an appearance-based impression only."
}
''',
              },
            },
          ],
        };
      },
    );

    final analysis = await service.analyzeStill(image);

    expect(requestedEndpoint, Uri.parse('https://example.test/openai'));
    expect(requestedHeaders['authorization'], 'Bearer test-key');
    expect(requestedBody['model'], 'test-model');
    expect(analysis.overallDescription, 'Polished and deliberate.');
    expect(
      analysis.likelyOccupationSignals,
      'Could plausibly read as a CEO or senior manager.',
    );
    expect(
      analysis.ctoInterviewRecommendations,
      contains('CTO interview'),
    );
    expect(analysis.impressionLabels, ['tidy', 'executive']);
  });

  test('includes sanitized OpenAI error details', () {
    expect(
      OpenAiAppearanceAnalysisService.formatOpenAiErrorForTest(
        401,
        {
          'error': {
            'message': 'Incorrect API key provided: sk-secret123.',
          },
        },
      ),
      'OpenAI request failed with HTTP 401: '
      'Incorrect API key provided: sk-....',
    );
  });
}

class FakeOpenAiConfigLoader implements OpenAiConfigLoader {
  const FakeOpenAiConfigLoader();

  @override
  Future<OpenAiConfig> load() async {
    return const OpenAiConfig(apiKey: 'test-key', model: 'test-model');
  }
}

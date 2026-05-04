import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'appearance_analysis.dart';

typedef OpenAiJsonPost = Future<Map<String, Object?>> Function(
  Uri endpoint,
  Map<String, String> headers,
  Map<String, Object?> body,
);

class OpenAiConfig {
  const OpenAiConfig({
    required this.apiKey,
    required this.model,
  });

  final String apiKey;
  final String model;
}

abstract class OpenAiConfigLoader {
  Future<OpenAiConfig> load();
}

class DotEnvOpenAiConfigLoader implements OpenAiConfigLoader {
  const DotEnvOpenAiConfigLoader({
    List<String> envFilePaths = const ['.env'],
  }) : _envFilePaths = envFilePaths;

  final List<String> _envFilePaths;

  @override
  Future<OpenAiConfig> load() async {
    final values = <String, String>{...Platform.environment};
    for (final path in _envFilePaths) {
      final file = File(path);
      if (!await file.exists()) {
        continue;
      }
      values.addAll(parseDotEnv(await file.readAsString()));
    }

    final apiKey = values['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw AppearanceAnalysisException(
        'OPENAI_API_KEY is missing. Add it to .env before analyzing a still.',
      );
    }

    return OpenAiConfig(
      apiKey: apiKey,
      model: values['OPENAI_MODEL'] ?? 'gpt-4o-mini',
    );
  }

  static Map<String, String> parseDotEnv(String contents) {
    final values = <String, String>{};
    for (final rawLine in const LineSplitter().convert(contents)) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      final normalized =
          line.startsWith('export ') ? line.substring('export '.length) : line;
      final separator = normalized.indexOf('=');
      if (separator <= 0) {
        continue;
      }

      final key = normalized.substring(0, separator).trim();
      final rawValue = _stripInlineComment(
        normalized.substring(separator + 1).trim(),
      );
      if (key.isEmpty) {
        continue;
      }
      values[key] = _stripOptionalQuotes(rawValue);
    }
    return values;
  }

  static String _stripInlineComment(String value) {
    var inSingleQuote = false;
    var inDoubleQuote = false;
    for (var index = 0; index < value.length; index += 1) {
      final character = value[index];
      if (character == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
      } else if (character == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
      } else if (character == '#' && !inSingleQuote && !inDoubleQuote) {
        return value.substring(0, index).trimRight();
      }
    }
    return value;
  }

  static String _stripOptionalQuotes(String value) {
    if (value.length < 2) {
      return value;
    }
    final first = value[0];
    final last = value[value.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}

class OpenAiAppearanceAnalysisService implements AppearanceAnalysisService {
  OpenAiAppearanceAnalysisService({
    OpenAiConfigLoader configLoader = const DotEnvOpenAiConfigLoader(),
    OpenAiJsonPost? postJson,
    Uri? endpoint,
  })  : _configLoader = configLoader,
        _postJson = postJson ?? _postJsonWithHttpClient,
        _endpoint =
            endpoint ?? Uri.https('api.openai.com', '/v1/chat/completions');

  final OpenAiConfigLoader _configLoader;
  final OpenAiJsonPost _postJson;
  final Uri _endpoint;

  static String formatOpenAiErrorForTest(int statusCode, Object? decoded) {
    return _formatOpenAiError(statusCode, decoded);
  }

  @override
  Future<AppearanceAnalysis> analyzeStill(File imageFile) async {
    final config = await _configLoader.load();
    final imageBytes = await imageFile.readAsBytes();
    final response = await _postJson(
      _endpoint,
      {
        HttpHeaders.authorizationHeader: 'Bearer ${config.apiKey}',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      _buildRequestBody(config.model, imageBytes),
    );
    return _parseResponse(response);
  }

  Map<String, Object?> _buildRequestBody(String model, Uint8List imageBytes) {
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
    return {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': _systemPrompt,
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': _userPrompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': dataUrl,
                'detail': 'high',
              },
            },
          ],
        },
      ],
      'response_format': {
        'type': 'json_schema',
        'json_schema': {
          'name': 'appearance_analysis',
          'strict': true,
          'schema': _responseSchema,
        },
      },
    };
  }

  AppearanceAnalysis _parseResponse(Map<String, Object?> response) {
    final choices = response['choices'];
    if (choices is! List || choices.isEmpty) {
      throw AppearanceAnalysisException('OpenAI returned no analysis choices.');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, Object?>) {
      throw AppearanceAnalysisException('OpenAI returned an invalid choice.');
    }

    final message = firstChoice['message'];
    if (message is! Map<String, Object?>) {
      throw AppearanceAnalysisException('OpenAI returned no message.');
    }

    final content = message['content'];
    if (content is! String || content.isEmpty) {
      throw AppearanceAnalysisException('OpenAI returned an empty analysis.');
    }

    final decoded = jsonDecode(_stripJsonFence(content));
    if (decoded is! Map<String, Object?>) {
      throw AppearanceAnalysisException('OpenAI returned invalid JSON.');
    }
    return AppearanceAnalysis.fromJson(decoded);
  }

  static String _stripJsonFence(String content) {
    final trimmed = content.trim();
    if (!trimmed.startsWith('```')) {
      return trimmed;
    }

    final firstNewline = trimmed.indexOf('\n');
    final lastFence = trimmed.lastIndexOf('```');
    if (firstNewline < 0 || lastFence <= firstNewline) {
      return trimmed;
    }
    return trimmed.substring(firstNewline + 1, lastFence).trim();
  }

  static Future<Map<String, Object?>> _postJsonWithHttpClient(
    Uri endpoint,
    Map<String, String> headers,
    Map<String, Object?> body,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(endpoint);
      for (final header in headers.entries) {
        request.headers.set(header.key, header.value);
      }
      request.write(jsonEncode(body));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(responseBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppearanceAnalysisException(
          _formatOpenAiError(response.statusCode, decoded),
        );
      }
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      throw AppearanceAnalysisException('OpenAI returned invalid JSON.');
    } on FormatException catch (error) {
      throw AppearanceAnalysisException(
        'OpenAI returned a response that could not be decoded: $error',
      );
    } finally {
      client.close(force: true);
    }
  }

  static String _formatOpenAiError(int statusCode, Object? decoded) {
    final detail = _openAiErrorMessage(decoded);
    if (detail == null || detail.isEmpty) {
      return 'OpenAI request failed with HTTP $statusCode.';
    }
    return 'OpenAI request failed with HTTP $statusCode: '
        '${_redactSecretFragments(detail)}';
  }

  static String? _openAiErrorMessage(Object? decoded) {
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    final error = decoded['error'];
    if (error is Map<String, Object?>) {
      final message = error['message'];
      if (message is String) {
        return message;
      }
    }
    return null;
  }

  static String _redactSecretFragments(String message) {
    return message.replaceAll(RegExp(r'sk-[A-Za-z0-9_-]+'), 'sk-...');
  }
}

const _systemPrompt = '''
You analyze a single camera still for a virtual mirror app.
Describe only visible appearance, presentation, styling, grooming, clothing,
posture, expression, and context cues. Provide likely occupation and likely
professional seniority impressions when the image contains cues, but frame them
as appearance-based impressions rather than verified facts. It is acceptable to
say someone gives an executive, service, creative, technical, junior, senior,
tidy, frumpy, elegant, stylish, creepy, or unsettling impression when visible
cues support that impression.

Do not identify the person. Do not claim to know protected traits, exact age,
health, religion, ethnicity, nationality, sexuality, disability, or actual job.
When evidence is weak, say so clearly.
''';

const _userPrompt = '''
Give a detailed appearance-focused description of the person in this still.
Focus on tidiness, grooming, clothing, polish, style, elegance, frumpiness,
creepiness or unsettling cues, confidence, apparent professionalism, likely
occupation signals, and likely professional seniority signals. Return detailed
but careful language.
''';

const _responseSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': [
    'overallDescription',
    'visibleAppearance',
    'groomingAndTidiness',
    'clothingAndAccessories',
    'styleAndPresentation',
    'demeanorAndVibe',
    'likelyOccupationSignals',
    'likelySenioritySignals',
    'impressionLabels',
    'uncertaintyNotes',
  ],
  'properties': {
    'overallDescription': {'type': 'string'},
    'visibleAppearance': {'type': 'string'},
    'groomingAndTidiness': {'type': 'string'},
    'clothingAndAccessories': {'type': 'string'},
    'styleAndPresentation': {'type': 'string'},
    'demeanorAndVibe': {'type': 'string'},
    'likelyOccupationSignals': {'type': 'string'},
    'likelySenioritySignals': {'type': 'string'},
    'impressionLabels': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'uncertaintyNotes': {'type': 'string'},
  },
};

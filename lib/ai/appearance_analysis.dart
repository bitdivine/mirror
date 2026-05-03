import 'dart:io';

class AppearanceAnalysis {
  const AppearanceAnalysis({
    required this.overallDescription,
    required this.visibleAppearance,
    required this.groomingAndTidiness,
    required this.clothingAndAccessories,
    required this.styleAndPresentation,
    required this.demeanorAndVibe,
    required this.likelyOccupationSignals,
    required this.likelySenioritySignals,
    required this.impressionLabels,
    required this.uncertaintyNotes,
  });

  factory AppearanceAnalysis.fromJson(Map<String, Object?> json) {
    return AppearanceAnalysis(
      overallDescription: _requiredString(json, 'overallDescription'),
      visibleAppearance: _requiredString(json, 'visibleAppearance'),
      groomingAndTidiness: _requiredString(json, 'groomingAndTidiness'),
      clothingAndAccessories: _requiredString(json, 'clothingAndAccessories'),
      styleAndPresentation: _requiredString(json, 'styleAndPresentation'),
      demeanorAndVibe: _requiredString(json, 'demeanorAndVibe'),
      likelyOccupationSignals: _requiredString(
        json,
        'likelyOccupationSignals',
      ),
      likelySenioritySignals: _requiredString(json, 'likelySenioritySignals'),
      impressionLabels: _requiredStringList(json, 'impressionLabels'),
      uncertaintyNotes: _requiredString(json, 'uncertaintyNotes'),
    );
  }

  final String overallDescription;
  final String visibleAppearance;
  final String groomingAndTidiness;
  final String clothingAndAccessories;
  final String styleAndPresentation;
  final String demeanorAndVibe;
  final String likelyOccupationSignals;
  final String likelySenioritySignals;
  final List<String> impressionLabels;
  final String uncertaintyNotes;

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw AppearanceAnalysisException('OpenAI response omitted $key.');
  }

  static List<String> _requiredStringList(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    throw AppearanceAnalysisException('OpenAI response omitted $key.');
  }
}

abstract class AppearanceAnalysisService {
  Future<AppearanceAnalysis> analyzeStill(File imageFile);
}

class AppearanceAnalysisException implements Exception {
  AppearanceAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Local Gemini credentials for VitalReach AI health chat.
/// Prefer --dart-define=GEMINI_API_KEY=... (do not commit real keys).
class GeminiSecrets {
  GeminiSecrets._();

  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String projectName = 'skh20276';
  static const String projectId = 'projects/297831985629';
}

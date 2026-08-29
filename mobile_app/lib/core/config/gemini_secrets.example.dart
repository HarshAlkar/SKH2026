/// Copy to gemini_secrets.dart and fill in your key.
/// Do not commit real keys.
class GeminiSecrets {
  GeminiSecrets._();

  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String projectName = 'your-project-name';
  static const String projectId = 'projects/your-project-number';
}

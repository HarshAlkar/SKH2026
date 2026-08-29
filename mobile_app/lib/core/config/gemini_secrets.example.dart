/// Example only — do not put real Gemini keys in the Flutter app.
/// Prefer server-side GEMINI_API_KEY on Django and POST /api/ai/gemini-chat/.
class GeminiSecrets {
  GeminiSecrets._();

  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}

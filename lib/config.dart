/// Build time configuration.
///
/// Run the app with your OpenAI key like this (never commit the key):
///
///   flutter run --dart-define=OPENAI_API_KEY=sk-...
///
/// or put it in a local file and use --dart-define-from-file=env.json
/// (env.json is already listed in .gitignore). See README.md.
class AppConfig {
  static const openAiKey = String.fromEnvironment('OPENAI_API_KEY');

  /// Models can be changed without touching code.
  static const transcribeModel = String.fromEnvironment('OPENAI_TRANSCRIBE_MODEL', defaultValue: 'whisper-1');
  static const chatModel = String.fromEnvironment('OPENAI_CHAT_MODEL', defaultValue: 'gpt-4o-mini');
  static const speechModel = String.fromEnvironment('OPENAI_TTS_MODEL', defaultValue: 'tts-1');

  /// Optional: a JSON file describing the newest band firmware, for example
  /// {"version":"1.1.0","notes":["Clearer audio"],"url":"https://.../firmware.bin"}
  static const firmwareManifestUrl = String.fromEnvironment('FIRMWARE_MANIFEST_URL');

  static bool get hasOpenAiKey => openAiKey.trim().isNotEmpty;
}

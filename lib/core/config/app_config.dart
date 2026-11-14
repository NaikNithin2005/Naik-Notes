/// Application configuration and environment profiles.
class AppConfig {
  AppConfig._();

  static const String appName = 'Naik Notes';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your Cross-Platform Digital Notebook';

  // Network and API
  static const String devApiBaseUrl = 'http://localhost:8000/v1';
  static const String prodApiBaseUrl = 'https://api.naiknotes.com/v1';

  // Feature flags
  static const bool enableAiAssistant = true;
  static const bool enableAudioRecording = true;
  static const bool enableCloudSync = true;
  static const bool enableVectorSmoothing = true;

  // Defaults
  static const double defaultPageWidth = 595.28; // Standard A4 points (72 DPI)
  static const double defaultPageHeight = 841.89;
  static const double minZoom = 0.5;
  static const double maxZoom = 5.0;
}

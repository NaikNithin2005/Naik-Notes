/// Core constants used across the application.
class AppConstants {
  AppConstants._();

  // Layout breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  // Local storage keys
  static const String keyAuthToken = 'naik_auth_token';
  static const String keyDeviceId = 'naik_device_id';
  static const String keyThemeMode = 'naik_theme_mode';
  static const String keyLastSync = 'naik_last_sync_timestamp';

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 350);
  static const Duration pageTurnDuration = Duration(milliseconds: 400);

  // Default pen presets
  static const List<double> penWidthPresets = [1.0, 2.0, 3.5, 5.0, 8.0];
  static const List<double> highlighterWidthPresets = [12.0, 18.0, 24.0];
}

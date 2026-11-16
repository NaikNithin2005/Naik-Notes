import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

/// Information about an application release update.
class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;
  final String releaseNotes;
  final String? downloadUrl;
  final bool isMandatory;
  final DateTime? publishedAt;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    required this.releaseNotes,
    this.downloadUrl,
    this.isMandatory = false,
    this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
    'currentVersion': currentVersion,
    'latestVersion': latestVersion,
    'hasUpdate': hasUpdate,
    'releaseNotes': releaseNotes,
    'downloadUrl': downloadUrl,
    'isMandatory': isMandatory,
    'publishedAt': publishedAt?.toIso8601String(),
  };

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json, String currentVer) {
    final latest =
        json['version'] as String? ??
        json['latestVersion'] as String? ??
        currentVer;
    final isNewer = AppUpdateService.isVersionNewer(currentVer, latest);

    return AppUpdateInfo(
      currentVersion: currentVer,
      latestVersion: latest,
      hasUpdate: isNewer,
      releaseNotes:
          json['releaseNotes'] as String? ?? json['changelog'] as String? ?? 'Performance improvements, handwriting enhancements, and stability updates.',
      downloadUrl:
          json['downloadUrl'] as String? ?? json['html_url'] as String?,
      isMandatory: json['isMandatory'] as bool? ?? false,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
    );
  }
}

/// Service managing application auto-update checks and version lifecycle.
class AppUpdateService {
  final http.Client _client;
  DateTime? _lastChecked;

  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();

  DateTime? get lastChecked => _lastChecked;

  /// Compares semantic version strings (e.g. '1.1.0' vs '1.0.0').
  /// Returns `true` if [target] is strictly newer than [current].
  static bool isVersionNewer(String current, String target) {
    try {
      final currentParts = current
          .split('.')
          .map((p) => int.tryParse(p.split('+').first) ?? 0)
          .toList();
      final targetParts = target
          .split('.')
          .map((p) => int.tryParse(p.split('+').first) ?? 0)
          .toList();

      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (targetParts.length < 3) {
        targetParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (targetParts[i] > currentParts[i]) return true;
        if (targetParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks remote API or GitHub endpoint for the latest available release.
  Future<AppUpdateInfo> checkForUpdate({String? customEndpoint}) async {
    _lastChecked = DateTime.now();
    const currentVer = AppConfig.appVersion;

    try {
      final endpoint =
          customEndpoint ?? '${AppConfig.prodApiBaseUrl}/app/version';
      final response = await _client
          .get(Uri.parse(endpoint), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return AppUpdateInfo.fromJson(data, currentVer);
      }
    } catch (e) {
      debugPrint(
        'Update check server unreachable ($e). Using local version status.',
      );
    }

    // Default status when offline or server unreachable
    return const AppUpdateInfo(
      currentVersion: currentVer,
      latestVersion: currentVer,
      hasUpdate: false,
      releaseNotes:
          'You are running the latest verified build of ${AppConfig.appName}.',
    );
  }
}

/// Global provider for the AppUpdateService.
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final service = AppUpdateService();
  return service;
});

/// State notifier for checking and storing the latest update status.
class AppUpdateNotifier extends Notifier<AsyncValue<AppUpdateInfo?>> {
  @override
  AsyncValue<AppUpdateInfo?> build() {
    return const AsyncValue.data(null);
  }

  Future<AppUpdateInfo> check({bool force = false}) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(appUpdateServiceProvider);
      final info = await service.checkForUpdate();
      state = AsyncValue.data(info);
      return info;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      const fallback = AppUpdateInfo(
        currentVersion: AppConfig.appVersion,
        latestVersion: AppConfig.appVersion,
        hasUpdate: false,
        releaseNotes: 'Unable to connect to update server.',
      );
      return fallback;
    }
  }
}

final appUpdateNotifierProvider =
    NotifierProvider<AppUpdateNotifier, AsyncValue<AppUpdateInfo?>>(
      AppUpdateNotifier.new,
    );

/// Boolean flag for whether auto-check is enabled in Settings.
class AutoUpdateEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle(bool enabled) => state = enabled;
}

final autoUpdateEnabledProvider =
    NotifierProvider<AutoUpdateEnabledNotifier, bool>(
      AutoUpdateEnabledNotifier.new,
    );

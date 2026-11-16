import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naik_notes/services/update/app_update_service.dart';

void main() {
  group('AppUpdateService Semantic Version Comparison Tests', () {
    test('accurately identifies newer minor and patch releases', () {
      expect(AppUpdateService.isVersionNewer('1.0.0', '1.0.1'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.0.0', '1.1.0'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.0.0', '2.0.0'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.2.3', '1.2.4'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.2.3', '1.3.0'), isTrue);
    });

    test('accurately returns false for equal or older versions', () {
      expect(AppUpdateService.isVersionNewer('1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateService.isVersionNewer('1.1.0', '1.0.0'), isFalse);
      expect(AppUpdateService.isVersionNewer('2.0.0', '1.9.9'), isFalse);
      expect(AppUpdateService.isVersionNewer('1.0.1', '1.0.0'), isFalse);
    });

    test('handles build metadata and prefixes gracefully', () {
      expect(AppUpdateService.isVersionNewer('1.0.0+1', '1.0.1+2'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.0.0', '1.0.0+2'), isFalse);
    });
  });

  group('AppUpdateService API & JSON Parsing Tests', () {
    test(
      'parses remote update manifest and marks hasUpdate correctly',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            json.encode({
              'version': '1.1.0',
              'releaseNotes':
                  'Added advanced shape drawing and unlimited pages.',
              'downloadUrl': 'https://github.com/naiknotes/releases/v1.1.0.apk',
              'isMandatory': false,
              'publishedAt': '2026-11-16T12:00:00Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = AppUpdateService(client: mockClient);
        final updateInfo = await service.checkForUpdate(
          customEndpoint: 'https://test.naiknotes.com/version',
        );

        expect(updateInfo.hasUpdate, isTrue);
        expect(updateInfo.latestVersion, '1.1.0');
        expect(
          updateInfo.downloadUrl,
          'https://github.com/naiknotes/releases/v1.1.0.apk',
        );
        expect(updateInfo.releaseNotes, contains('advanced shape drawing'));
      },
    );

    test('returns non-blocking fallback when remote server returns error or is offline', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = AppUpdateService(client: mockClient);
      final updateInfo = await service.checkForUpdate(
        customEndpoint: 'https://test.naiknotes.com/version',
      );

      expect(updateInfo.hasUpdate, isFalse);
      expect(updateInfo.currentVersion, updateInfo.latestVersion);
      expect(updateInfo.releaseNotes, isNotEmpty);
    });
  });

  group('Riverpod Notifier State Tests', () {
    test('AppUpdateNotifier and AutoUpdateEnabledNotifier handle state transitions', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(autoUpdateEnabledProvider), isTrue);

      container.read(autoUpdateEnabledProvider.notifier).toggle(false);
      expect(container.read(autoUpdateEnabledProvider), isFalse);

      final notifier = container.read(appUpdateNotifierProvider.notifier);
      final info = await notifier.check();
      expect(info, isNotNull);
      expect(container.read(appUpdateNotifierProvider).value, isNotNull);
    });
  });
}

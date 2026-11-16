import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/core/diagnostics/performance_monitor.dart';

void main() {
  group('AppPerformanceMonitor Tests', () {
    setUp(() {
      AppPerformanceMonitor.clearHistory();
    });

    test('trace records successful operation with positive duration', () async {
      final result = await AppPerformanceMonitor.trace('test_async_op', () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 42;
      });

      expect(result, 42);
      expect(AppPerformanceMonitor.history.length, 1);
      final record = AppPerformanceMonitor.history.first;
      expect(record.name, 'test_async_op');
      expect(record.isSuccess, isTrue);
      expect(record.milliseconds, greaterThanOrEqualTo(5));
      expect(record.error, isNull);
    });

    test('trace records failed operation and rethrows exception', () async {
      await expectLater(
        AppPerformanceMonitor.trace('failing_op', () async {
          throw Exception('network failure');
        }),
        throwsException,
      );

      expect(AppPerformanceMonitor.history.length, 1);
      final record = AppPerformanceMonitor.history.first;
      expect(record.name, 'failing_op');
      expect(record.isSuccess, isFalse);
      expect(record.error, contains('network failure'));
    });

    test('traceSync measures synchronous operation', () {
      final sum = AppPerformanceMonitor.traceSync('compute_sum', () {
        var total = 0;
        for (var i = 0; i < 1000; i++) {
          total += i;
        }
        return total;
      });

      expect(sum, 499500);
      expect(AppPerformanceMonitor.history.length, 1);
      expect(AppPerformanceMonitor.history.first.name, 'compute_sum');
      expect(AppPerformanceMonitor.history.first.isSuccess, isTrue);
    });

    test('getAverageLatency calculates correct mean latency', () async {
      await AppPerformanceMonitor.trace('repeated_op', () async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      });
      await AppPerformanceMonitor.trace('repeated_op', () async {
        await Future<void>.delayed(const Duration(milliseconds: 15));
      });

      final avg = AppPerformanceMonitor.getAverageLatency('repeated_op');
      expect(avg, greaterThanOrEqualTo(5.0));
      expect(AppPerformanceMonitor.getAverageLatency('non_existent'), 0.0);
    });

    test('clearHistory empties the recorded metrics', () async {
      await AppPerformanceMonitor.trace('op1', () async => 1);
      expect(AppPerformanceMonitor.history, isNotEmpty);
      AppPerformanceMonitor.clearHistory();
      expect(AppPerformanceMonitor.history, isEmpty);
    });
  });
}

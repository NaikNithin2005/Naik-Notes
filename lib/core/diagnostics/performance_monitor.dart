import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance record capturing duration and metadata of an instrumented operation.
class PerformanceRecord {
  final String name;
  final Duration duration;
  final DateTime timestamp;
  final bool isSuccess;
  final String? error;

  const PerformanceRecord({
    required this.name,
    required this.duration,
    required this.timestamp,
    required this.isSuccess,
    this.error,
  });

  int get milliseconds => duration.inMilliseconds;

  @override
  String toString() =>
      '[PERF] $name: ${milliseconds}ms (${isSuccess ? 'OK' : 'FAILED: $error'})';
}

/// Centralized diagnostic performance monitor and latency tracer for Naik Notes.
///
/// Measures execution time for authentication, database loading, stroke rendering,
/// network synchronization, and page transitions with sub-millisecond precision.
class AppPerformanceMonitor {
  AppPerformanceMonitor._();

  static final List<PerformanceRecord> _history = [];
  static const int _maxHistoryLength = 200;

  /// Returns an unmodifiable list of recent performance records.
  static List<PerformanceRecord> get history => List.unmodifiable(_history);

  /// Synchronous or asynchronous tracing helper.
  /// Measures elapsed execution time and logs structured metrics.
  static Future<T> trace<T>(
    String operationName,
    Future<T> Function() action,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();
      _record(
        PerformanceRecord(
          name: operationName,
          duration: stopwatch.elapsed,
          timestamp: DateTime.now(),
          isSuccess: true,
        ),
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      _record(
        PerformanceRecord(
          name: operationName,
          duration: stopwatch.elapsed,
          timestamp: DateTime.now(),
          isSuccess: false,
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Synchronous tracing helper for non-async calculations.
  static T traceSync<T>(String operationName, T Function() action) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = action();
      stopwatch.stop();
      _record(
        PerformanceRecord(
          name: operationName,
          duration: stopwatch.elapsed,
          timestamp: DateTime.now(),
          isSuccess: true,
        ),
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      _record(
        PerformanceRecord(
          name: operationName,
          duration: stopwatch.elapsed,
          timestamp: DateTime.now(),
          isSuccess: false,
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  static void _record(PerformanceRecord record) {
    if (_history.length >= _maxHistoryLength) {
      _history.removeAt(0);
    }
    _history.add(record);

    if (kDebugMode) {
      debugPrint(record.toString());
    }
  }

  /// Calculates average latency for a given operation name in milliseconds.
  static double getAverageLatency(String operationName) {
    final matching = _history.where((r) => r.name == operationName && r.isSuccess);
    if (matching.isEmpty) return 0.0;
    final totalMs = matching.fold<int>(0, (sum, r) => sum + r.milliseconds);
    return totalMs / matching.length;
  }

  /// Clears collected diagnostic history.
  static void clearHistory() {
    _history.clear();
  }
}


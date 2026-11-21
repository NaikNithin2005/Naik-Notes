import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Type of activity performed on a note/notebook.
enum NoteActionType {
  created,
  updated,
  deleted,
}

/// Represents an individual note audit trail record tracking who did what, when, and on which device.
@immutable
class NoteActivityEntry {
  final String id;
  final String noteId;
  final String noteTitle;
  final NoteActionType action;
  final DateTime timestamp;
  final String deviceName;
  final String userEmail;
  final String details;

  const NoteActivityEntry({
    required this.id,
    required this.noteId,
    required this.noteTitle,
    required this.action,
    required this.timestamp,
    required this.deviceName,
    required this.userEmail,
    this.details = '',
  });

  String get formattedDateTime {
    final y = timestamp.year;
    final m = timestamp.month.toString().padLeft(2, '0');
    final d = timestamp.day.toString().padLeft(2, '0');
    final h = timestamp.hour.toString().padLeft(2, '0');
    final min = timestamp.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'noteId': noteId,
    'noteTitle': noteTitle,
    'action': action.name,
    'timestamp': timestamp.toIso8601String(),
    'deviceName': deviceName,
    'userEmail': userEmail,
    'details': details,
  };

  factory NoteActivityEntry.fromJson(Map<String, dynamic> json) => NoteActivityEntry(
    id: json['id'] as String? ?? const Uuid().v4(),
    noteId: json['noteId'] as String? ?? '',
    noteTitle: json['noteTitle'] as String? ?? 'Untitled Note',
    action: NoteActionType.values.firstWhere(
      (a) => a.name == (json['action'] as String?),
      orElse: () => NoteActionType.updated,
    ),
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    deviceName: json['deviceName'] as String? ?? 'Local Device',
    userEmail: json['userEmail'] as String? ?? 'Local User',
    details: json['details'] as String? ?? '',
  );
}

/// Service managing persistent note audit history across local storage and Google Drive cloud sync.
class NoteHistoryService {
  static const String _fileName = 'naik_notes_history.json';
  static const int _maxEntries = 500;
  final Uuid _uuid = const Uuid();

  List<NoteActivityEntry> _cache = [];
  bool _isLoaded = false;
  File? _cachedFile;

  static String get currentDeviceName {
    if (kIsWeb) return 'Web Browser';
    try {
      if (Platform.isWindows) {
        final host = Platform.localHostname;
        return host.isNotEmpty ? 'Windows PC ($host)' : 'Windows 10/11 PC';
      }
      if (Platform.isAndroid) return 'Android Device';
      if (Platform.isIOS) return 'iPad / Apple Device';
      if (Platform.isMacOS) return 'macOS Workstation';
      if (Platform.isLinux) return 'Linux Workstation';
    } catch (_) {}
    return 'Local Device';
  }

  Future<File> _getFile() async {
    if (_cachedFile != null) return _cachedFile!;
    try {
      final name = WidgetsBinding.instance.runtimeType.toString();
      if (name.contains('Test') || name.contains('Binding')) {
        // In tests, avoid platform channel
        _cachedFile = File(_fileName);
        return _cachedFile!;
      }
      final dir = await getApplicationDocumentsDirectory();
      _cachedFile = File('${dir.path}/$_fileName');
    } catch (_) {
      _cachedFile = File(_fileName);
    }
    return _cachedFile!;
  }

  /// Loads all local activity records.
  Future<List<NoteActivityEntry>> getHistory() async {
    if (_isLoaded) return List.unmodifiable(_cache);
    try {
      final file = await _getFile();
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final list = jsonDecode(content) as List<dynamic>;
        _cache = list
            .map((e) => NoteActivityEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        _sortCache();
      }
    } catch (e) {
      debugPrint('[NoteHistoryService] Load history note: $e');
    }
    _isLoaded = true;
    return List.unmodifiable(_cache);
  }

  /// Records a new note event (creation, update, deletion) with current timestamp, device, and user.
  Future<NoteActivityEntry> recordActivity({
    required String noteId,
    required String noteTitle,
    required NoteActionType action,
    required String userEmail,
    String? deviceName,
    String? details,
  }) async {
    await getHistory(); // Ensure cache is warm

    final entry = NoteActivityEntry(
      id: _uuid.v4(),
      noteId: noteId,
      noteTitle: noteTitle,
      action: action,
      timestamp: DateTime.now(),
      deviceName: deviceName ?? currentDeviceName,
      userEmail: userEmail.isNotEmpty ? userEmail : 'Local User',
      details: details ?? _defaultDetails(action, noteTitle),
    );

    _cache.insert(0, entry);
    if (_cache.length > _maxEntries) {
      _cache = _cache.sublist(0, _maxEntries);
    }

    await _saveLocal();
    return entry;
  }

  /// Merges remote activity entries retrieved from Google Drive with local history.
  Future<List<NoteActivityEntry>> mergeCloudHistory(
    List<NoteActivityEntry> cloudEntries,
  ) async {
    await getHistory();
    final existingIds = _cache.map((e) => e.id).toSet();

    bool hasNew = false;
    for (final remote in cloudEntries) {
      if (!existingIds.contains(remote.id)) {
        _cache.add(remote);
        existingIds.add(remote.id);
        hasNew = true;
      }
    }

    if (hasNew) {
      _sortCache();
      if (_cache.length > _maxEntries) {
        _cache = _cache.sublist(0, _maxEntries);
      }
      await _saveLocal();
    }

    return List.unmodifiable(_cache);
  }

  /// Returns JSON-encoded string for uploading to Google Drive backup metadata.
  Future<String> exportJson() async {
    final history = await getHistory();
    final list = history.map((e) => e.toJson()).toList();
    return jsonEncode(list);
  }

  void _sortCache() {
    _cache.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _saveLocal() async {
    try {
      final file = await _getFile();
      final list = _cache.map((e) => e.toJson()).toList();
      file.writeAsStringSync(jsonEncode(list), flush: true);
    } catch (e) {
      debugPrint('[NoteHistoryService] Failed to save local history: $e');
    }
  }

  String _defaultDetails(NoteActionType action, String title) {
    switch (action) {
      case NoteActionType.created:
        return 'Created notebook "$title"';
      case NoteActionType.updated:
        return 'Updated notebook "$title"';
      case NoteActionType.deleted:
        return 'Deleted notebook "$title"';
    }
  }
}

/// Global provider for the NoteHistoryService singleton.
final noteHistoryServiceProvider = Provider<NoteHistoryService>((ref) {
  return NoteHistoryService();
});

/// Reactive state notifier providing the stream/list of activity records for the UI.
class NoteHistoryNotifier extends Notifier<List<NoteActivityEntry>> {
  NoteHistoryService get _service => ref.read(noteHistoryServiceProvider);

  @override
  List<NoteActivityEntry> build() {
    ref.watch(noteHistoryServiceProvider);
    Future.microtask(() => refresh());
    return const [];
  }

  Future<void> refresh() async {
    state = await _service.getHistory();
  }

  Future<void> record({
    required String noteId,
    required String noteTitle,
    required NoteActionType action,
    required String userEmail,
    String? details,
  }) async {
    await _service.recordActivity(
      noteId: noteId,
      noteTitle: noteTitle,
      action: action,
      userEmail: userEmail,
      details: details,
    );
    state = await _service.getHistory();
  }
}

/// Global provider watching note history records.
final noteHistoryProvider =
    NotifierProvider<NoteHistoryNotifier, List<NoteActivityEntry>>(
  NoteHistoryNotifier.new,
);


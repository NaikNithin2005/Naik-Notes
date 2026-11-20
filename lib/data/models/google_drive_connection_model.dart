import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a user's linked Google Drive storage account metadata
/// stored at `users/{uid}/integrations/googleDrive`.
///
/// NOTE: OAuth tokens, secrets, and refresh credentials are NEVER saved in Firestore;
/// they are maintained exclusively in platform-native secure storage.
class GoogleDriveConnectionModel {
  final String provider;
  final bool connected;
  final String? googleAccountEmail;
  final String? googleAccountSubjectId;
  final DateTime? connectedAt;
  final DateTime? lastVerifiedAt;
  final String storageProvider;
  final int schemaVersion;

  const GoogleDriveConnectionModel({
    this.provider = 'google_drive',
    this.connected = false,
    this.googleAccountEmail,
    this.googleAccountSubjectId,
    this.connectedAt,
    this.lastVerifiedAt,
    this.storageProvider = 'google_drive_appdata',
    this.schemaVersion = 1,
  });

  GoogleDriveConnectionModel copyWith({
    String? provider,
    bool? connected,
    String? googleAccountEmail,
    String? googleAccountSubjectId,
    DateTime? connectedAt,
    DateTime? lastVerifiedAt,
    String? storageProvider,
    int? schemaVersion,
  }) {
    return GoogleDriveConnectionModel(
      provider: provider ?? this.provider,
      connected: connected ?? this.connected,
      googleAccountEmail: googleAccountEmail ?? this.googleAccountEmail,
      googleAccountSubjectId:
          googleAccountSubjectId ?? this.googleAccountSubjectId,
      connectedAt: connectedAt ?? this.connectedAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      storageProvider: storageProvider ?? this.storageProvider,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'provider': provider,
      'connected': connected,
      'googleAccountEmail': googleAccountEmail,
      'googleAccountSubjectId': googleAccountSubjectId,
      'connectedAt':
          connectedAt != null ? Timestamp.fromDate(connectedAt!) : null,
      'lastVerifiedAt':
          lastVerifiedAt != null ? Timestamp.fromDate(lastVerifiedAt!) : null,
      'storageProvider': storageProvider,
      'schemaVersion': schemaVersion,
    };
  }

  factory GoogleDriveConnectionModel.fromFirestore(Map<String, dynamic> data) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return GoogleDriveConnectionModel(
      provider: data['provider'] as String? ?? 'google_drive',
      connected: data['connected'] as bool? ?? false,
      googleAccountEmail: data['googleAccountEmail'] as String?,
      googleAccountSubjectId: data['googleAccountSubjectId'] as String?,
      connectedAt: parseTimestamp(data['connectedAt']),
      lastVerifiedAt: parseTimestamp(data['lastVerifiedAt']),
      storageProvider:
          data['storageProvider'] as String? ?? 'google_drive_appdata',
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'connected': connected,
      'googleAccountEmail': googleAccountEmail,
      'googleAccountSubjectId': googleAccountSubjectId,
      'connectedAt': connectedAt?.toIso8601String(),
      'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
      'storageProvider': storageProvider,
      'schemaVersion': schemaVersion,
    };
  }

  factory GoogleDriveConnectionModel.fromJson(Map<String, dynamic> json) {
    return GoogleDriveConnectionModel(
      provider: json['provider'] as String? ?? 'google_drive',
      connected: json['connected'] as bool? ?? false,
      googleAccountEmail: json['googleAccountEmail'] as String?,
      googleAccountSubjectId: json['googleAccountSubjectId'] as String?,
      connectedAt: json['connectedAt'] != null
          ? DateTime.tryParse(json['connectedAt'] as String)
          : null,
      lastVerifiedAt: json['lastVerifiedAt'] != null
          ? DateTime.tryParse(json['lastVerifiedAt'] as String)
          : null,
      storageProvider:
          json['storageProvider'] as String? ?? 'google_drive_appdata',
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }
}

import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../models/attachment_model.dart';

/// Repository managing local SQLite persistence of attachments via Drift.
class AttachmentRepository {
  final AppDatabase _db;

  AttachmentRepository(this._db);

  /// Converts a Drift [AttachmentsTableData] entity into a domain [NoteAttachment].
  NoteAttachment _toDomain(AttachmentsTableData row) {
    return NoteAttachment(
      attachmentId: row.id,
      ownerId: row.ownerId,
      noteId: row.noteId,
      driveFileId: row.driveFileId,
      fileName: row.fileName,
      mimeType: row.mimeType,
      fileSize: row.fileSize,
      localPath: row.localPath,
      checksum: row.checksum,
      storageProvider: row.storageProvider,
      uploadStatus: row.uploadStatus,
      isDeleted: row.isDeleted,
      retryCount: row.retryCount,
      lastError: row.lastError,
      createdAt: row.createdAt,
      uploadedAt: row.uploadedAt,
    );
  }

  /// Inserts or updates an attachment in the local SQLite database.
  Future<void> saveAttachment(NoteAttachment attachment) async {
    final companion = AttachmentsTableCompanion(
      id: Value(attachment.attachmentId),
      ownerId: Value(attachment.ownerId),
      noteId: Value(attachment.noteId),
      driveFileId: Value(attachment.driveFileId),
      fileName: Value(attachment.fileName),
      mimeType: Value(attachment.mimeType),
      fileSize: Value(attachment.fileSize),
      localPath: Value(attachment.localPath),
      checksum: Value(attachment.checksum),
      storageProvider: Value(attachment.storageProvider),
      uploadStatus: Value(attachment.uploadStatus),
      isDeleted: Value(attachment.isDeleted),
      retryCount: Value(attachment.retryCount),
      lastError: Value(attachment.lastError),
      createdAt: Value(attachment.createdAt),
      uploadedAt: Value(attachment.uploadedAt),
      updatedAt: Value(DateTime.now()),
    );

    await _db.into(_db.attachmentsTable).insertOnConflictUpdate(companion);
  }

  /// Retrieves an attachment by its unique [attachmentId].
  Future<NoteAttachment?> getAttachment(String attachmentId) async {
    final query = _db.select(_db.attachmentsTable)
      ..where((tbl) => tbl.id.equals(attachmentId));
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  /// Retrieves all non-deleted attachments associated with [noteId].
  Future<List<NoteAttachment>> getAttachmentsForNote(String noteId) async {
    final query = _db.select(_db.attachmentsTable)
      ..where((tbl) => tbl.noteId.equals(noteId) & tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  /// Watches real-time changes to attachments for [noteId].
  Stream<List<NoteAttachment>> watchAttachmentsForNote(String noteId) {
    final query = _db.select(_db.attachmentsTable)
      ..where((tbl) => tbl.noteId.equals(noteId) & tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  /// Retrieves all pending or failed attachments awaiting upload for [ownerId].
  Future<List<NoteAttachment>> getPendingUploads(String ownerId) async {
    final query = _db.select(_db.attachmentsTable)
      ..where(
        (tbl) =>
            tbl.ownerId.equals(ownerId) &
            tbl.isDeleted.equals(false) &
            (tbl.uploadStatus.equals(AttachmentUploadStatus.pending) |
                tbl.uploadStatus.equals(AttachmentUploadStatus.failed)),
      );
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  /// Updates the synchronization status and metadata of an attachment.
  Future<void> updateAttachmentStatus(
    String attachmentId,
    String status, {
    String? driveFileId,
    String? localPath,
    String? error,
    DateTime? uploadedAt,
  }) async {
    final updateQuery = _db.update(_db.attachmentsTable)
      ..where((tbl) => tbl.id.equals(attachmentId));

    await updateQuery.write(
      AttachmentsTableCompanion(
        uploadStatus: Value(status),
        driveFileId: driveFileId != null ? Value(driveFileId) : const Value.absent(),
        localPath: localPath != null ? Value(localPath) : const Value.absent(),
        lastError: error != null ? Value(error) : const Value.absent(),
        uploadedAt: uploadedAt != null ? Value(uploadedAt) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marks an attachment as pending deletion.
  Future<void> markAttachmentDeleted(String attachmentId) async {
    final query = _db.update(_db.attachmentsTable)
      ..where((tbl) => tbl.id.equals(attachmentId));
    await query.write(
      AttachmentsTableCompanion(
        isDeleted: const Value(true),
        uploadStatus: const Value(AttachmentUploadStatus.pending),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanently deletes an attachment record from SQLite.
  Future<void> deleteAttachmentPermanently(String attachmentId) async {
    final query = _db.delete(_db.attachmentsTable)
      ..where((tbl) => tbl.id.equals(attachmentId));
    await query.go();
  }

  /// Returns the total number of pending uploads for [ownerId].
  Future<int> getPendingUploadsCount(String ownerId) async {
    final count = countAll();
    final query = _db.selectOnly(_db.attachmentsTable)
      ..addColumns([count])
      ..where(
        _db.attachmentsTable.ownerId.equals(ownerId) &
            _db.attachmentsTable.isDeleted.equals(false) &
            _db.attachmentsTable.uploadStatus.equals(AttachmentUploadStatus.pending),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Returns the total number of failed uploads for [ownerId].
  Future<int> getFailedUploadsCount(String ownerId) async {
    final count = countAll();
    final query = _db.selectOnly(_db.attachmentsTable)
      ..addColumns([count])
      ..where(
        _db.attachmentsTable.ownerId.equals(ownerId) &
            _db.attachmentsTable.isDeleted.equals(false) &
            _db.attachmentsTable.uploadStatus.equals(AttachmentUploadStatus.failed),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }
}

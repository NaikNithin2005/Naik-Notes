// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FoldersTableTable extends FoldersTable
    with TableInfo<$FoldersTableTable, FoldersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_user'),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#8B4513'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    parentId,
    name,
    colorHex,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoldersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoldersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoldersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $FoldersTableTable createAlias(String alias) {
    return $FoldersTableTable(attachedDatabase, alias);
  }
}

class FoldersTableData extends DataClass
    implements Insertable<FoldersTableData> {
  final String id;
  final String ownerId;
  final String? parentId;
  final String name;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const FoldersTableData({
    required this.id,
    required this.ownerId,
    this.parentId,
    required this.name,
    required this.colorHex,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    map['color_hex'] = Variable<String>(colorHex);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  FoldersTableCompanion toCompanion(bool nullToAbsent) {
    return FoldersTableCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      colorHex: Value(colorHex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory FoldersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoldersTableData(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String>(colorHex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  FoldersTableData copyWith({
    String? id,
    String? ownerId,
    Value<String?> parentId = const Value.absent(),
    String? name,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => FoldersTableData(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
    colorHex: colorHex ?? this.colorHex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  FoldersTableData copyWithCompanion(FoldersTableCompanion data) {
    return FoldersTableData(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoldersTableData(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    parentId,
    name,
    colorHex,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoldersTableData &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class FoldersTableCompanion extends UpdateCompanion<FoldersTableData> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<String> colorHex;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const FoldersTableCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersTableCompanion.insert({
    required String id,
    this.ownerId = const Value.absent(),
    this.parentId = const Value.absent(),
    required String name,
    this.colorHex = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FoldersTableData> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String?>? parentId,
    Value<String>? name,
    Value<String>? colorHex,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return FoldersTableCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersTableCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotebooksTableTable extends NotebooksTable
    with TableInfo<$NotebooksTableTable, NotebooksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotebooksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_user'),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _coverIdMeta = const VerificationMeta(
    'coverId',
  );
  @override
  late final GeneratedColumn<String> coverId = GeneratedColumn<String>(
    'cover_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('classic_leather'),
  );
  static const VerificationMeta _coverColorHexMeta = const VerificationMeta(
    'coverColorHex',
  );
  @override
  late final GeneratedColumn<String> coverColorHex = GeneratedColumn<String>(
    'cover_color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#8B4513'),
  );
  static const VerificationMeta _coverImageUrlMeta = const VerificationMeta(
    'coverImageUrl',
  );
  @override
  late final GeneratedColumn<String> coverImageUrl = GeneratedColumn<String>(
    'cover_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paperTemplateIdMeta = const VerificationMeta(
    'paperTemplateId',
  );
  @override
  late final GeneratedColumn<String> paperTemplateId = GeneratedColumn<String>(
    'paper_template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('college_ruled'),
  );
  static const VerificationMeta _orientationMeta = const VerificationMeta(
    'orientation',
  );
  @override
  late final GeneratedColumn<String> orientation = GeneratedColumn<String>(
    'orientation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('portrait'),
  );
  static const VerificationMeta _pageSizeMeta = const VerificationMeta(
    'pageSize',
  );
  @override
  late final GeneratedColumn<String> pageSize = GeneratedColumn<String>(
    'page_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('A4'),
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPdfMeta = const VerificationMeta('isPdf');
  @override
  late final GeneratedColumn<bool> isPdf = GeneratedColumn<bool>(
    'is_pdf',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pdf" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pdfPathMeta = const VerificationMeta(
    'pdfPath',
  );
  @override
  late final GeneratedColumn<String> pdfPath = GeneratedColumn<String>(
    'pdf_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    folderId,
    title,
    description,
    coverId,
    coverColorHex,
    coverImageUrl,
    paperTemplateId,
    orientation,
    pageSize,
    pageCount,
    isFavorite,
    isArchived,
    isPdf,
    pdfPath,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notebooks_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotebooksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cover_id')) {
      context.handle(
        _coverIdMeta,
        coverId.isAcceptableOrUnknown(data['cover_id']!, _coverIdMeta),
      );
    }
    if (data.containsKey('cover_color_hex')) {
      context.handle(
        _coverColorHexMeta,
        coverColorHex.isAcceptableOrUnknown(
          data['cover_color_hex']!,
          _coverColorHexMeta,
        ),
      );
    }
    if (data.containsKey('cover_image_url')) {
      context.handle(
        _coverImageUrlMeta,
        coverImageUrl.isAcceptableOrUnknown(
          data['cover_image_url']!,
          _coverImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('paper_template_id')) {
      context.handle(
        _paperTemplateIdMeta,
        paperTemplateId.isAcceptableOrUnknown(
          data['paper_template_id']!,
          _paperTemplateIdMeta,
        ),
      );
    }
    if (data.containsKey('orientation')) {
      context.handle(
        _orientationMeta,
        orientation.isAcceptableOrUnknown(
          data['orientation']!,
          _orientationMeta,
        ),
      );
    }
    if (data.containsKey('page_size')) {
      context.handle(
        _pageSizeMeta,
        pageSize.isAcceptableOrUnknown(data['page_size']!, _pageSizeMeta),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_pdf')) {
      context.handle(
        _isPdfMeta,
        isPdf.isAcceptableOrUnknown(data['is_pdf']!, _isPdfMeta),
      );
    }
    if (data.containsKey('pdf_path')) {
      context.handle(
        _pdfPathMeta,
        pdfPath.isAcceptableOrUnknown(data['pdf_path']!, _pdfPathMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotebooksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotebooksTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      coverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_id'],
      )!,
      coverColorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_color_hex'],
      )!,
      coverImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image_url'],
      ),
      paperTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paper_template_id'],
      )!,
      orientation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}orientation'],
      )!,
      pageSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_size'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      isPdf: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pdf'],
      )!,
      pdfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_path'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $NotebooksTableTable createAlias(String alias) {
    return $NotebooksTableTable(attachedDatabase, alias);
  }
}

class NotebooksTableData extends DataClass
    implements Insertable<NotebooksTableData> {
  final String id;
  final String ownerId;
  final String? folderId;
  final String title;
  final String description;
  final String coverId;
  final String coverColorHex;
  final String? coverImageUrl;
  final String paperTemplateId;
  final String orientation;
  final String pageSize;
  final int pageCount;
  final bool isFavorite;
  final bool isArchived;
  final bool isPdf;
  final String? pdfPath;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  const NotebooksTableData({
    required this.id,
    required this.ownerId,
    this.folderId,
    required this.title,
    required this.description,
    required this.coverId,
    required this.coverColorHex,
    this.coverImageUrl,
    required this.paperTemplateId,
    required this.orientation,
    required this.pageSize,
    required this.pageCount,
    required this.isFavorite,
    required this.isArchived,
    required this.isPdf,
    this.pdfPath,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['cover_id'] = Variable<String>(coverId);
    map['cover_color_hex'] = Variable<String>(coverColorHex);
    if (!nullToAbsent || coverImageUrl != null) {
      map['cover_image_url'] = Variable<String>(coverImageUrl);
    }
    map['paper_template_id'] = Variable<String>(paperTemplateId);
    map['orientation'] = Variable<String>(orientation);
    map['page_size'] = Variable<String>(pageSize);
    map['page_count'] = Variable<int>(pageCount);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_pdf'] = Variable<bool>(isPdf);
    if (!nullToAbsent || pdfPath != null) {
      map['pdf_path'] = Variable<String>(pdfPath);
    }
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  NotebooksTableCompanion toCompanion(bool nullToAbsent) {
    return NotebooksTableCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      title: Value(title),
      description: Value(description),
      coverId: Value(coverId),
      coverColorHex: Value(coverColorHex),
      coverImageUrl: coverImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImageUrl),
      paperTemplateId: Value(paperTemplateId),
      orientation: Value(orientation),
      pageSize: Value(pageSize),
      pageCount: Value(pageCount),
      isFavorite: Value(isFavorite),
      isArchived: Value(isArchived),
      isPdf: Value(isPdf),
      pdfPath: pdfPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPath),
      revision: Value(revision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory NotebooksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotebooksTableData(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      coverId: serializer.fromJson<String>(json['coverId']),
      coverColorHex: serializer.fromJson<String>(json['coverColorHex']),
      coverImageUrl: serializer.fromJson<String?>(json['coverImageUrl']),
      paperTemplateId: serializer.fromJson<String>(json['paperTemplateId']),
      orientation: serializer.fromJson<String>(json['orientation']),
      pageSize: serializer.fromJson<String>(json['pageSize']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isPdf: serializer.fromJson<bool>(json['isPdf']),
      pdfPath: serializer.fromJson<String?>(json['pdfPath']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'folderId': serializer.toJson<String?>(folderId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'coverId': serializer.toJson<String>(coverId),
      'coverColorHex': serializer.toJson<String>(coverColorHex),
      'coverImageUrl': serializer.toJson<String?>(coverImageUrl),
      'paperTemplateId': serializer.toJson<String>(paperTemplateId),
      'orientation': serializer.toJson<String>(orientation),
      'pageSize': serializer.toJson<String>(pageSize),
      'pageCount': serializer.toJson<int>(pageCount),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isPdf': serializer.toJson<bool>(isPdf),
      'pdfPath': serializer.toJson<String?>(pdfPath),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  NotebooksTableData copyWith({
    String? id,
    String? ownerId,
    Value<String?> folderId = const Value.absent(),
    String? title,
    String? description,
    String? coverId,
    String? coverColorHex,
    Value<String?> coverImageUrl = const Value.absent(),
    String? paperTemplateId,
    String? orientation,
    String? pageSize,
    int? pageCount,
    bool? isFavorite,
    bool? isArchived,
    bool? isPdf,
    Value<String?> pdfPath = const Value.absent(),
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncStatus,
  }) => NotebooksTableData(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    folderId: folderId.present ? folderId.value : this.folderId,
    title: title ?? this.title,
    description: description ?? this.description,
    coverId: coverId ?? this.coverId,
    coverColorHex: coverColorHex ?? this.coverColorHex,
    coverImageUrl: coverImageUrl.present
        ? coverImageUrl.value
        : this.coverImageUrl,
    paperTemplateId: paperTemplateId ?? this.paperTemplateId,
    orientation: orientation ?? this.orientation,
    pageSize: pageSize ?? this.pageSize,
    pageCount: pageCount ?? this.pageCount,
    isFavorite: isFavorite ?? this.isFavorite,
    isArchived: isArchived ?? this.isArchived,
    isPdf: isPdf ?? this.isPdf,
    pdfPath: pdfPath.present ? pdfPath.value : this.pdfPath,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  NotebooksTableData copyWithCompanion(NotebooksTableCompanion data) {
    return NotebooksTableData(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      coverId: data.coverId.present ? data.coverId.value : this.coverId,
      coverColorHex: data.coverColorHex.present
          ? data.coverColorHex.value
          : this.coverColorHex,
      coverImageUrl: data.coverImageUrl.present
          ? data.coverImageUrl.value
          : this.coverImageUrl,
      paperTemplateId: data.paperTemplateId.present
          ? data.paperTemplateId.value
          : this.paperTemplateId,
      orientation: data.orientation.present
          ? data.orientation.value
          : this.orientation,
      pageSize: data.pageSize.present ? data.pageSize.value : this.pageSize,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isPdf: data.isPdf.present ? data.isPdf.value : this.isPdf,
      pdfPath: data.pdfPath.present ? data.pdfPath.value : this.pdfPath,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotebooksTableData(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('folderId: $folderId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('coverId: $coverId, ')
          ..write('coverColorHex: $coverColorHex, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('paperTemplateId: $paperTemplateId, ')
          ..write('orientation: $orientation, ')
          ..write('pageSize: $pageSize, ')
          ..write('pageCount: $pageCount, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isArchived: $isArchived, ')
          ..write('isPdf: $isPdf, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    ownerId,
    folderId,
    title,
    description,
    coverId,
    coverColorHex,
    coverImageUrl,
    paperTemplateId,
    orientation,
    pageSize,
    pageCount,
    isFavorite,
    isArchived,
    isPdf,
    pdfPath,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotebooksTableData &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.folderId == this.folderId &&
          other.title == this.title &&
          other.description == this.description &&
          other.coverId == this.coverId &&
          other.coverColorHex == this.coverColorHex &&
          other.coverImageUrl == this.coverImageUrl &&
          other.paperTemplateId == this.paperTemplateId &&
          other.orientation == this.orientation &&
          other.pageSize == this.pageSize &&
          other.pageCount == this.pageCount &&
          other.isFavorite == this.isFavorite &&
          other.isArchived == this.isArchived &&
          other.isPdf == this.isPdf &&
          other.pdfPath == this.pdfPath &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class NotebooksTableCompanion extends UpdateCompanion<NotebooksTableData> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String?> folderId;
  final Value<String> title;
  final Value<String> description;
  final Value<String> coverId;
  final Value<String> coverColorHex;
  final Value<String?> coverImageUrl;
  final Value<String> paperTemplateId;
  final Value<String> orientation;
  final Value<String> pageSize;
  final Value<int> pageCount;
  final Value<bool> isFavorite;
  final Value<bool> isArchived;
  final Value<bool> isPdf;
  final Value<String?> pdfPath;
  final Value<int> revision;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const NotebooksTableCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.coverId = const Value.absent(),
    this.coverColorHex = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.paperTemplateId = const Value.absent(),
    this.orientation = const Value.absent(),
    this.pageSize = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isPdf = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotebooksTableCompanion.insert({
    required String id,
    this.ownerId = const Value.absent(),
    this.folderId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.coverId = const Value.absent(),
    this.coverColorHex = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.paperTemplateId = const Value.absent(),
    this.orientation = const Value.absent(),
    this.pageSize = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isPdf = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.revision = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NotebooksTableData> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? folderId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? coverId,
    Expression<String>? coverColorHex,
    Expression<String>? coverImageUrl,
    Expression<String>? paperTemplateId,
    Expression<String>? orientation,
    Expression<String>? pageSize,
    Expression<int>? pageCount,
    Expression<bool>? isFavorite,
    Expression<bool>? isArchived,
    Expression<bool>? isPdf,
    Expression<String>? pdfPath,
    Expression<int>? revision,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (folderId != null) 'folder_id': folderId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (coverId != null) 'cover_id': coverId,
      if (coverColorHex != null) 'cover_color_hex': coverColorHex,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (paperTemplateId != null) 'paper_template_id': paperTemplateId,
      if (orientation != null) 'orientation': orientation,
      if (pageSize != null) 'page_size': pageSize,
      if (pageCount != null) 'page_count': pageCount,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isArchived != null) 'is_archived': isArchived,
      if (isPdf != null) 'is_pdf': isPdf,
      if (pdfPath != null) 'pdf_path': pdfPath,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotebooksTableCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String?>? folderId,
    Value<String>? title,
    Value<String>? description,
    Value<String>? coverId,
    Value<String>? coverColorHex,
    Value<String?>? coverImageUrl,
    Value<String>? paperTemplateId,
    Value<String>? orientation,
    Value<String>? pageSize,
    Value<int>? pageCount,
    Value<bool>? isFavorite,
    Value<bool>? isArchived,
    Value<bool>? isPdf,
    Value<String?>? pdfPath,
    Value<int>? revision,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return NotebooksTableCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      description: description ?? this.description,
      coverId: coverId ?? this.coverId,
      coverColorHex: coverColorHex ?? this.coverColorHex,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      paperTemplateId: paperTemplateId ?? this.paperTemplateId,
      orientation: orientation ?? this.orientation,
      pageSize: pageSize ?? this.pageSize,
      pageCount: pageCount ?? this.pageCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isPdf: isPdf ?? this.isPdf,
      pdfPath: pdfPath ?? this.pdfPath,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverId.present) {
      map['cover_id'] = Variable<String>(coverId.value);
    }
    if (coverColorHex.present) {
      map['cover_color_hex'] = Variable<String>(coverColorHex.value);
    }
    if (coverImageUrl.present) {
      map['cover_image_url'] = Variable<String>(coverImageUrl.value);
    }
    if (paperTemplateId.present) {
      map['paper_template_id'] = Variable<String>(paperTemplateId.value);
    }
    if (orientation.present) {
      map['orientation'] = Variable<String>(orientation.value);
    }
    if (pageSize.present) {
      map['page_size'] = Variable<String>(pageSize.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isPdf.present) {
      map['is_pdf'] = Variable<bool>(isPdf.value);
    }
    if (pdfPath.present) {
      map['pdf_path'] = Variable<String>(pdfPath.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotebooksTableCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('folderId: $folderId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('coverId: $coverId, ')
          ..write('coverColorHex: $coverColorHex, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('paperTemplateId: $paperTemplateId, ')
          ..write('orientation: $orientation, ')
          ..write('pageSize: $pageSize, ')
          ..write('pageCount: $pageCount, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isArchived: $isArchived, ')
          ..write('isPdf: $isPdf, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SectionsTableTable extends SectionsTable
    with TableInfo<$SectionsTableTable, SectionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notebookIdMeta = const VerificationMeta(
    'notebookId',
  );
  @override
  late final GeneratedColumn<String> notebookId = GeneratedColumn<String>(
    'notebook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notebooks_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#1E2A38'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    notebookId,
    name,
    orderIndex,
    colorHex,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sections_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SectionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
        _notebookIdMeta,
        notebookId.isAcceptableOrUnknown(data['notebook_id']!, _notebookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notebookIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SectionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      notebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notebook_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SectionsTableTable createAlias(String alias) {
    return $SectionsTableTable(attachedDatabase, alias);
  }
}

class SectionsTableData extends DataClass
    implements Insertable<SectionsTableData> {
  final String id;
  final String notebookId;
  final String name;
  final int orderIndex;
  final String colorHex;
  final DateTime createdAt;
  const SectionsTableData({
    required this.id,
    required this.notebookId,
    required this.name,
    required this.orderIndex,
    required this.colorHex,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['notebook_id'] = Variable<String>(notebookId);
    map['name'] = Variable<String>(name);
    map['order_index'] = Variable<int>(orderIndex);
    map['color_hex'] = Variable<String>(colorHex);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SectionsTableCompanion toCompanion(bool nullToAbsent) {
    return SectionsTableCompanion(
      id: Value(id),
      notebookId: Value(notebookId),
      name: Value(name),
      orderIndex: Value(orderIndex),
      colorHex: Value(colorHex),
      createdAt: Value(createdAt),
    );
  }

  factory SectionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectionsTableData(
      id: serializer.fromJson<String>(json['id']),
      notebookId: serializer.fromJson<String>(json['notebookId']),
      name: serializer.fromJson<String>(json['name']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'notebookId': serializer.toJson<String>(notebookId),
      'name': serializer.toJson<String>(name),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'colorHex': serializer.toJson<String>(colorHex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SectionsTableData copyWith({
    String? id,
    String? notebookId,
    String? name,
    int? orderIndex,
    String? colorHex,
    DateTime? createdAt,
  }) => SectionsTableData(
    id: id ?? this.id,
    notebookId: notebookId ?? this.notebookId,
    name: name ?? this.name,
    orderIndex: orderIndex ?? this.orderIndex,
    colorHex: colorHex ?? this.colorHex,
    createdAt: createdAt ?? this.createdAt,
  );
  SectionsTableData copyWithCompanion(SectionsTableCompanion data) {
    return SectionsTableData(
      id: data.id.present ? data.id.value : this.id,
      notebookId: data.notebookId.present
          ? data.notebookId.value
          : this.notebookId,
      name: data.name.present ? data.name.value : this.name,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectionsTableData(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('name: $name, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, notebookId, name, orderIndex, colorHex, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectionsTableData &&
          other.id == this.id &&
          other.notebookId == this.notebookId &&
          other.name == this.name &&
          other.orderIndex == this.orderIndex &&
          other.colorHex == this.colorHex &&
          other.createdAt == this.createdAt);
}

class SectionsTableCompanion extends UpdateCompanion<SectionsTableData> {
  final Value<String> id;
  final Value<String> notebookId;
  final Value<String> name;
  final Value<int> orderIndex;
  final Value<String> colorHex;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SectionsTableCompanion({
    this.id = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.name = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SectionsTableCompanion.insert({
    required String id,
    required String notebookId,
    required String name,
    this.orderIndex = const Value.absent(),
    this.colorHex = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       notebookId = Value(notebookId),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<SectionsTableData> custom({
    Expression<String>? id,
    Expression<String>? notebookId,
    Expression<String>? name,
    Expression<int>? orderIndex,
    Expression<String>? colorHex,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notebookId != null) 'notebook_id': notebookId,
      if (name != null) 'name': name,
      if (orderIndex != null) 'order_index': orderIndex,
      if (colorHex != null) 'color_hex': colorHex,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SectionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? notebookId,
    Value<String>? name,
    Value<int>? orderIndex,
    Value<String>? colorHex,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SectionsTableCompanion(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<String>(notebookId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectionsTableCompanion(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('name: $name, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PagesTableTable extends PagesTable
    with TableInfo<$PagesTableTable, PagesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notebookIdMeta = const VerificationMeta(
    'notebookId',
  );
  @override
  late final GeneratedColumn<String> notebookId = GeneratedColumn<String>(
    'notebook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notebooks_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sectionIdMeta = const VerificationMeta(
    'sectionId',
  );
  @override
  late final GeneratedColumn<String> sectionId = GeneratedColumn<String>(
    'section_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('college_ruled'),
  );
  static const VerificationMeta _backgroundColorMeta = const VerificationMeta(
    'backgroundColor',
  );
  @override
  late final GeneratedColumn<String> backgroundColor = GeneratedColumn<String>(
    'background_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templatePropertiesJsonMeta =
      const VerificationMeta('templatePropertiesJson');
  @override
  late final GeneratedColumn<String> templatePropertiesJson =
      GeneratedColumn<String>(
        'template_properties_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isBookmarkedMeta = const VerificationMeta(
    'isBookmarked',
  );
  @override
  late final GeneratedColumn<bool> isBookmarked = GeneratedColumn<bool>(
    'is_bookmarked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bookmarked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pdfPageIndexMeta = const VerificationMeta(
    'pdfPageIndex',
  );
  @override
  late final GeneratedColumn<int> pdfPageIndex = GeneratedColumn<int>(
    'pdf_page_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(595.28),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(841.89),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    notebookId,
    sectionId,
    pageNumber,
    templateId,
    backgroundColor,
    templatePropertiesJson,
    isBookmarked,
    pdfPageIndex,
    width,
    height,
    revision,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pages_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PagesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
        _notebookIdMeta,
        notebookId.isAcceptableOrUnknown(data['notebook_id']!, _notebookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notebookIdMeta);
    }
    if (data.containsKey('section_id')) {
      context.handle(
        _sectionIdMeta,
        sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta),
      );
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('background_color')) {
      context.handle(
        _backgroundColorMeta,
        backgroundColor.isAcceptableOrUnknown(
          data['background_color']!,
          _backgroundColorMeta,
        ),
      );
    }
    if (data.containsKey('template_properties_json')) {
      context.handle(
        _templatePropertiesJsonMeta,
        templatePropertiesJson.isAcceptableOrUnknown(
          data['template_properties_json']!,
          _templatePropertiesJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_bookmarked')) {
      context.handle(
        _isBookmarkedMeta,
        isBookmarked.isAcceptableOrUnknown(
          data['is_bookmarked']!,
          _isBookmarkedMeta,
        ),
      );
    }
    if (data.containsKey('pdf_page_index')) {
      context.handle(
        _pdfPageIndexMeta,
        pdfPageIndex.isAcceptableOrUnknown(
          data['pdf_page_index']!,
          _pdfPageIndexMeta,
        ),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PagesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PagesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      notebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notebook_id'],
      )!,
      sectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_id'],
      ),
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      backgroundColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_color'],
      ),
      templatePropertiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_properties_json'],
      ),
      isBookmarked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bookmarked'],
      )!,
      pdfPageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pdf_page_index'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PagesTableTable createAlias(String alias) {
    return $PagesTableTable(attachedDatabase, alias);
  }
}

class PagesTableData extends DataClass implements Insertable<PagesTableData> {
  final String id;
  final String notebookId;
  final String? sectionId;
  final int pageNumber;
  final String templateId;
  final String? backgroundColor;
  final String? templatePropertiesJson;
  final bool isBookmarked;
  final int? pdfPageIndex;
  final double width;
  final double height;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PagesTableData({
    required this.id,
    required this.notebookId,
    this.sectionId,
    required this.pageNumber,
    required this.templateId,
    this.backgroundColor,
    this.templatePropertiesJson,
    required this.isBookmarked,
    this.pdfPageIndex,
    required this.width,
    required this.height,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['notebook_id'] = Variable<String>(notebookId);
    if (!nullToAbsent || sectionId != null) {
      map['section_id'] = Variable<String>(sectionId);
    }
    map['page_number'] = Variable<int>(pageNumber);
    map['template_id'] = Variable<String>(templateId);
    if (!nullToAbsent || backgroundColor != null) {
      map['background_color'] = Variable<String>(backgroundColor);
    }
    if (!nullToAbsent || templatePropertiesJson != null) {
      map['template_properties_json'] = Variable<String>(
        templatePropertiesJson,
      );
    }
    map['is_bookmarked'] = Variable<bool>(isBookmarked);
    if (!nullToAbsent || pdfPageIndex != null) {
      map['pdf_page_index'] = Variable<int>(pdfPageIndex);
    }
    map['width'] = Variable<double>(width);
    map['height'] = Variable<double>(height);
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PagesTableCompanion toCompanion(bool nullToAbsent) {
    return PagesTableCompanion(
      id: Value(id),
      notebookId: Value(notebookId),
      sectionId: sectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionId),
      pageNumber: Value(pageNumber),
      templateId: Value(templateId),
      backgroundColor: backgroundColor == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundColor),
      templatePropertiesJson: templatePropertiesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(templatePropertiesJson),
      isBookmarked: Value(isBookmarked),
      pdfPageIndex: pdfPageIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPageIndex),
      width: Value(width),
      height: Value(height),
      revision: Value(revision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PagesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PagesTableData(
      id: serializer.fromJson<String>(json['id']),
      notebookId: serializer.fromJson<String>(json['notebookId']),
      sectionId: serializer.fromJson<String?>(json['sectionId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      templateId: serializer.fromJson<String>(json['templateId']),
      backgroundColor: serializer.fromJson<String?>(json['backgroundColor']),
      templatePropertiesJson: serializer.fromJson<String?>(
        json['templatePropertiesJson'],
      ),
      isBookmarked: serializer.fromJson<bool>(json['isBookmarked']),
      pdfPageIndex: serializer.fromJson<int?>(json['pdfPageIndex']),
      width: serializer.fromJson<double>(json['width']),
      height: serializer.fromJson<double>(json['height']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'notebookId': serializer.toJson<String>(notebookId),
      'sectionId': serializer.toJson<String?>(sectionId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'templateId': serializer.toJson<String>(templateId),
      'backgroundColor': serializer.toJson<String?>(backgroundColor),
      'templatePropertiesJson': serializer.toJson<String?>(
        templatePropertiesJson,
      ),
      'isBookmarked': serializer.toJson<bool>(isBookmarked),
      'pdfPageIndex': serializer.toJson<int?>(pdfPageIndex),
      'width': serializer.toJson<double>(width),
      'height': serializer.toJson<double>(height),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PagesTableData copyWith({
    String? id,
    String? notebookId,
    Value<String?> sectionId = const Value.absent(),
    int? pageNumber,
    String? templateId,
    Value<String?> backgroundColor = const Value.absent(),
    Value<String?> templatePropertiesJson = const Value.absent(),
    bool? isBookmarked,
    Value<int?> pdfPageIndex = const Value.absent(),
    double? width,
    double? height,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PagesTableData(
    id: id ?? this.id,
    notebookId: notebookId ?? this.notebookId,
    sectionId: sectionId.present ? sectionId.value : this.sectionId,
    pageNumber: pageNumber ?? this.pageNumber,
    templateId: templateId ?? this.templateId,
    backgroundColor: backgroundColor.present
        ? backgroundColor.value
        : this.backgroundColor,
    templatePropertiesJson: templatePropertiesJson.present
        ? templatePropertiesJson.value
        : this.templatePropertiesJson,
    isBookmarked: isBookmarked ?? this.isBookmarked,
    pdfPageIndex: pdfPageIndex.present ? pdfPageIndex.value : this.pdfPageIndex,
    width: width ?? this.width,
    height: height ?? this.height,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PagesTableData copyWithCompanion(PagesTableCompanion data) {
    return PagesTableData(
      id: data.id.present ? data.id.value : this.id,
      notebookId: data.notebookId.present
          ? data.notebookId.value
          : this.notebookId,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      backgroundColor: data.backgroundColor.present
          ? data.backgroundColor.value
          : this.backgroundColor,
      templatePropertiesJson: data.templatePropertiesJson.present
          ? data.templatePropertiesJson.value
          : this.templatePropertiesJson,
      isBookmarked: data.isBookmarked.present
          ? data.isBookmarked.value
          : this.isBookmarked,
      pdfPageIndex: data.pdfPageIndex.present
          ? data.pdfPageIndex.value
          : this.pdfPageIndex,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PagesTableData(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('sectionId: $sectionId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('templateId: $templateId, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('templatePropertiesJson: $templatePropertiesJson, ')
          ..write('isBookmarked: $isBookmarked, ')
          ..write('pdfPageIndex: $pdfPageIndex, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    notebookId,
    sectionId,
    pageNumber,
    templateId,
    backgroundColor,
    templatePropertiesJson,
    isBookmarked,
    pdfPageIndex,
    width,
    height,
    revision,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PagesTableData &&
          other.id == this.id &&
          other.notebookId == this.notebookId &&
          other.sectionId == this.sectionId &&
          other.pageNumber == this.pageNumber &&
          other.templateId == this.templateId &&
          other.backgroundColor == this.backgroundColor &&
          other.templatePropertiesJson == this.templatePropertiesJson &&
          other.isBookmarked == this.isBookmarked &&
          other.pdfPageIndex == this.pdfPageIndex &&
          other.width == this.width &&
          other.height == this.height &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PagesTableCompanion extends UpdateCompanion<PagesTableData> {
  final Value<String> id;
  final Value<String> notebookId;
  final Value<String?> sectionId;
  final Value<int> pageNumber;
  final Value<String> templateId;
  final Value<String?> backgroundColor;
  final Value<String?> templatePropertiesJson;
  final Value<bool> isBookmarked;
  final Value<int?> pdfPageIndex;
  final Value<double> width;
  final Value<double> height;
  final Value<int> revision;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PagesTableCompanion({
    this.id = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.templateId = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.templatePropertiesJson = const Value.absent(),
    this.isBookmarked = const Value.absent(),
    this.pdfPageIndex = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PagesTableCompanion.insert({
    required String id,
    required String notebookId,
    this.sectionId = const Value.absent(),
    required int pageNumber,
    this.templateId = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.templatePropertiesJson = const Value.absent(),
    this.isBookmarked = const Value.absent(),
    this.pdfPageIndex = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.revision = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       notebookId = Value(notebookId),
       pageNumber = Value(pageNumber),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PagesTableData> custom({
    Expression<String>? id,
    Expression<String>? notebookId,
    Expression<String>? sectionId,
    Expression<int>? pageNumber,
    Expression<String>? templateId,
    Expression<String>? backgroundColor,
    Expression<String>? templatePropertiesJson,
    Expression<bool>? isBookmarked,
    Expression<int>? pdfPageIndex,
    Expression<double>? width,
    Expression<double>? height,
    Expression<int>? revision,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notebookId != null) 'notebook_id': notebookId,
      if (sectionId != null) 'section_id': sectionId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (templateId != null) 'template_id': templateId,
      if (backgroundColor != null) 'background_color': backgroundColor,
      if (templatePropertiesJson != null)
        'template_properties_json': templatePropertiesJson,
      if (isBookmarked != null) 'is_bookmarked': isBookmarked,
      if (pdfPageIndex != null) 'pdf_page_index': pdfPageIndex,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PagesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? notebookId,
    Value<String?>? sectionId,
    Value<int>? pageNumber,
    Value<String>? templateId,
    Value<String?>? backgroundColor,
    Value<String?>? templatePropertiesJson,
    Value<bool>? isBookmarked,
    Value<int?>? pdfPageIndex,
    Value<double>? width,
    Value<double>? height,
    Value<int>? revision,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PagesTableCompanion(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      sectionId: sectionId ?? this.sectionId,
      pageNumber: pageNumber ?? this.pageNumber,
      templateId: templateId ?? this.templateId,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      templatePropertiesJson:
          templatePropertiesJson ?? this.templatePropertiesJson,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      pdfPageIndex: pdfPageIndex ?? this.pdfPageIndex,
      width: width ?? this.width,
      height: height ?? this.height,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<String>(notebookId.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<String>(sectionId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (backgroundColor.present) {
      map['background_color'] = Variable<String>(backgroundColor.value);
    }
    if (templatePropertiesJson.present) {
      map['template_properties_json'] = Variable<String>(
        templatePropertiesJson.value,
      );
    }
    if (isBookmarked.present) {
      map['is_bookmarked'] = Variable<bool>(isBookmarked.value);
    }
    if (pdfPageIndex.present) {
      map['pdf_page_index'] = Variable<int>(pdfPageIndex.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagesTableCompanion(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('sectionId: $sectionId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('templateId: $templateId, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('templatePropertiesJson: $templatePropertiesJson, ')
          ..write('isBookmarked: $isBookmarked, ')
          ..write('pdfPageIndex: $pdfPageIndex, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StrokesTableTable extends StrokesTable
    with TableInfo<$StrokesTableTable, StrokesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrokesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _toolTypeMeta = const VerificationMeta(
    'toolType',
  );
  @override
  late final GeneratedColumn<String> toolType = GeneratedColumn<String>(
    'tool_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opacityMeta = const VerificationMeta(
    'opacity',
  );
  @override
  late final GeneratedColumn<double> opacity = GeneratedColumn<double>(
    'opacity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsJsonMeta = const VerificationMeta(
    'pointsJson',
  );
  @override
  late final GeneratedColumn<String> pointsJson = GeneratedColumn<String>(
    'points_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingBoxJsonMeta = const VerificationMeta(
    'boundingBoxJson',
  );
  @override
  late final GeneratedColumn<String> boundingBoxJson = GeneratedColumn<String>(
    'bounding_box_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pageId,
    toolType,
    colorValue,
    width,
    opacity,
    pointsJson,
    boundingBoxJson,
    createdAt,
    deletedAt,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strokes_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StrokesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('tool_type')) {
      context.handle(
        _toolTypeMeta,
        toolType.isAcceptableOrUnknown(data['tool_type']!, _toolTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_toolTypeMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('opacity')) {
      context.handle(
        _opacityMeta,
        opacity.isAcceptableOrUnknown(data['opacity']!, _opacityMeta),
      );
    } else if (isInserting) {
      context.missing(_opacityMeta);
    }
    if (data.containsKey('points_json')) {
      context.handle(
        _pointsJsonMeta,
        pointsJson.isAcceptableOrUnknown(data['points_json']!, _pointsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_pointsJsonMeta);
    }
    if (data.containsKey('bounding_box_json')) {
      context.handle(
        _boundingBoxJsonMeta,
        boundingBoxJson.isAcceptableOrUnknown(
          data['bounding_box_json']!,
          _boundingBoxJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingBoxJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StrokesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StrokesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      toolType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_type'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      opacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opacity'],
      )!,
      pointsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}points_json'],
      )!,
      boundingBoxJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bounding_box_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $StrokesTableTable createAlias(String alias) {
    return $StrokesTableTable(attachedDatabase, alias);
  }
}

class StrokesTableData extends DataClass
    implements Insertable<StrokesTableData> {
  final String id;
  final String pageId;
  final String toolType;
  final int colorValue;
  final double width;
  final double opacity;
  final String pointsJson;
  final String boundingBoxJson;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final int revision;
  const StrokesTableData({
    required this.id,
    required this.pageId,
    required this.toolType,
    required this.colorValue,
    required this.width,
    required this.opacity,
    required this.pointsJson,
    required this.boundingBoxJson,
    required this.createdAt,
    this.deletedAt,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['tool_type'] = Variable<String>(toolType);
    map['color_value'] = Variable<int>(colorValue);
    map['width'] = Variable<double>(width);
    map['opacity'] = Variable<double>(opacity);
    map['points_json'] = Variable<String>(pointsJson);
    map['bounding_box_json'] = Variable<String>(boundingBoxJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['revision'] = Variable<int>(revision);
    return map;
  }

  StrokesTableCompanion toCompanion(bool nullToAbsent) {
    return StrokesTableCompanion(
      id: Value(id),
      pageId: Value(pageId),
      toolType: Value(toolType),
      colorValue: Value(colorValue),
      width: Value(width),
      opacity: Value(opacity),
      pointsJson: Value(pointsJson),
      boundingBoxJson: Value(boundingBoxJson),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      revision: Value(revision),
    );
  }

  factory StrokesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StrokesTableData(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      toolType: serializer.fromJson<String>(json['toolType']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      width: serializer.fromJson<double>(json['width']),
      opacity: serializer.fromJson<double>(json['opacity']),
      pointsJson: serializer.fromJson<String>(json['pointsJson']),
      boundingBoxJson: serializer.fromJson<String>(json['boundingBoxJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'toolType': serializer.toJson<String>(toolType),
      'colorValue': serializer.toJson<int>(colorValue),
      'width': serializer.toJson<double>(width),
      'opacity': serializer.toJson<double>(opacity),
      'pointsJson': serializer.toJson<String>(pointsJson),
      'boundingBoxJson': serializer.toJson<String>(boundingBoxJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'revision': serializer.toJson<int>(revision),
    };
  }

  StrokesTableData copyWith({
    String? id,
    String? pageId,
    String? toolType,
    int? colorValue,
    double? width,
    double? opacity,
    String? pointsJson,
    String? boundingBoxJson,
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? revision,
  }) => StrokesTableData(
    id: id ?? this.id,
    pageId: pageId ?? this.pageId,
    toolType: toolType ?? this.toolType,
    colorValue: colorValue ?? this.colorValue,
    width: width ?? this.width,
    opacity: opacity ?? this.opacity,
    pointsJson: pointsJson ?? this.pointsJson,
    boundingBoxJson: boundingBoxJson ?? this.boundingBoxJson,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    revision: revision ?? this.revision,
  );
  StrokesTableData copyWithCompanion(StrokesTableCompanion data) {
    return StrokesTableData(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      toolType: data.toolType.present ? data.toolType.value : this.toolType,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      width: data.width.present ? data.width.value : this.width,
      opacity: data.opacity.present ? data.opacity.value : this.opacity,
      pointsJson: data.pointsJson.present
          ? data.pointsJson.value
          : this.pointsJson,
      boundingBoxJson: data.boundingBoxJson.present
          ? data.boundingBoxJson.value
          : this.boundingBoxJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StrokesTableData(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('toolType: $toolType, ')
          ..write('colorValue: $colorValue, ')
          ..write('width: $width, ')
          ..write('opacity: $opacity, ')
          ..write('pointsJson: $pointsJson, ')
          ..write('boundingBoxJson: $boundingBoxJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pageId,
    toolType,
    colorValue,
    width,
    opacity,
    pointsJson,
    boundingBoxJson,
    createdAt,
    deletedAt,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StrokesTableData &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.toolType == this.toolType &&
          other.colorValue == this.colorValue &&
          other.width == this.width &&
          other.opacity == this.opacity &&
          other.pointsJson == this.pointsJson &&
          other.boundingBoxJson == this.boundingBoxJson &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt &&
          other.revision == this.revision);
}

class StrokesTableCompanion extends UpdateCompanion<StrokesTableData> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String> toolType;
  final Value<int> colorValue;
  final Value<double> width;
  final Value<double> opacity;
  final Value<String> pointsJson;
  final Value<String> boundingBoxJson;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<int> revision;
  final Value<int> rowid;
  const StrokesTableCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.toolType = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.width = const Value.absent(),
    this.opacity = const Value.absent(),
    this.pointsJson = const Value.absent(),
    this.boundingBoxJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StrokesTableCompanion.insert({
    required String id,
    required String pageId,
    required String toolType,
    required int colorValue,
    required double width,
    required double opacity,
    required String pointsJson,
    required String boundingBoxJson,
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pageId = Value(pageId),
       toolType = Value(toolType),
       colorValue = Value(colorValue),
       width = Value(width),
       opacity = Value(opacity),
       pointsJson = Value(pointsJson),
       boundingBoxJson = Value(boundingBoxJson),
       createdAt = Value(createdAt);
  static Insertable<StrokesTableData> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? toolType,
    Expression<int>? colorValue,
    Expression<double>? width,
    Expression<double>? opacity,
    Expression<String>? pointsJson,
    Expression<String>? boundingBoxJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (toolType != null) 'tool_type': toolType,
      if (colorValue != null) 'color_value': colorValue,
      if (width != null) 'width': width,
      if (opacity != null) 'opacity': opacity,
      if (pointsJson != null) 'points_json': pointsJson,
      if (boundingBoxJson != null) 'bounding_box_json': boundingBoxJson,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StrokesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? pageId,
    Value<String>? toolType,
    Value<int>? colorValue,
    Value<double>? width,
    Value<double>? opacity,
    Value<String>? pointsJson,
    Value<String>? boundingBoxJson,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return StrokesTableCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      toolType: toolType ?? this.toolType,
      colorValue: colorValue ?? this.colorValue,
      width: width ?? this.width,
      opacity: opacity ?? this.opacity,
      pointsJson: pointsJson ?? this.pointsJson,
      boundingBoxJson: boundingBoxJson ?? this.boundingBoxJson,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (toolType.present) {
      map['tool_type'] = Variable<String>(toolType.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (opacity.present) {
      map['opacity'] = Variable<double>(opacity.value);
    }
    if (pointsJson.present) {
      map['points_json'] = Variable<String>(pointsJson.value);
    }
    if (boundingBoxJson.present) {
      map['bounding_box_json'] = Variable<String>(boundingBoxJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrokesTableCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('toolType: $toolType, ')
          ..write('colorValue: $colorValue, ')
          ..write('width: $width, ')
          ..write('opacity: $opacity, ')
          ..write('pointsJson: $pointsJson, ')
          ..write('boundingBoxJson: $boundingBoxJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StickyNotesTableTable extends StickyNotesTable
    with TableInfo<$StickyNotesTableTable, StickyNotesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StickyNotesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(160.0),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(140.0),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#FEF08A'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pageId,
    x,
    y,
    width,
    height,
    content,
    colorHex,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sticky_notes_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StickyNotesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StickyNotesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StickyNotesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StickyNotesTableTable createAlias(String alias) {
    return $StickyNotesTableTable(attachedDatabase, alias);
  }
}

class StickyNotesTableData extends DataClass
    implements Insertable<StickyNotesTableData> {
  final String id;
  final String pageId;
  final double x;
  final double y;
  final double width;
  final double height;
  final String content;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StickyNotesTableData({
    required this.id,
    required this.pageId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.content,
    required this.colorHex,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['width'] = Variable<double>(width);
    map['height'] = Variable<double>(height);
    map['content'] = Variable<String>(content);
    map['color_hex'] = Variable<String>(colorHex);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StickyNotesTableCompanion toCompanion(bool nullToAbsent) {
    return StickyNotesTableCompanion(
      id: Value(id),
      pageId: Value(pageId),
      x: Value(x),
      y: Value(y),
      width: Value(width),
      height: Value(height),
      content: Value(content),
      colorHex: Value(colorHex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StickyNotesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StickyNotesTableData(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      width: serializer.fromJson<double>(json['width']),
      height: serializer.fromJson<double>(json['height']),
      content: serializer.fromJson<String>(json['content']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'width': serializer.toJson<double>(width),
      'height': serializer.toJson<double>(height),
      'content': serializer.toJson<String>(content),
      'colorHex': serializer.toJson<String>(colorHex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StickyNotesTableData copyWith({
    String? id,
    String? pageId,
    double? x,
    double? y,
    double? width,
    double? height,
    String? content,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StickyNotesTableData(
    id: id ?? this.id,
    pageId: pageId ?? this.pageId,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    content: content ?? this.content,
    colorHex: colorHex ?? this.colorHex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StickyNotesTableData copyWithCompanion(StickyNotesTableCompanion data) {
    return StickyNotesTableData(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      content: data.content.present ? data.content.value : this.content,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StickyNotesTableData(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('content: $content, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pageId,
    x,
    y,
    width,
    height,
    content,
    colorHex,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StickyNotesTableData &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.x == this.x &&
          other.y == this.y &&
          other.width == this.width &&
          other.height == this.height &&
          other.content == this.content &&
          other.colorHex == this.colorHex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StickyNotesTableCompanion extends UpdateCompanion<StickyNotesTableData> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<double> x;
  final Value<double> y;
  final Value<double> width;
  final Value<double> height;
  final Value<String> content;
  final Value<String> colorHex;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StickyNotesTableCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.content = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StickyNotesTableCompanion.insert({
    required String id,
    required String pageId,
    required double x,
    required double y,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    required String content,
    this.colorHex = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pageId = Value(pageId),
       x = Value(x),
       y = Value(y),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StickyNotesTableData> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? width,
    Expression<double>? height,
    Expression<String>? content,
    Expression<String>? colorHex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (content != null) 'content': content,
      if (colorHex != null) 'color_hex': colorHex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StickyNotesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? pageId,
    Value<double>? x,
    Value<double>? y,
    Value<double>? width,
    Value<double>? height,
    Value<String>? content,
    Value<String>? colorHex,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StickyNotesTableCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      content: content ?? this.content,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StickyNotesTableCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('content: $content, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operationType,
    payloadJson,
    revision,
    createdAt,
    status,
    retryCount,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final String id;
  final String entityType;
  final String entityId;
  final String operationType;
  final String payloadJson;
  final int revision;
  final DateTime createdAt;
  final String status;
  final int retryCount;
  final String? lastError;
  const SyncQueueTableData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payloadJson,
    required this.revision,
    required this.createdAt,
    required this.status,
    required this.retryCount,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      revision: Value(revision),
      createdAt: Value(createdAt),
      status: Value(status),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueTableData copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? operationType,
    String? payloadJson,
    int? revision,
    DateTime? createdAt,
    String? status,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
  }) => SyncQueueTableData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operationType,
    payloadJson,
    revision,
    createdAt,
    status,
    retryCount,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<int> revision;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payloadJson,
    this.revision = const Value.absent(),
    required DateTime createdAt,
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operationType = Value(operationType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueTableData> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<int>? revision,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueTableCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<int>? revision,
    Value<DateTime>? createdAt,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PageSearchIndexTableTable extends PageSearchIndexTable
    with TableInfo<$PageSearchIndexTableTable, PageSearchIndexTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PageSearchIndexTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _notebookIdMeta = const VerificationMeta(
    'notebookId',
  );
  @override
  late final GeneratedColumn<String> notebookId = GeneratedColumn<String>(
    'notebook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notebooks_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textContentMeta = const VerificationMeta(
    'textContent',
  );
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text_content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingBoxesJsonMeta = const VerificationMeta(
    'boundingBoxesJson',
  );
  @override
  late final GeneratedColumn<String> boundingBoxesJson =
      GeneratedColumn<String>(
        'bounding_boxes_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pageId,
    notebookId,
    sourceType,
    textContent,
    boundingBoxesJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'page_search_index_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PageSearchIndexTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
        _notebookIdMeta,
        notebookId.isAcceptableOrUnknown(data['notebook_id']!, _notebookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notebookIdMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('text_content')) {
      context.handle(
        _textContentMeta,
        textContent.isAcceptableOrUnknown(
          data['text_content']!,
          _textContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textContentMeta);
    }
    if (data.containsKey('bounding_boxes_json')) {
      context.handle(
        _boundingBoxesJsonMeta,
        boundingBoxesJson.isAcceptableOrUnknown(
          data['bounding_boxes_json']!,
          _boundingBoxesJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PageSearchIndexTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageSearchIndexTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      notebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notebook_id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_content'],
      )!,
      boundingBoxesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bounding_boxes_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PageSearchIndexTableTable createAlias(String alias) {
    return $PageSearchIndexTableTable(attachedDatabase, alias);
  }
}

class PageSearchIndexTableData extends DataClass
    implements Insertable<PageSearchIndexTableData> {
  final String id;
  final String pageId;
  final String notebookId;
  final String sourceType;
  final String textContent;
  final String? boundingBoxesJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PageSearchIndexTableData({
    required this.id,
    required this.pageId,
    required this.notebookId,
    required this.sourceType,
    required this.textContent,
    this.boundingBoxesJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['notebook_id'] = Variable<String>(notebookId);
    map['source_type'] = Variable<String>(sourceType);
    map['text_content'] = Variable<String>(textContent);
    if (!nullToAbsent || boundingBoxesJson != null) {
      map['bounding_boxes_json'] = Variable<String>(boundingBoxesJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PageSearchIndexTableCompanion toCompanion(bool nullToAbsent) {
    return PageSearchIndexTableCompanion(
      id: Value(id),
      pageId: Value(pageId),
      notebookId: Value(notebookId),
      sourceType: Value(sourceType),
      textContent: Value(textContent),
      boundingBoxesJson: boundingBoxesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(boundingBoxesJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PageSearchIndexTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageSearchIndexTableData(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      notebookId: serializer.fromJson<String>(json['notebookId']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      textContent: serializer.fromJson<String>(json['textContent']),
      boundingBoxesJson: serializer.fromJson<String?>(
        json['boundingBoxesJson'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'notebookId': serializer.toJson<String>(notebookId),
      'sourceType': serializer.toJson<String>(sourceType),
      'textContent': serializer.toJson<String>(textContent),
      'boundingBoxesJson': serializer.toJson<String?>(boundingBoxesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PageSearchIndexTableData copyWith({
    String? id,
    String? pageId,
    String? notebookId,
    String? sourceType,
    String? textContent,
    Value<String?> boundingBoxesJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PageSearchIndexTableData(
    id: id ?? this.id,
    pageId: pageId ?? this.pageId,
    notebookId: notebookId ?? this.notebookId,
    sourceType: sourceType ?? this.sourceType,
    textContent: textContent ?? this.textContent,
    boundingBoxesJson: boundingBoxesJson.present
        ? boundingBoxesJson.value
        : this.boundingBoxesJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PageSearchIndexTableData copyWithCompanion(
    PageSearchIndexTableCompanion data,
  ) {
    return PageSearchIndexTableData(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      notebookId: data.notebookId.present
          ? data.notebookId.value
          : this.notebookId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      boundingBoxesJson: data.boundingBoxesJson.present
          ? data.boundingBoxesJson.value
          : this.boundingBoxesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageSearchIndexTableData(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('notebookId: $notebookId, ')
          ..write('sourceType: $sourceType, ')
          ..write('textContent: $textContent, ')
          ..write('boundingBoxesJson: $boundingBoxesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pageId,
    notebookId,
    sourceType,
    textContent,
    boundingBoxesJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageSearchIndexTableData &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.notebookId == this.notebookId &&
          other.sourceType == this.sourceType &&
          other.textContent == this.textContent &&
          other.boundingBoxesJson == this.boundingBoxesJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PageSearchIndexTableCompanion
    extends UpdateCompanion<PageSearchIndexTableData> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String> notebookId;
  final Value<String> sourceType;
  final Value<String> textContent;
  final Value<String?> boundingBoxesJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PageSearchIndexTableCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.textContent = const Value.absent(),
    this.boundingBoxesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PageSearchIndexTableCompanion.insert({
    required String id,
    required String pageId,
    required String notebookId,
    required String sourceType,
    required String textContent,
    this.boundingBoxesJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pageId = Value(pageId),
       notebookId = Value(notebookId),
       sourceType = Value(sourceType),
       textContent = Value(textContent),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PageSearchIndexTableData> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? notebookId,
    Expression<String>? sourceType,
    Expression<String>? textContent,
    Expression<String>? boundingBoxesJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (notebookId != null) 'notebook_id': notebookId,
      if (sourceType != null) 'source_type': sourceType,
      if (textContent != null) 'text_content': textContent,
      if (boundingBoxesJson != null) 'bounding_boxes_json': boundingBoxesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PageSearchIndexTableCompanion copyWith({
    Value<String>? id,
    Value<String>? pageId,
    Value<String>? notebookId,
    Value<String>? sourceType,
    Value<String>? textContent,
    Value<String?>? boundingBoxesJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PageSearchIndexTableCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      notebookId: notebookId ?? this.notebookId,
      sourceType: sourceType ?? this.sourceType,
      textContent: textContent ?? this.textContent,
      boundingBoxesJson: boundingBoxesJson ?? this.boundingBoxesJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<String>(notebookId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (textContent.present) {
      map['text_content'] = Variable<String>(textContent.value);
    }
    if (boundingBoxesJson.present) {
      map['bounding_boxes_json'] = Variable<String>(boundingBoxesJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PageSearchIndexTableCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('notebookId: $notebookId, ')
          ..write('sourceType: $sourceType, ')
          ..write('textContent: $textContent, ')
          ..write('boundingBoxesJson: $boundingBoxesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudioRecordingsTableTable extends AudioRecordingsTable
    with TableInfo<$AudioRecordingsTableTable, AudioRecordingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioRecordingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notebookIdMeta = const VerificationMeta(
    'notebookId',
  );
  @override
  late final GeneratedColumn<String> notebookId = GeneratedColumn<String>(
    'notebook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notebooks_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Lecture Audio'),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    notebookId,
    pageId,
    title,
    filePath,
    durationMs,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_recordings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioRecordingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
        _notebookIdMeta,
        notebookId.isAcceptableOrUnknown(data['notebook_id']!, _notebookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notebookIdMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioRecordingsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioRecordingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      notebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notebook_id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AudioRecordingsTableTable createAlias(String alias) {
    return $AudioRecordingsTableTable(attachedDatabase, alias);
  }
}

class AudioRecordingsTableData extends DataClass
    implements Insertable<AudioRecordingsTableData> {
  final String id;
  final String notebookId;
  final String? pageId;
  final String title;
  final String filePath;
  final int durationMs;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AudioRecordingsTableData({
    required this.id,
    required this.notebookId,
    this.pageId,
    required this.title,
    required this.filePath,
    required this.durationMs,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['notebook_id'] = Variable<String>(notebookId);
    if (!nullToAbsent || pageId != null) {
      map['page_id'] = Variable<String>(pageId);
    }
    map['title'] = Variable<String>(title);
    map['file_path'] = Variable<String>(filePath);
    map['duration_ms'] = Variable<int>(durationMs);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AudioRecordingsTableCompanion toCompanion(bool nullToAbsent) {
    return AudioRecordingsTableCompanion(
      id: Value(id),
      notebookId: Value(notebookId),
      pageId: pageId == null && nullToAbsent
          ? const Value.absent()
          : Value(pageId),
      title: Value(title),
      filePath: Value(filePath),
      durationMs: Value(durationMs),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AudioRecordingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioRecordingsTableData(
      id: serializer.fromJson<String>(json['id']),
      notebookId: serializer.fromJson<String>(json['notebookId']),
      pageId: serializer.fromJson<String?>(json['pageId']),
      title: serializer.fromJson<String>(json['title']),
      filePath: serializer.fromJson<String>(json['filePath']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'notebookId': serializer.toJson<String>(notebookId),
      'pageId': serializer.toJson<String?>(pageId),
      'title': serializer.toJson<String>(title),
      'filePath': serializer.toJson<String>(filePath),
      'durationMs': serializer.toJson<int>(durationMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AudioRecordingsTableData copyWith({
    String? id,
    String? notebookId,
    Value<String?> pageId = const Value.absent(),
    String? title,
    String? filePath,
    int? durationMs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AudioRecordingsTableData(
    id: id ?? this.id,
    notebookId: notebookId ?? this.notebookId,
    pageId: pageId.present ? pageId.value : this.pageId,
    title: title ?? this.title,
    filePath: filePath ?? this.filePath,
    durationMs: durationMs ?? this.durationMs,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AudioRecordingsTableData copyWithCompanion(
    AudioRecordingsTableCompanion data,
  ) {
    return AudioRecordingsTableData(
      id: data.id.present ? data.id.value : this.id,
      notebookId: data.notebookId.present
          ? data.notebookId.value
          : this.notebookId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      title: data.title.present ? data.title.value : this.title,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioRecordingsTableData(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('pageId: $pageId, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    notebookId,
    pageId,
    title,
    filePath,
    durationMs,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioRecordingsTableData &&
          other.id == this.id &&
          other.notebookId == this.notebookId &&
          other.pageId == this.pageId &&
          other.title == this.title &&
          other.filePath == this.filePath &&
          other.durationMs == this.durationMs &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AudioRecordingsTableCompanion
    extends UpdateCompanion<AudioRecordingsTableData> {
  final Value<String> id;
  final Value<String> notebookId;
  final Value<String?> pageId;
  final Value<String> title;
  final Value<String> filePath;
  final Value<int> durationMs;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AudioRecordingsTableCompanion({
    this.id = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.title = const Value.absent(),
    this.filePath = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioRecordingsTableCompanion.insert({
    required String id,
    required String notebookId,
    this.pageId = const Value.absent(),
    this.title = const Value.absent(),
    required String filePath,
    this.durationMs = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       notebookId = Value(notebookId),
       filePath = Value(filePath),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AudioRecordingsTableData> custom({
    Expression<String>? id,
    Expression<String>? notebookId,
    Expression<String>? pageId,
    Expression<String>? title,
    Expression<String>? filePath,
    Expression<int>? durationMs,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notebookId != null) 'notebook_id': notebookId,
      if (pageId != null) 'page_id': pageId,
      if (title != null) 'title': title,
      if (filePath != null) 'file_path': filePath,
      if (durationMs != null) 'duration_ms': durationMs,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioRecordingsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? notebookId,
    Value<String?>? pageId,
    Value<String>? title,
    Value<String>? filePath,
    Value<int>? durationMs,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AudioRecordingsTableCompanion(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      pageId: pageId ?? this.pageId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<String>(notebookId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioRecordingsTableCompanion(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('pageId: $pageId, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudioBookmarksTableTable extends AudioBookmarksTable
    with TableInfo<$AudioBookmarksTableTable, AudioBookmarksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioBookmarksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordingIdMeta = const VerificationMeta(
    'recordingId',
  );
  @override
  late final GeneratedColumn<String> recordingId = GeneratedColumn<String>(
    'recording_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES audio_recordings_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strokeIdMeta = const VerificationMeta(
    'strokeId',
  );
  @override
  late final GeneratedColumn<String> strokeId = GeneratedColumn<String>(
    'stroke_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMsMeta = const VerificationMeta(
    'timestampMs',
  );
  @override
  late final GeneratedColumn<int> timestampMs = GeneratedColumn<int>(
    'timestamp_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordingId,
    pageId,
    strokeId,
    timestampMs,
    label,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_bookmarks_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioBookmarksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recording_id')) {
      context.handle(
        _recordingIdMeta,
        recordingId.isAcceptableOrUnknown(
          data['recording_id']!,
          _recordingIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordingIdMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    }
    if (data.containsKey('stroke_id')) {
      context.handle(
        _strokeIdMeta,
        strokeId.isAcceptableOrUnknown(data['stroke_id']!, _strokeIdMeta),
      );
    }
    if (data.containsKey('timestamp_ms')) {
      context.handle(
        _timestampMsMeta,
        timestampMs.isAcceptableOrUnknown(
          data['timestamp_ms']!,
          _timestampMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampMsMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioBookmarksTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioBookmarksTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording_id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      ),
      strokeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stroke_id'],
      ),
      timestampMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_ms'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AudioBookmarksTableTable createAlias(String alias) {
    return $AudioBookmarksTableTable(attachedDatabase, alias);
  }
}

class AudioBookmarksTableData extends DataClass
    implements Insertable<AudioBookmarksTableData> {
  final String id;
  final String recordingId;
  final String? pageId;
  final String? strokeId;
  final int timestampMs;
  final String label;
  final DateTime createdAt;
  const AudioBookmarksTableData({
    required this.id,
    required this.recordingId,
    this.pageId,
    this.strokeId,
    required this.timestampMs,
    required this.label,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recording_id'] = Variable<String>(recordingId);
    if (!nullToAbsent || pageId != null) {
      map['page_id'] = Variable<String>(pageId);
    }
    if (!nullToAbsent || strokeId != null) {
      map['stroke_id'] = Variable<String>(strokeId);
    }
    map['timestamp_ms'] = Variable<int>(timestampMs);
    map['label'] = Variable<String>(label);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AudioBookmarksTableCompanion toCompanion(bool nullToAbsent) {
    return AudioBookmarksTableCompanion(
      id: Value(id),
      recordingId: Value(recordingId),
      pageId: pageId == null && nullToAbsent
          ? const Value.absent()
          : Value(pageId),
      strokeId: strokeId == null && nullToAbsent
          ? const Value.absent()
          : Value(strokeId),
      timestampMs: Value(timestampMs),
      label: Value(label),
      createdAt: Value(createdAt),
    );
  }

  factory AudioBookmarksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioBookmarksTableData(
      id: serializer.fromJson<String>(json['id']),
      recordingId: serializer.fromJson<String>(json['recordingId']),
      pageId: serializer.fromJson<String?>(json['pageId']),
      strokeId: serializer.fromJson<String?>(json['strokeId']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
      label: serializer.fromJson<String>(json['label']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordingId': serializer.toJson<String>(recordingId),
      'pageId': serializer.toJson<String?>(pageId),
      'strokeId': serializer.toJson<String?>(strokeId),
      'timestampMs': serializer.toJson<int>(timestampMs),
      'label': serializer.toJson<String>(label),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AudioBookmarksTableData copyWith({
    String? id,
    String? recordingId,
    Value<String?> pageId = const Value.absent(),
    Value<String?> strokeId = const Value.absent(),
    int? timestampMs,
    String? label,
    DateTime? createdAt,
  }) => AudioBookmarksTableData(
    id: id ?? this.id,
    recordingId: recordingId ?? this.recordingId,
    pageId: pageId.present ? pageId.value : this.pageId,
    strokeId: strokeId.present ? strokeId.value : this.strokeId,
    timestampMs: timestampMs ?? this.timestampMs,
    label: label ?? this.label,
    createdAt: createdAt ?? this.createdAt,
  );
  AudioBookmarksTableData copyWithCompanion(AudioBookmarksTableCompanion data) {
    return AudioBookmarksTableData(
      id: data.id.present ? data.id.value : this.id,
      recordingId: data.recordingId.present
          ? data.recordingId.value
          : this.recordingId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      strokeId: data.strokeId.present ? data.strokeId.value : this.strokeId,
      timestampMs: data.timestampMs.present
          ? data.timestampMs.value
          : this.timestampMs,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioBookmarksTableData(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('pageId: $pageId, ')
          ..write('strokeId: $strokeId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordingId,
    pageId,
    strokeId,
    timestampMs,
    label,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioBookmarksTableData &&
          other.id == this.id &&
          other.recordingId == this.recordingId &&
          other.pageId == this.pageId &&
          other.strokeId == this.strokeId &&
          other.timestampMs == this.timestampMs &&
          other.label == this.label &&
          other.createdAt == this.createdAt);
}

class AudioBookmarksTableCompanion
    extends UpdateCompanion<AudioBookmarksTableData> {
  final Value<String> id;
  final Value<String> recordingId;
  final Value<String?> pageId;
  final Value<String?> strokeId;
  final Value<int> timestampMs;
  final Value<String> label;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AudioBookmarksTableCompanion({
    this.id = const Value.absent(),
    this.recordingId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.strokeId = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioBookmarksTableCompanion.insert({
    required String id,
    required String recordingId,
    this.pageId = const Value.absent(),
    this.strokeId = const Value.absent(),
    required int timestampMs,
    required String label,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordingId = Value(recordingId),
       timestampMs = Value(timestampMs),
       label = Value(label),
       createdAt = Value(createdAt);
  static Insertable<AudioBookmarksTableData> custom({
    Expression<String>? id,
    Expression<String>? recordingId,
    Expression<String>? pageId,
    Expression<String>? strokeId,
    Expression<int>? timestampMs,
    Expression<String>? label,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordingId != null) 'recording_id': recordingId,
      if (pageId != null) 'page_id': pageId,
      if (strokeId != null) 'stroke_id': strokeId,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioBookmarksTableCompanion copyWith({
    Value<String>? id,
    Value<String>? recordingId,
    Value<String?>? pageId,
    Value<String?>? strokeId,
    Value<int>? timestampMs,
    Value<String>? label,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AudioBookmarksTableCompanion(
      id: id ?? this.id,
      recordingId: recordingId ?? this.recordingId,
      pageId: pageId ?? this.pageId,
      strokeId: strokeId ?? this.strokeId,
      timestampMs: timestampMs ?? this.timestampMs,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recordingId.present) {
      map['recording_id'] = Variable<String>(recordingId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (strokeId.present) {
      map['stroke_id'] = Variable<String>(strokeId.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioBookmarksTableCompanion(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('pageId: $pageId, ')
          ..write('strokeId: $strokeId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PageSnapshotsTableTable extends PageSnapshotsTable
    with TableInfo<$PageSnapshotsTableTable, PageSnapshotsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PageSnapshotsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _notebookIdMeta = const VerificationMeta(
    'notebookId',
  );
  @override
  late final GeneratedColumn<String> notebookId = GeneratedColumn<String>(
    'notebook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notebooks_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _versionNumberMeta = const VerificationMeta(
    'versionNumber',
  );
  @override
  late final GeneratedColumn<int> versionNumber = GeneratedColumn<int>(
    'version_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Snapshot'),
  );
  static const VerificationMeta _strokesJsonMeta = const VerificationMeta(
    'strokesJson',
  );
  @override
  late final GeneratedColumn<String> strokesJson = GeneratedColumn<String>(
    'strokes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stickyNotesJsonMeta = const VerificationMeta(
    'stickyNotesJson',
  );
  @override
  late final GeneratedColumn<String> stickyNotesJson = GeneratedColumn<String>(
    'sticky_notes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('college_ruled'),
  );
  static const VerificationMeta _templatePropertiesJsonMeta =
      const VerificationMeta('templatePropertiesJson');
  @override
  late final GeneratedColumn<String> templatePropertiesJson =
      GeneratedColumn<String>(
        'template_properties_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deviceInfoMeta = const VerificationMeta(
    'deviceInfo',
  );
  @override
  late final GeneratedColumn<String> deviceInfo = GeneratedColumn<String>(
    'device_info',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Local Device'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pageId,
    notebookId,
    versionNumber,
    label,
    strokesJson,
    stickyNotesJson,
    templateId,
    templatePropertiesJson,
    deviceInfo,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'page_snapshots_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PageSnapshotsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
        _notebookIdMeta,
        notebookId.isAcceptableOrUnknown(data['notebook_id']!, _notebookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notebookIdMeta);
    }
    if (data.containsKey('version_number')) {
      context.handle(
        _versionNumberMeta,
        versionNumber.isAcceptableOrUnknown(
          data['version_number']!,
          _versionNumberMeta,
        ),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('strokes_json')) {
      context.handle(
        _strokesJsonMeta,
        strokesJson.isAcceptableOrUnknown(
          data['strokes_json']!,
          _strokesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strokesJsonMeta);
    }
    if (data.containsKey('sticky_notes_json')) {
      context.handle(
        _stickyNotesJsonMeta,
        stickyNotesJson.isAcceptableOrUnknown(
          data['sticky_notes_json']!,
          _stickyNotesJsonMeta,
        ),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('template_properties_json')) {
      context.handle(
        _templatePropertiesJsonMeta,
        templatePropertiesJson.isAcceptableOrUnknown(
          data['template_properties_json']!,
          _templatePropertiesJsonMeta,
        ),
      );
    }
    if (data.containsKey('device_info')) {
      context.handle(
        _deviceInfoMeta,
        deviceInfo.isAcceptableOrUnknown(data['device_info']!, _deviceInfoMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PageSnapshotsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageSnapshotsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      notebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notebook_id'],
      )!,
      versionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_number'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      strokesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strokes_json'],
      )!,
      stickyNotesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sticky_notes_json'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      templatePropertiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_properties_json'],
      ),
      deviceInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_info'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PageSnapshotsTableTable createAlias(String alias) {
    return $PageSnapshotsTableTable(attachedDatabase, alias);
  }
}

class PageSnapshotsTableData extends DataClass
    implements Insertable<PageSnapshotsTableData> {
  final String id;
  final String pageId;
  final String notebookId;
  final int versionNumber;
  final String label;
  final String strokesJson;
  final String stickyNotesJson;
  final String templateId;
  final String? templatePropertiesJson;
  final String deviceInfo;
  final DateTime createdAt;
  const PageSnapshotsTableData({
    required this.id,
    required this.pageId,
    required this.notebookId,
    required this.versionNumber,
    required this.label,
    required this.strokesJson,
    required this.stickyNotesJson,
    required this.templateId,
    this.templatePropertiesJson,
    required this.deviceInfo,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['notebook_id'] = Variable<String>(notebookId);
    map['version_number'] = Variable<int>(versionNumber);
    map['label'] = Variable<String>(label);
    map['strokes_json'] = Variable<String>(strokesJson);
    map['sticky_notes_json'] = Variable<String>(stickyNotesJson);
    map['template_id'] = Variable<String>(templateId);
    if (!nullToAbsent || templatePropertiesJson != null) {
      map['template_properties_json'] = Variable<String>(
        templatePropertiesJson,
      );
    }
    map['device_info'] = Variable<String>(deviceInfo);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PageSnapshotsTableCompanion toCompanion(bool nullToAbsent) {
    return PageSnapshotsTableCompanion(
      id: Value(id),
      pageId: Value(pageId),
      notebookId: Value(notebookId),
      versionNumber: Value(versionNumber),
      label: Value(label),
      strokesJson: Value(strokesJson),
      stickyNotesJson: Value(stickyNotesJson),
      templateId: Value(templateId),
      templatePropertiesJson: templatePropertiesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(templatePropertiesJson),
      deviceInfo: Value(deviceInfo),
      createdAt: Value(createdAt),
    );
  }

  factory PageSnapshotsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageSnapshotsTableData(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      notebookId: serializer.fromJson<String>(json['notebookId']),
      versionNumber: serializer.fromJson<int>(json['versionNumber']),
      label: serializer.fromJson<String>(json['label']),
      strokesJson: serializer.fromJson<String>(json['strokesJson']),
      stickyNotesJson: serializer.fromJson<String>(json['stickyNotesJson']),
      templateId: serializer.fromJson<String>(json['templateId']),
      templatePropertiesJson: serializer.fromJson<String?>(
        json['templatePropertiesJson'],
      ),
      deviceInfo: serializer.fromJson<String>(json['deviceInfo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'notebookId': serializer.toJson<String>(notebookId),
      'versionNumber': serializer.toJson<int>(versionNumber),
      'label': serializer.toJson<String>(label),
      'strokesJson': serializer.toJson<String>(strokesJson),
      'stickyNotesJson': serializer.toJson<String>(stickyNotesJson),
      'templateId': serializer.toJson<String>(templateId),
      'templatePropertiesJson': serializer.toJson<String?>(
        templatePropertiesJson,
      ),
      'deviceInfo': serializer.toJson<String>(deviceInfo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PageSnapshotsTableData copyWith({
    String? id,
    String? pageId,
    String? notebookId,
    int? versionNumber,
    String? label,
    String? strokesJson,
    String? stickyNotesJson,
    String? templateId,
    Value<String?> templatePropertiesJson = const Value.absent(),
    String? deviceInfo,
    DateTime? createdAt,
  }) => PageSnapshotsTableData(
    id: id ?? this.id,
    pageId: pageId ?? this.pageId,
    notebookId: notebookId ?? this.notebookId,
    versionNumber: versionNumber ?? this.versionNumber,
    label: label ?? this.label,
    strokesJson: strokesJson ?? this.strokesJson,
    stickyNotesJson: stickyNotesJson ?? this.stickyNotesJson,
    templateId: templateId ?? this.templateId,
    templatePropertiesJson: templatePropertiesJson.present
        ? templatePropertiesJson.value
        : this.templatePropertiesJson,
    deviceInfo: deviceInfo ?? this.deviceInfo,
    createdAt: createdAt ?? this.createdAt,
  );
  PageSnapshotsTableData copyWithCompanion(PageSnapshotsTableCompanion data) {
    return PageSnapshotsTableData(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      notebookId: data.notebookId.present
          ? data.notebookId.value
          : this.notebookId,
      versionNumber: data.versionNumber.present
          ? data.versionNumber.value
          : this.versionNumber,
      label: data.label.present ? data.label.value : this.label,
      strokesJson: data.strokesJson.present
          ? data.strokesJson.value
          : this.strokesJson,
      stickyNotesJson: data.stickyNotesJson.present
          ? data.stickyNotesJson.value
          : this.stickyNotesJson,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      templatePropertiesJson: data.templatePropertiesJson.present
          ? data.templatePropertiesJson.value
          : this.templatePropertiesJson,
      deviceInfo: data.deviceInfo.present
          ? data.deviceInfo.value
          : this.deviceInfo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageSnapshotsTableData(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('notebookId: $notebookId, ')
          ..write('versionNumber: $versionNumber, ')
          ..write('label: $label, ')
          ..write('strokesJson: $strokesJson, ')
          ..write('stickyNotesJson: $stickyNotesJson, ')
          ..write('templateId: $templateId, ')
          ..write('templatePropertiesJson: $templatePropertiesJson, ')
          ..write('deviceInfo: $deviceInfo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pageId,
    notebookId,
    versionNumber,
    label,
    strokesJson,
    stickyNotesJson,
    templateId,
    templatePropertiesJson,
    deviceInfo,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageSnapshotsTableData &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.notebookId == this.notebookId &&
          other.versionNumber == this.versionNumber &&
          other.label == this.label &&
          other.strokesJson == this.strokesJson &&
          other.stickyNotesJson == this.stickyNotesJson &&
          other.templateId == this.templateId &&
          other.templatePropertiesJson == this.templatePropertiesJson &&
          other.deviceInfo == this.deviceInfo &&
          other.createdAt == this.createdAt);
}

class PageSnapshotsTableCompanion
    extends UpdateCompanion<PageSnapshotsTableData> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String> notebookId;
  final Value<int> versionNumber;
  final Value<String> label;
  final Value<String> strokesJson;
  final Value<String> stickyNotesJson;
  final Value<String> templateId;
  final Value<String?> templatePropertiesJson;
  final Value<String> deviceInfo;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PageSnapshotsTableCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.versionNumber = const Value.absent(),
    this.label = const Value.absent(),
    this.strokesJson = const Value.absent(),
    this.stickyNotesJson = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templatePropertiesJson = const Value.absent(),
    this.deviceInfo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PageSnapshotsTableCompanion.insert({
    required String id,
    required String pageId,
    required String notebookId,
    this.versionNumber = const Value.absent(),
    this.label = const Value.absent(),
    required String strokesJson,
    this.stickyNotesJson = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templatePropertiesJson = const Value.absent(),
    this.deviceInfo = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pageId = Value(pageId),
       notebookId = Value(notebookId),
       strokesJson = Value(strokesJson),
       createdAt = Value(createdAt);
  static Insertable<PageSnapshotsTableData> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? notebookId,
    Expression<int>? versionNumber,
    Expression<String>? label,
    Expression<String>? strokesJson,
    Expression<String>? stickyNotesJson,
    Expression<String>? templateId,
    Expression<String>? templatePropertiesJson,
    Expression<String>? deviceInfo,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (notebookId != null) 'notebook_id': notebookId,
      if (versionNumber != null) 'version_number': versionNumber,
      if (label != null) 'label': label,
      if (strokesJson != null) 'strokes_json': strokesJson,
      if (stickyNotesJson != null) 'sticky_notes_json': stickyNotesJson,
      if (templateId != null) 'template_id': templateId,
      if (templatePropertiesJson != null)
        'template_properties_json': templatePropertiesJson,
      if (deviceInfo != null) 'device_info': deviceInfo,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PageSnapshotsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? pageId,
    Value<String>? notebookId,
    Value<int>? versionNumber,
    Value<String>? label,
    Value<String>? strokesJson,
    Value<String>? stickyNotesJson,
    Value<String>? templateId,
    Value<String?>? templatePropertiesJson,
    Value<String>? deviceInfo,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PageSnapshotsTableCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      notebookId: notebookId ?? this.notebookId,
      versionNumber: versionNumber ?? this.versionNumber,
      label: label ?? this.label,
      strokesJson: strokesJson ?? this.strokesJson,
      stickyNotesJson: stickyNotesJson ?? this.stickyNotesJson,
      templateId: templateId ?? this.templateId,
      templatePropertiesJson:
          templatePropertiesJson ?? this.templatePropertiesJson,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<String>(notebookId.value);
    }
    if (versionNumber.present) {
      map['version_number'] = Variable<int>(versionNumber.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (strokesJson.present) {
      map['strokes_json'] = Variable<String>(strokesJson.value);
    }
    if (stickyNotesJson.present) {
      map['sticky_notes_json'] = Variable<String>(stickyNotesJson.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (templatePropertiesJson.present) {
      map['template_properties_json'] = Variable<String>(
        templatePropertiesJson.value,
      );
    }
    if (deviceInfo.present) {
      map['device_info'] = Variable<String>(deviceInfo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PageSnapshotsTableCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('notebookId: $notebookId, ')
          ..write('versionNumber: $versionNumber, ')
          ..write('label: $label, ')
          ..write('strokesJson: $strokesJson, ')
          ..write('stickyNotesJson: $stickyNotesJson, ')
          ..write('templateId: $templateId, ')
          ..write('templatePropertiesJson: $templatePropertiesJson, ')
          ..write('deviceInfo: $deviceInfo, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomTemplatesTableTable extends CustomTemplatesTable
    with TableInfo<$CustomTemplatesTableTable, CustomTemplatesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomTemplatesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('General'),
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Community'),
  );
  static const VerificationMeta _paperPropertiesJsonMeta =
      const VerificationMeta('paperPropertiesJson');
  @override
  late final GeneratedColumn<String> paperPropertiesJson =
      GeneratedColumn<String>(
        'paper_properties_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _thumbnailBase64Meta = const VerificationMeta(
    'thumbnailBase64',
  );
  @override
  late final GeneratedColumn<String> thumbnailBase64 = GeneratedColumn<String>(
    'thumbnail_base64',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isInstalledMeta = const VerificationMeta(
    'isInstalled',
  );
  @override
  late final GeneratedColumn<bool> isInstalled = GeneratedColumn<bool>(
    'is_installed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_installed" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isBuiltInMeta = const VerificationMeta(
    'isBuiltIn',
  );
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
    'is_built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _downloadCountMeta = const VerificationMeta(
    'downloadCount',
  );
  @override
  late final GeneratedColumn<int> downloadCount = GeneratedColumn<int>(
    'download_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(5.0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    category,
    author,
    paperPropertiesJson,
    thumbnailBase64,
    isInstalled,
    isBuiltIn,
    downloadCount,
    rating,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_templates_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomTemplatesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('paper_properties_json')) {
      context.handle(
        _paperPropertiesJsonMeta,
        paperPropertiesJson.isAcceptableOrUnknown(
          data['paper_properties_json']!,
          _paperPropertiesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paperPropertiesJsonMeta);
    }
    if (data.containsKey('thumbnail_base64')) {
      context.handle(
        _thumbnailBase64Meta,
        thumbnailBase64.isAcceptableOrUnknown(
          data['thumbnail_base64']!,
          _thumbnailBase64Meta,
        ),
      );
    }
    if (data.containsKey('is_installed')) {
      context.handle(
        _isInstalledMeta,
        isInstalled.isAcceptableOrUnknown(
          data['is_installed']!,
          _isInstalledMeta,
        ),
      );
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
        _isBuiltInMeta,
        isBuiltIn.isAcceptableOrUnknown(data['is_built_in']!, _isBuiltInMeta),
      );
    }
    if (data.containsKey('download_count')) {
      context.handle(
        _downloadCountMeta,
        downloadCount.isAcceptableOrUnknown(
          data['download_count']!,
          _downloadCountMeta,
        ),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomTemplatesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomTemplatesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      paperPropertiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paper_properties_json'],
      )!,
      thumbnailBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_base64'],
      ),
      isInstalled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_installed'],
      )!,
      isBuiltIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_built_in'],
      )!,
      downloadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}download_count'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomTemplatesTableTable createAlias(String alias) {
    return $CustomTemplatesTableTable(attachedDatabase, alias);
  }
}

class CustomTemplatesTableData extends DataClass
    implements Insertable<CustomTemplatesTableData> {
  final String id;
  final String title;
  final String description;
  final String category;
  final String author;
  final String paperPropertiesJson;
  final String? thumbnailBase64;
  final bool isInstalled;
  final bool isBuiltIn;
  final int downloadCount;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CustomTemplatesTableData({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.author,
    required this.paperPropertiesJson,
    this.thumbnailBase64,
    required this.isInstalled,
    required this.isBuiltIn,
    required this.downloadCount,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['author'] = Variable<String>(author);
    map['paper_properties_json'] = Variable<String>(paperPropertiesJson);
    if (!nullToAbsent || thumbnailBase64 != null) {
      map['thumbnail_base64'] = Variable<String>(thumbnailBase64);
    }
    map['is_installed'] = Variable<bool>(isInstalled);
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['download_count'] = Variable<int>(downloadCount);
    map['rating'] = Variable<double>(rating);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomTemplatesTableCompanion toCompanion(bool nullToAbsent) {
    return CustomTemplatesTableCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      category: Value(category),
      author: Value(author),
      paperPropertiesJson: Value(paperPropertiesJson),
      thumbnailBase64: thumbnailBase64 == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailBase64),
      isInstalled: Value(isInstalled),
      isBuiltIn: Value(isBuiltIn),
      downloadCount: Value(downloadCount),
      rating: Value(rating),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomTemplatesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomTemplatesTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      author: serializer.fromJson<String>(json['author']),
      paperPropertiesJson: serializer.fromJson<String>(
        json['paperPropertiesJson'],
      ),
      thumbnailBase64: serializer.fromJson<String?>(json['thumbnailBase64']),
      isInstalled: serializer.fromJson<bool>(json['isInstalled']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      downloadCount: serializer.fromJson<int>(json['downloadCount']),
      rating: serializer.fromJson<double>(json['rating']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'author': serializer.toJson<String>(author),
      'paperPropertiesJson': serializer.toJson<String>(paperPropertiesJson),
      'thumbnailBase64': serializer.toJson<String?>(thumbnailBase64),
      'isInstalled': serializer.toJson<bool>(isInstalled),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'downloadCount': serializer.toJson<int>(downloadCount),
      'rating': serializer.toJson<double>(rating),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomTemplatesTableData copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? author,
    String? paperPropertiesJson,
    Value<String?> thumbnailBase64 = const Value.absent(),
    bool? isInstalled,
    bool? isBuiltIn,
    int? downloadCount,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CustomTemplatesTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    author: author ?? this.author,
    paperPropertiesJson: paperPropertiesJson ?? this.paperPropertiesJson,
    thumbnailBase64: thumbnailBase64.present
        ? thumbnailBase64.value
        : this.thumbnailBase64,
    isInstalled: isInstalled ?? this.isInstalled,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    downloadCount: downloadCount ?? this.downloadCount,
    rating: rating ?? this.rating,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomTemplatesTableData copyWithCompanion(
    CustomTemplatesTableCompanion data,
  ) {
    return CustomTemplatesTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      author: data.author.present ? data.author.value : this.author,
      paperPropertiesJson: data.paperPropertiesJson.present
          ? data.paperPropertiesJson.value
          : this.paperPropertiesJson,
      thumbnailBase64: data.thumbnailBase64.present
          ? data.thumbnailBase64.value
          : this.thumbnailBase64,
      isInstalled: data.isInstalled.present
          ? data.isInstalled.value
          : this.isInstalled,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      downloadCount: data.downloadCount.present
          ? data.downloadCount.value
          : this.downloadCount,
      rating: data.rating.present ? data.rating.value : this.rating,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomTemplatesTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('author: $author, ')
          ..write('paperPropertiesJson: $paperPropertiesJson, ')
          ..write('thumbnailBase64: $thumbnailBase64, ')
          ..write('isInstalled: $isInstalled, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('downloadCount: $downloadCount, ')
          ..write('rating: $rating, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    category,
    author,
    paperPropertiesJson,
    thumbnailBase64,
    isInstalled,
    isBuiltIn,
    downloadCount,
    rating,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomTemplatesTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.author == this.author &&
          other.paperPropertiesJson == this.paperPropertiesJson &&
          other.thumbnailBase64 == this.thumbnailBase64 &&
          other.isInstalled == this.isInstalled &&
          other.isBuiltIn == this.isBuiltIn &&
          other.downloadCount == this.downloadCount &&
          other.rating == this.rating &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomTemplatesTableCompanion
    extends UpdateCompanion<CustomTemplatesTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<String> category;
  final Value<String> author;
  final Value<String> paperPropertiesJson;
  final Value<String?> thumbnailBase64;
  final Value<bool> isInstalled;
  final Value<bool> isBuiltIn;
  final Value<int> downloadCount;
  final Value<double> rating;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CustomTemplatesTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.author = const Value.absent(),
    this.paperPropertiesJson = const Value.absent(),
    this.thumbnailBase64 = const Value.absent(),
    this.isInstalled = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.downloadCount = const Value.absent(),
    this.rating = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomTemplatesTableCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.author = const Value.absent(),
    required String paperPropertiesJson,
    this.thumbnailBase64 = const Value.absent(),
    this.isInstalled = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.downloadCount = const Value.absent(),
    this.rating = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       paperPropertiesJson = Value(paperPropertiesJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomTemplatesTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? author,
    Expression<String>? paperPropertiesJson,
    Expression<String>? thumbnailBase64,
    Expression<bool>? isInstalled,
    Expression<bool>? isBuiltIn,
    Expression<int>? downloadCount,
    Expression<double>? rating,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (author != null) 'author': author,
      if (paperPropertiesJson != null)
        'paper_properties_json': paperPropertiesJson,
      if (thumbnailBase64 != null) 'thumbnail_base64': thumbnailBase64,
      if (isInstalled != null) 'is_installed': isInstalled,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (downloadCount != null) 'download_count': downloadCount,
      if (rating != null) 'rating': rating,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomTemplatesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? description,
    Value<String>? category,
    Value<String>? author,
    Value<String>? paperPropertiesJson,
    Value<String?>? thumbnailBase64,
    Value<bool>? isInstalled,
    Value<bool>? isBuiltIn,
    Value<int>? downloadCount,
    Value<double>? rating,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CustomTemplatesTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      author: author ?? this.author,
      paperPropertiesJson: paperPropertiesJson ?? this.paperPropertiesJson,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
      isInstalled: isInstalled ?? this.isInstalled,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      downloadCount: downloadCount ?? this.downloadCount,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (paperPropertiesJson.present) {
      map['paper_properties_json'] = Variable<String>(
        paperPropertiesJson.value,
      );
    }
    if (thumbnailBase64.present) {
      map['thumbnail_base64'] = Variable<String>(thumbnailBase64.value);
    }
    if (isInstalled.present) {
      map['is_installed'] = Variable<bool>(isInstalled.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (downloadCount.present) {
      map['download_count'] = Variable<int>(downloadCount.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomTemplatesTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('author: $author, ')
          ..write('paperPropertiesJson: $paperPropertiesJson, ')
          ..write('thumbnailBase64: $thumbnailBase64, ')
          ..write('isInstalled: $isInstalled, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('downloadCount: $downloadCount, ')
          ..write('rating: $rating, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoldersTableTable foldersTable = $FoldersTableTable(this);
  late final $NotebooksTableTable notebooksTable = $NotebooksTableTable(this);
  late final $SectionsTableTable sectionsTable = $SectionsTableTable(this);
  late final $PagesTableTable pagesTable = $PagesTableTable(this);
  late final $StrokesTableTable strokesTable = $StrokesTableTable(this);
  late final $StickyNotesTableTable stickyNotesTable = $StickyNotesTableTable(
    this,
  );
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final $PageSearchIndexTableTable pageSearchIndexTable =
      $PageSearchIndexTableTable(this);
  late final $AudioRecordingsTableTable audioRecordingsTable =
      $AudioRecordingsTableTable(this);
  late final $AudioBookmarksTableTable audioBookmarksTable =
      $AudioBookmarksTableTable(this);
  late final $PageSnapshotsTableTable pageSnapshotsTable =
      $PageSnapshotsTableTable(this);
  late final $CustomTemplatesTableTable customTemplatesTable =
      $CustomTemplatesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foldersTable,
    notebooksTable,
    sectionsTable,
    pagesTable,
    strokesTable,
    stickyNotesTable,
    syncQueueTable,
    pageSearchIndexTable,
    audioRecordingsTable,
    audioBookmarksTable,
    pageSnapshotsTable,
    customTemplatesTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notebooks_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sections_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notebooks_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pages_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pages_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('strokes_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pages_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sticky_notes_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pages_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('page_search_index_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notebooks_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('page_search_index_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notebooks_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('audio_recordings_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pages_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('audio_recordings_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'audio_recordings_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('audio_bookmarks_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pages_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('page_snapshots_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notebooks_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('page_snapshots_table', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FoldersTableTableCreateCompanionBuilder =
    FoldersTableCompanion Function({
      required String id,
      Value<String> ownerId,
      Value<String?> parentId,
      required String name,
      Value<String> colorHex,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$FoldersTableTableUpdateCompanionBuilder =
    FoldersTableCompanion Function({
      Value<String> id,
      Value<String> ownerId,
      Value<String?> parentId,
      Value<String> name,
      Value<String> colorHex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$FoldersTableTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTableTable> {
  $$FoldersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoldersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTableTable> {
  $$FoldersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTableTable> {
  $$FoldersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$FoldersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTableTable,
          FoldersTableData,
          $$FoldersTableTableFilterComposer,
          $$FoldersTableTableOrderingComposer,
          $$FoldersTableTableAnnotationComposer,
          $$FoldersTableTableCreateCompanionBuilder,
          $$FoldersTableTableUpdateCompanionBuilder,
          (
            FoldersTableData,
            BaseReferences<_$AppDatabase, $FoldersTableTable, FoldersTableData>,
          ),
          FoldersTableData,
          PrefetchHooks Function()
        > {
  $$FoldersTableTableTableManager(_$AppDatabase db, $FoldersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersTableCompanion(
                id: id,
                ownerId: ownerId,
                parentId: parentId,
                name: name,
                colorHex: colorHex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> ownerId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                required String name,
                Value<String> colorHex = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersTableCompanion.insert(
                id: id,
                ownerId: ownerId,
                parentId: parentId,
                name: name,
                colorHex: colorHex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoldersTableTable, FoldersTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FoldersTableTable,
                    FoldersTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoldersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTableTable,
      FoldersTableData,
      $$FoldersTableTableFilterComposer,
      $$FoldersTableTableOrderingComposer,
      $$FoldersTableTableAnnotationComposer,
      $$FoldersTableTableCreateCompanionBuilder,
      $$FoldersTableTableUpdateCompanionBuilder,
      (
        FoldersTableData,
        BaseReferences<_$AppDatabase, $FoldersTableTable, FoldersTableData>,
      ),
      FoldersTableData,
      PrefetchHooks Function()
    >;
typedef $$NotebooksTableTableCreateCompanionBuilder =
    NotebooksTableCompanion Function({
      required String id,
      Value<String> ownerId,
      Value<String?> folderId,
      required String title,
      Value<String> description,
      Value<String> coverId,
      Value<String> coverColorHex,
      Value<String?> coverImageUrl,
      Value<String> paperTemplateId,
      Value<String> orientation,
      Value<String> pageSize,
      Value<int> pageCount,
      Value<bool> isFavorite,
      Value<bool> isArchived,
      Value<bool> isPdf,
      Value<String?> pdfPath,
      Value<int> revision,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$NotebooksTableTableUpdateCompanionBuilder =
    NotebooksTableCompanion Function({
      Value<String> id,
      Value<String> ownerId,
      Value<String?> folderId,
      Value<String> title,
      Value<String> description,
      Value<String> coverId,
      Value<String> coverColorHex,
      Value<String?> coverImageUrl,
      Value<String> paperTemplateId,
      Value<String> orientation,
      Value<String> pageSize,
      Value<int> pageCount,
      Value<bool> isFavorite,
      Value<bool> isArchived,
      Value<bool> isPdf,
      Value<String?> pdfPath,
      Value<int> revision,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$NotebooksTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $NotebooksTableTable,
          NotebooksTableData
        > {
  $$NotebooksTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SectionsTableTable, List<SectionsTableData>>
  _sectionsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sectionsTable,
    aliasName: 'notebooks_table__id__sections_table__notebook_id',
  );

  $$SectionsTableTableProcessedTableManager get sectionsTableRefs {
    final manager = $$SectionsTableTableTableManager(
      $_db,
      $_db.sectionsTable,
    ).filter((f) => f.notebookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sectionsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PagesTableTable, List<PagesTableData>>
  _pagesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pagesTable,
    aliasName: 'notebooks_table__id__pages_table__notebook_id',
  );

  $$PagesTableTableProcessedTableManager get pagesTableRefs {
    final manager = $$PagesTableTableTableManager(
      $_db,
      $_db.pagesTable,
    ).filter((f) => f.notebookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pagesTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PageSearchIndexTableTable,
    List<PageSearchIndexTableData>
  >
  _pageSearchIndexTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pageSearchIndexTable,
        aliasName: 'notebooks_table__id__page_search_index_table__notebook_id',
      );

  $$PageSearchIndexTableTableProcessedTableManager
  get pageSearchIndexTableRefs {
    final manager = $$PageSearchIndexTableTableTableManager(
      $_db,
      $_db.pageSearchIndexTable,
    ).filter((f) => f.notebookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pageSearchIndexTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AudioRecordingsTableTable,
    List<AudioRecordingsTableData>
  >
  _audioRecordingsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.audioRecordingsTable,
        aliasName: 'notebooks_table__id__audio_recordings_table__notebook_id',
      );

  $$AudioRecordingsTableTableProcessedTableManager
  get audioRecordingsTableRefs {
    final manager = $$AudioRecordingsTableTableTableManager(
      $_db,
      $_db.audioRecordingsTable,
    ).filter((f) => f.notebookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _audioRecordingsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PageSnapshotsTableTable,
    List<PageSnapshotsTableData>
  >
  _pageSnapshotsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pageSnapshotsTable,
        aliasName: 'notebooks_table__id__page_snapshots_table__notebook_id',
      );

  $$PageSnapshotsTableTableProcessedTableManager get pageSnapshotsTableRefs {
    final manager = $$PageSnapshotsTableTableTableManager(
      $_db,
      $_db.pageSnapshotsTable,
    ).filter((f) => f.notebookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pageSnapshotsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NotebooksTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotebooksTableTable> {
  $$NotebooksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverId => $composableBuilder(
    column: $table.coverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverColorHex => $composableBuilder(
    column: $table.coverColorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImageUrl => $composableBuilder(
    column: $table.coverImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paperTemplateId => $composableBuilder(
    column: $table.paperTemplateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageSize => $composableBuilder(
    column: $table.pageSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPdf => $composableBuilder(
    column: $table.isPdf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sectionsTableRefs(
    Expression<bool> Function($$SectionsTableTableFilterComposer f) f,
  ) {
    final $$SectionsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sectionsTable,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SectionsTableTableFilterComposer(
            $db: $db,
            $table: $db.sectionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pagesTableRefs(
    Expression<bool> Function($$PagesTableTableFilterComposer f) f,
  ) {
    final $$PagesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableFilterComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pageSearchIndexTableRefs(
    Expression<bool> Function($$PageSearchIndexTableTableFilterComposer f) f,
  ) {
    final $$PageSearchIndexTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pageSearchIndexTable,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PageSearchIndexTableTableFilterComposer(
            $db: $db,
            $table: $db.pageSearchIndexTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> audioRecordingsTableRefs(
    Expression<bool> Function($$AudioRecordingsTableTableFilterComposer f) f,
  ) {
    final $$AudioRecordingsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioRecordingsTable,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioRecordingsTableTableFilterComposer(
            $db: $db,
            $table: $db.audioRecordingsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pageSnapshotsTableRefs(
    Expression<bool> Function($$PageSnapshotsTableTableFilterComposer f) f,
  ) {
    final $$PageSnapshotsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pageSnapshotsTable,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PageSnapshotsTableTableFilterComposer(
            $db: $db,
            $table: $db.pageSnapshotsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotebooksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotebooksTableTable> {
  $$NotebooksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverId => $composableBuilder(
    column: $table.coverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverColorHex => $composableBuilder(
    column: $table.coverColorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImageUrl => $composableBuilder(
    column: $table.coverImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paperTemplateId => $composableBuilder(
    column: $table.paperTemplateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageSize => $composableBuilder(
    column: $table.pageSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPdf => $composableBuilder(
    column: $table.isPdf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotebooksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotebooksTableTable> {
  $$NotebooksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverId =>
      $composableBuilder(column: $table.coverId, builder: (column) => column);

  GeneratedColumn<String> get coverColorHex => $composableBuilder(
    column: $table.coverColorHex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverImageUrl => $composableBuilder(
    column: $table.coverImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paperTemplateId => $composableBuilder(
    column: $table.paperTemplateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pageSize =>
      $composableBuilder(column: $table.pageSize, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPdf =>
      $composableBuilder(column: $table.isPdf, builder: (column) => column);

  GeneratedColumn<String> get pdfPath =>
      $composableBuilder(column: $table.pdfPath, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  Expression<T> sectionsTableRefs<T extends Object>(
    Expression<T> Function($$SectionsTableTableAnnotationComposer a) f,
  ) {
    final $$SectionsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sectionsTable,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SectionsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.sectionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pagesTableRefs<T extends Object>(
    Expression<T> Function($$PagesTableTableAnnotationComposer a) f,
  ) {
    final $$PagesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pageSearchIndexTableRefs<T extends Object>(
    Expression<T> Function($$PageSearchIndexTableTableAnnotationComposer a) f,
  ) {
    final $$PageSearchIndexTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.pageSearchIndexTable,
          getReferencedColumn: (t) => t.notebookId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PageSearchIndexTableTableAnnotationComposer(
                $db: $db,
                $table: $db.pageSearchIndexTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> audioRecordingsTableRefs<T extends Object>(
    Expression<T> Function($$AudioRecordingsTableTableAnnotationComposer a) f,
  ) {
    final $$AudioRecordingsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.audioRecordingsTable,
          getReferencedColumn: (t) => t.notebookId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AudioRecordingsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.audioRecordingsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> pageSnapshotsTableRefs<T extends Object>(
    Expression<T> Function($$PageSnapshotsTableTableAnnotationComposer a) f,
  ) {
    final $$PageSnapshotsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.pageSnapshotsTable,
          getReferencedColumn: (t) => t.notebookId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PageSnapshotsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.pageSnapshotsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$NotebooksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotebooksTableTable,
          NotebooksTableData,
          $$NotebooksTableTableFilterComposer,
          $$NotebooksTableTableOrderingComposer,
          $$NotebooksTableTableAnnotationComposer,
          $$NotebooksTableTableCreateCompanionBuilder,
          $$NotebooksTableTableUpdateCompanionBuilder,
          (NotebooksTableData, $$NotebooksTableTableReferences),
          NotebooksTableData,
          PrefetchHooks Function({
            bool sectionsTableRefs,
            bool pagesTableRefs,
            bool pageSearchIndexTableRefs,
            bool audioRecordingsTableRefs,
            bool pageSnapshotsTableRefs,
          })
        > {
  $$NotebooksTableTableTableManager(
    _$AppDatabase db,
    $NotebooksTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotebooksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotebooksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotebooksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> coverId = const Value.absent(),
                Value<String> coverColorHex = const Value.absent(),
                Value<String?> coverImageUrl = const Value.absent(),
                Value<String> paperTemplateId = const Value.absent(),
                Value<String> orientation = const Value.absent(),
                Value<String> pageSize = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isPdf = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotebooksTableCompanion(
                id: id,
                ownerId: ownerId,
                folderId: folderId,
                title: title,
                description: description,
                coverId: coverId,
                coverColorHex: coverColorHex,
                coverImageUrl: coverImageUrl,
                paperTemplateId: paperTemplateId,
                orientation: orientation,
                pageSize: pageSize,
                pageCount: pageCount,
                isFavorite: isFavorite,
                isArchived: isArchived,
                isPdf: isPdf,
                pdfPath: pdfPath,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> ownerId = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                required String title,
                Value<String> description = const Value.absent(),
                Value<String> coverId = const Value.absent(),
                Value<String> coverColorHex = const Value.absent(),
                Value<String?> coverImageUrl = const Value.absent(),
                Value<String> paperTemplateId = const Value.absent(),
                Value<String> orientation = const Value.absent(),
                Value<String> pageSize = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isPdf = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<int> revision = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotebooksTableCompanion.insert(
                id: id,
                ownerId: ownerId,
                folderId: folderId,
                title: title,
                description: description,
                coverId: coverId,
                coverColorHex: coverColorHex,
                coverImageUrl: coverImageUrl,
                paperTemplateId: paperTemplateId,
                orientation: orientation,
                pageSize: pageSize,
                pageCount: pageCount,
                isFavorite: isFavorite,
                isArchived: isArchived,
                isPdf: isPdf,
                pdfPath: pdfPath,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotebooksTableTable, NotebooksTableData>(table),
                  $$NotebooksTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sectionsTableRefs = false,
                pagesTableRefs = false,
                pageSearchIndexTableRefs = false,
                audioRecordingsTableRefs = false,
                pageSnapshotsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sectionsTableRefs) db.sectionsTable,
                    if (pagesTableRefs) db.pagesTable,
                    if (pageSearchIndexTableRefs) db.pageSearchIndexTable,
                    if (audioRecordingsTableRefs) db.audioRecordingsTable,
                    if (pageSnapshotsTableRefs) db.pageSnapshotsTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sectionsTableRefs)
                        await $_getPrefetchedDataByColumns<
                          NotebooksTableData,
                          $NotebooksTableTable,
                          SectionsTableData,
                          $SectionsTableTable
                        >(
                          currentTable: table,
                          referencedTable: $$NotebooksTableTableReferences
                              ._sectionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotebooksTableTableReferences(
                                db,
                                table,
                                p0,
                              ).sectionsTableRefs,
                          currentColumn: 'id',
                          referencedColumn: 'notebook_id',
                          typedResults: items,
                        ),
                      if (pagesTableRefs)
                        await $_getPrefetchedDataByColumns<
                          NotebooksTableData,
                          $NotebooksTableTable,
                          PagesTableData,
                          $PagesTableTable
                        >(
                          currentTable: table,
                          referencedTable: $$NotebooksTableTableReferences
                              ._pagesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotebooksTableTableReferences(
                                db,
                                table,
                                p0,
                              ).pagesTableRefs,
                          currentColumn: 'id',
                          referencedColumn: 'notebook_id',
                          typedResults: items,
                        ),
                      if (pageSearchIndexTableRefs)
                        await $_getPrefetchedDataByColumns<
                          NotebooksTableData,
                          $NotebooksTableTable,
                          PageSearchIndexTableData,
                          $PageSearchIndexTableTable
                        >(
                          currentTable: table,
                          referencedTable: $$NotebooksTableTableReferences
                              ._pageSearchIndexTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotebooksTableTableReferences(
                                db,
                                table,
                                p0,
                              ).pageSearchIndexTableRefs,
                          currentColumn: 'id',
                          referencedColumn: 'notebook_id',
                          typedResults: items,
                        ),
                      if (audioRecordingsTableRefs)
                        await $_getPrefetchedDataByColumns<
                          NotebooksTableData,
                          $NotebooksTableTable,
                          AudioRecordingsTableData,
                          $AudioRecordingsTableTable
                        >(
                          currentTable: table,
                          referencedTable: $$NotebooksTableTableReferences
                              ._audioRecordingsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotebooksTableTableReferences(
                                db,
                                table,
                                p0,
                              ).audioRecordingsTableRefs,
                          currentColumn: 'id',
                          referencedColumn: 'notebook_id',
                          typedResults: items,
                        ),
                      if (pageSnapshotsTableRefs)
                        await $_getPrefetchedDataByColumns<
                          NotebooksTableData,
                          $NotebooksTableTable,
                          PageSnapshotsTableData,
                          $PageSnapshotsTableTable
                        >(
                          currentTable: table,
                          referencedTable: $$NotebooksTableTableReferences
                              ._pageSnapshotsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotebooksTableTableReferences(
                                db,
                                table,
                                p0,
                              ).pageSnapshotsTableRefs,
                          currentColumn: 'id',
                          referencedColumn: 'notebook_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$NotebooksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotebooksTableTable,
      NotebooksTableData,
      $$NotebooksTableTableFilterComposer,
      $$NotebooksTableTableOrderingComposer,
      $$NotebooksTableTableAnnotationComposer,
      $$NotebooksTableTableCreateCompanionBuilder,
      $$NotebooksTableTableUpdateCompanionBuilder,
      (NotebooksTableData, $$NotebooksTableTableReferences),
      NotebooksTableData,
      PrefetchHooks Function({
        bool sectionsTableRefs,
        bool pagesTableRefs,
        bool pageSearchIndexTableRefs,
        bool audioRecordingsTableRefs,
        bool pageSnapshotsTableRefs,
      })
    >;
typedef $$SectionsTableTableCreateCompanionBuilder =
    SectionsTableCompanion Function({
      required String id,
      required String notebookId,
      required String name,
      Value<int> orderIndex,
      Value<String> colorHex,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SectionsTableTableUpdateCompanionBuilder =
    SectionsTableCompanion Function({
      Value<String> id,
      Value<String> notebookId,
      Value<String> name,
      Value<int> orderIndex,
      Value<String> colorHex,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$SectionsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $SectionsTableTable, SectionsTableData> {
  $$SectionsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $NotebooksTableTable _notebookIdTable(_$AppDatabase db) => db
      .notebooksTable
      .createAlias('sections_table__notebook_id__notebooks_table__id');

  $$NotebooksTableTableProcessedTableManager get notebookId {
    final $_column = $_itemColumn<String>('notebook_id')!;

    final manager = $$NotebooksTableTableTableManager(
      $_db,
      $_db.notebooksTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SectionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SectionsTableTable> {
  $$SectionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$NotebooksTableTableFilterComposer get notebookId {
    final $$NotebooksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableFilterComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SectionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SectionsTableTable> {
  $$SectionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotebooksTableTableOrderingComposer get notebookId {
    final $$NotebooksTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableOrderingComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SectionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SectionsTableTable> {
  $$SectionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$NotebooksTableTableAnnotationComposer get notebookId {
    final $$NotebooksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SectionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SectionsTableTable,
          SectionsTableData,
          $$SectionsTableTableFilterComposer,
          $$SectionsTableTableOrderingComposer,
          $$SectionsTableTableAnnotationComposer,
          $$SectionsTableTableCreateCompanionBuilder,
          $$SectionsTableTableUpdateCompanionBuilder,
          (SectionsTableData, $$SectionsTableTableReferences),
          SectionsTableData,
          PrefetchHooks Function({bool notebookId})
        > {
  $$SectionsTableTableTableManager(_$AppDatabase db, $SectionsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SectionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SectionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SectionsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> notebookId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SectionsTableCompanion(
                id: id,
                notebookId: notebookId,
                name: name,
                orderIndex: orderIndex,
                colorHex: colorHex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String notebookId,
                required String name,
                Value<int> orderIndex = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SectionsTableCompanion.insert(
                id: id,
                notebookId: notebookId,
                name: name,
                orderIndex: orderIndex,
                colorHex: colorHex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SectionsTableTable, SectionsTableData>(table),
                  $$SectionsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notebookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (notebookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.notebookId,
                                referencedTable: $$SectionsTableTableReferences
                                    ._notebookIdTable(db),
                                referencedColumn: $$SectionsTableTableReferences
                                    ._notebookIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SectionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SectionsTableTable,
      SectionsTableData,
      $$SectionsTableTableFilterComposer,
      $$SectionsTableTableOrderingComposer,
      $$SectionsTableTableAnnotationComposer,
      $$SectionsTableTableCreateCompanionBuilder,
      $$SectionsTableTableUpdateCompanionBuilder,
      (SectionsTableData, $$SectionsTableTableReferences),
      SectionsTableData,
      PrefetchHooks Function({bool notebookId})
    >;
typedef $$PagesTableTableCreateCompanionBuilder =
    PagesTableCompanion Function({
      required String id,
      required String notebookId,
      Value<String?> sectionId,
      required int pageNumber,
      Value<String> templateId,
      Value<String?> backgroundColor,
      Value<String?> templatePropertiesJson,
      Value<bool> isBookmarked,
      Value<int?> pdfPageIndex,
      Value<double> width,
      Value<double> height,
      Value<int> revision,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PagesTableTableUpdateCompanionBuilder =
    PagesTableCompanion Function({
      Value<String> id,
      Value<String> notebookId,
      Value<String?> sectionId,
      Value<int> pageNumber,
      Value<String> templateId,
      Value<String?> backgroundColor,
      Value<String?> templatePropertiesJson,
      Value<bool> isBookmarked,
      Value<int?> pdfPageIndex,
      Value<double> width,
      Value<double> height,
      Value<int> revision,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PagesTableTableReferences
    extends BaseReferences<_$AppDatabase, $PagesTableTable, PagesTableData> {
  $$PagesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotebooksTableTable _notebookIdTable(_$AppDatabase db) => db
      .notebooksTable
      .createAlias('pages_table__notebook_id__notebooks_table__id');

  $$NotebooksTableTableProcessedTableManager get notebookId {
    final $_column = $_itemColumn<String>('notebook_id')!;

    final manager = $$NotebooksTableTableTableManager(
      $_db,
      $_db.notebooksTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StrokesTableTable, List<StrokesTableData>>
  _strokesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.strokesTable,
    aliasName: 'pages_table__id__strokes_table__page_id',
  );

  $$StrokesTableTableProcessedTableManager get strokesTableRefs {
    final manager = $$StrokesTableTableTableManager(
      $_db,
      $_db.strokesTable,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_strokesTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StickyNotesTableTable, List<StickyNotesTableData>>
  _stickyNotesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stickyNotesTable,
    aliasName: 'pages_table__id__sticky_notes_table__page_id',
  );

  $$StickyNotesTableTableProcessedTableManager get stickyNotesTableRefs {
    final manager = $$StickyNotesTableTableTableManager(
      $_db,
      $_db.stickyNotesTable,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _stickyNotesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PageSearchIndexTableTable,
    List<PageSearchIndexTableData>
  >
  _pageSearchIndexTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pageSearchIndexTable,
        aliasName: 'pages_table__id__page_search_index_table__page_id',
      );

  $$PageSearchIndexTableTableProcessedTableManager
  get pageSearchIndexTableRefs {
    final manager = $$PageSearchIndexTableTableTableManager(
      $_db,
      $_db.pageSearchIndexTable,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pageSearchIndexTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AudioRecordingsTableTable,
    List<AudioRecordingsTableData>
  >
  _audioRecordingsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.audioRecordingsTable,
        aliasName: 'pages_table__id__audio_recordings_table__page_id',
      );

  $$AudioRecordingsTableTableProcessedTableManager
  get audioRecordingsTableRefs {
    final manager = $$AudioRecordingsTableTableTableManager(
      $_db,
      $_db.audioRecordingsTable,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _audioRecordingsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PageSnapshotsTableTable,
    List<PageSnapshotsTableData>
  >
  _pageSnapshotsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pageSnapshotsTable,
        aliasName: 'pages_table__id__page_snapshots_table__page_id',
      );

  $$PageSnapshotsTableTableProcessedTableManager get pageSnapshotsTableRefs {
    final manager = $$PageSnapshotsTableTableTableManager(
      $_db,
      $_db.pageSnapshotsTable,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pageSnapshotsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PagesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PagesTableTable> {
  $$PagesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionId => $composableBuilder(
    column: $table.sectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templatePropertiesJson => $composableBuilder(
    column: $table.templatePropertiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pdfPageIndex => $composableBuilder(
    column: $table.pdfPageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$NotebooksTableTableFilterComposer get notebookId {
    final $$NotebooksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableFilterComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> strokesTableRefs(
    Expression<bool> Function($$StrokesTableTableFilterComposer f) f,
  ) {
    final $$StrokesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.strokesTable,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StrokesTableTableFilterComposer(
            $db: $db,
            $table: $db.strokesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stickyNotesTableRefs(
    Expression<bool> Function($$StickyNotesTableTableFilterComposer f) f,
  ) {
    final $$StickyNotesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stickyNotesTable,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StickyNotesTableTableFilterComposer(
            $db: $db,
            $table: $db.stickyNotesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pageSearchIndexTableRefs(
    Expression<bool> Function($$PageSearchIndexTableTableFilterComposer f) f,
  ) {
    final $$PageSearchIndexTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pageSearchIndexTable,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PageSearchIndexTableTableFilterComposer(
            $db: $db,
            $table: $db.pageSearchIndexTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> audioRecordingsTableRefs(
    Expression<bool> Function($$AudioRecordingsTableTableFilterComposer f) f,
  ) {
    final $$AudioRecordingsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioRecordingsTable,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioRecordingsTableTableFilterComposer(
            $db: $db,
            $table: $db.audioRecordingsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pageSnapshotsTableRefs(
    Expression<bool> Function($$PageSnapshotsTableTableFilterComposer f) f,
  ) {
    final $$PageSnapshotsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pageSnapshotsTable,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PageSnapshotsTableTableFilterComposer(
            $db: $db,
            $table: $db.pageSnapshotsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PagesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PagesTableTable> {
  $$PagesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionId => $composableBuilder(
    column: $table.sectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templatePropertiesJson => $composableBuilder(
    column: $table.templatePropertiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pdfPageIndex => $composableBuilder(
    column: $table.pdfPageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotebooksTableTableOrderingComposer get notebookId {
    final $$NotebooksTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableOrderingComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagesTableTable> {
  $$PagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sectionId =>
      $composableBuilder(column: $table.sectionId, builder: (column) => column);

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templatePropertiesJson => $composableBuilder(
    column: $table.templatePropertiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pdfPageIndex => $composableBuilder(
    column: $table.pdfPageIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$NotebooksTableTableAnnotationComposer get notebookId {
    final $$NotebooksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> strokesTableRefs<T extends Object>(
    Expression<T> Function($$StrokesTableTableAnnotationComposer a) f,
  ) {
    final $$StrokesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.strokesTable,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StrokesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.strokesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> stickyNotesTableRefs<T extends Object>(
    Expression<T> Function($$StickyNotesTableTableAnnotationComposer a) f,
  ) {
    final $$StickyNotesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stickyNotesTable,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StickyNotesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.stickyNotesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pageSearchIndexTableRefs<T extends Object>(
    Expression<T> Function($$PageSearchIndexTableTableAnnotationComposer a) f,
  ) {
    final $$PageSearchIndexTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.pageSearchIndexTable,
          getReferencedColumn: (t) => t.pageId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PageSearchIndexTableTableAnnotationComposer(
                $db: $db,
                $table: $db.pageSearchIndexTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> audioRecordingsTableRefs<T extends Object>(
    Expression<T> Function($$AudioRecordingsTableTableAnnotationComposer a) f,
  ) {
    final $$AudioRecordingsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.audioRecordingsTable,
          getReferencedColumn: (t) => t.pageId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AudioRecordingsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.audioRecordingsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> pageSnapshotsTableRefs<T extends Object>(
    Expression<T> Function($$PageSnapshotsTableTableAnnotationComposer a) f,
  ) {
    final $$PageSnapshotsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.pageSnapshotsTable,
          getReferencedColumn: (t) => t.pageId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PageSnapshotsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.pageSnapshotsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PagesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PagesTableTable,
          PagesTableData,
          $$PagesTableTableFilterComposer,
          $$PagesTableTableOrderingComposer,
          $$PagesTableTableAnnotationComposer,
          $$PagesTableTableCreateCompanionBuilder,
          $$PagesTableTableUpdateCompanionBuilder,
          (PagesTableData, $$PagesTableTableReferences),
          PagesTableData,
          PrefetchHooks Function({
            bool notebookId,
            bool strokesTableRefs,
            bool stickyNotesTableRefs,
            bool pageSearchIndexTableRefs,
            bool audioRecordingsTableRefs,
            bool pageSnapshotsTableRefs,
          })
        > {
  $$PagesTableTableTableManager(_$AppDatabase db, $PagesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> notebookId = const Value.absent(),
                Value<String?> sectionId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String?> backgroundColor = const Value.absent(),
                Value<String?> templatePropertiesJson = const Value.absent(),
                Value<bool> isBookmarked = const Value.absent(),
                Value<int?> pdfPageIndex = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PagesTableCompanion(
                id: id,
                notebookId: notebookId,
                sectionId: sectionId,
                pageNumber: pageNumber,
                templateId: templateId,
                backgroundColor: backgroundColor,
                templatePropertiesJson: templatePropertiesJson,
                isBookmarked: isBookmarked,
                pdfPageIndex: pdfPageIndex,
                width: width,
                height: height,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String notebookId,
                Value<String?> sectionId = const Value.absent(),
                required int pageNumber,
                Value<String> templateId = const Value.absent(),
                Value<String?> backgroundColor = const Value.absent(),
                Value<String?> templatePropertiesJson = const Value.absent(),
                Value<bool> isBookmarked = const Value.absent(),
                Value<int?> pdfPageIndex = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<int> revision = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PagesTableCompanion.insert(
                id: id,
                notebookId: notebookId,
                sectionId: sectionId,
                pageNumber: pageNumber,
                templateId: templateId,
                backgroundColor: backgroundColor,
                templatePropertiesJson: templatePropertiesJson,
                isBookmarked: isBookmarked,
                pdfPageIndex: pdfPageIndex,
                width: width,
                height: height,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PagesTableTable, PagesTableData>(table),
                  $$PagesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                notebookId = false,
                strokesTableRefs = false,
                stickyNotesTableRefs = false,
                pageSearchIndexTableRefs = false,
                audioRecordingsTableRefs = false,
                pageSnapshotsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (strokesTableRefs) db.strokesTable,
                    if (stickyNotesTableRefs) db.stickyNotesTable,
                    if (pageSearchIndexTableRefs) db.pageSearchIndexTable,
                    if (audioRecordingsTableRefs) db.audioRecordingsTable,
                    if (pageSnapshotsTableRefs) db.pageSnapshotsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (notebookId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.notebookId,
                                    referencedTable: $$PagesTableTableReferences
                                        ._notebookIdTable(db),
                                    referencedColumn:
                                        $$PagesTableTableReferences
                                            ._notebookIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (strokesTableRefs)
                        await $_getPrefetchedDataByColumns<
                          PagesTableData,
                          $PagesTableTable,
                          StrokesTableData,
                          $StrokesTableTable
                        >(
                          currentTable: table,
                          referencedTable: $$PagesTableTableReferences
                              ._strokesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PagesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).strokesTableRefs,
                          currentColumn: 'id',
                          referencedColumn: 'page_id',
                          typedResults: items,
                        ),
                      if (stickyNotesTableRefs)
                        await $_getPrefetchedDataByColumns<
                          PagesTableData,
                          $PagesTableTable,
                          StickyNotesTableData,
                          $StickyNotesTableTable
                        >(
                          currentTable: table,
                          referencedTable: $$PagesTableTableReferences
                              ._stickyNotesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PagesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).stickyNotesTableRefs,
                          currentColumn: 'id',
                          referencedColumn: 'page_id',
                          typedResults: items,
                        ),
                      if (pageSearchIndexTableRefs)
                        await $_getPrefetchedDataByColumns<
                          PagesTableData,
                          $PagesTableTable,
                          PageSearchIndexTableData,
                          $PageSearchIndexTableTable
                        >(
                          currentTable: table,
                          referencedTable: $$PagesTableTableReferences
                              ._pageSearchIndexTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PagesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).pageSearchIndexTableRefs,
                          currentColumn: 'id',
                          referencedColumn: 'page_id',
                          typedResults: items,
                        ),
                      if (audioRecordingsTableRefs)
                        await $_getPrefetchedDataByColumns<
                          PagesTableData,
                          $PagesTableTable,
                          AudioRecordingsTableData,
                          $AudioRecordingsTableTable
                        >(
                          currentTable: table,
                          referencedTable: $$PagesTableTableReferences
                              ._audioRecordingsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PagesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).audioRecordingsTableRefs,
                          currentColumn: 'id',
                          referencedColumn: 'page_id',
                          typedResults: items,
                        ),
                      if (pageSnapshotsTableRefs)
                        await $_getPrefetchedDataByColumns<
                          PagesTableData,
                          $PagesTableTable,
                          PageSnapshotsTableData,
                          $PageSnapshotsTableTable
                        >(
                          currentTable: table,
                          referencedTable: $$PagesTableTableReferences
                              ._pageSnapshotsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PagesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).pageSnapshotsTableRefs,
                          currentColumn: 'id',
                          referencedColumn: 'page_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PagesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PagesTableTable,
      PagesTableData,
      $$PagesTableTableFilterComposer,
      $$PagesTableTableOrderingComposer,
      $$PagesTableTableAnnotationComposer,
      $$PagesTableTableCreateCompanionBuilder,
      $$PagesTableTableUpdateCompanionBuilder,
      (PagesTableData, $$PagesTableTableReferences),
      PagesTableData,
      PrefetchHooks Function({
        bool notebookId,
        bool strokesTableRefs,
        bool stickyNotesTableRefs,
        bool pageSearchIndexTableRefs,
        bool audioRecordingsTableRefs,
        bool pageSnapshotsTableRefs,
      })
    >;
typedef $$StrokesTableTableCreateCompanionBuilder =
    StrokesTableCompanion Function({
      required String id,
      required String pageId,
      required String toolType,
      required int colorValue,
      required double width,
      required double opacity,
      required String pointsJson,
      required String boundingBoxJson,
      required DateTime createdAt,
      Value<DateTime?> deletedAt,
      Value<int> revision,
      Value<int> rowid,
    });
typedef $$StrokesTableTableUpdateCompanionBuilder =
    StrokesTableCompanion Function({
      Value<String> id,
      Value<String> pageId,
      Value<String> toolType,
      Value<int> colorValue,
      Value<double> width,
      Value<double> opacity,
      Value<String> pointsJson,
      Value<String> boundingBoxJson,
      Value<DateTime> createdAt,
      Value<DateTime?> deletedAt,
      Value<int> revision,
      Value<int> rowid,
    });

final class $$StrokesTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $StrokesTableTable, StrokesTableData> {
  $$StrokesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PagesTableTable _pageIdTable(_$AppDatabase db) =>
      db.pagesTable.createAlias('strokes_table__page_id__pages_table__id');

  $$PagesTableTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<String>('page_id')!;

    final manager = $$PagesTableTableTableManager(
      $_db,
      $_db.pagesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StrokesTableTableFilterComposer
    extends Composer<_$AppDatabase, $StrokesTableTable> {
  $$StrokesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolType => $composableBuilder(
    column: $table.toolType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointsJson => $composableBuilder(
    column: $table.pointsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boundingBoxJson => $composableBuilder(
    column: $table.boundingBoxJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  $$PagesTableTableFilterComposer get pageId {
    final $$PagesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableFilterComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StrokesTableTable> {
  $$StrokesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolType => $composableBuilder(
    column: $table.toolType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointsJson => $composableBuilder(
    column: $table.pointsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boundingBoxJson => $composableBuilder(
    column: $table.boundingBoxJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  $$PagesTableTableOrderingComposer get pageId {
    final $$PagesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableOrderingComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StrokesTableTable> {
  $$StrokesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get toolType =>
      $composableBuilder(column: $table.toolType, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get opacity =>
      $composableBuilder(column: $table.opacity, builder: (column) => column);

  GeneratedColumn<String> get pointsJson => $composableBuilder(
    column: $table.pointsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boundingBoxJson => $composableBuilder(
    column: $table.boundingBoxJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  $$PagesTableTableAnnotationComposer get pageId {
    final $$PagesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StrokesTableTable,
          StrokesTableData,
          $$StrokesTableTableFilterComposer,
          $$StrokesTableTableOrderingComposer,
          $$StrokesTableTableAnnotationComposer,
          $$StrokesTableTableCreateCompanionBuilder,
          $$StrokesTableTableUpdateCompanionBuilder,
          (StrokesTableData, $$StrokesTableTableReferences),
          StrokesTableData,
          PrefetchHooks Function({bool pageId})
        > {
  $$StrokesTableTableTableManager(_$AppDatabase db, $StrokesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StrokesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StrokesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StrokesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<String> toolType = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> opacity = const Value.absent(),
                Value<String> pointsJson = const Value.absent(),
                Value<String> boundingBoxJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrokesTableCompanion(
                id: id,
                pageId: pageId,
                toolType: toolType,
                colorValue: colorValue,
                width: width,
                opacity: opacity,
                pointsJson: pointsJson,
                boundingBoxJson: boundingBoxJson,
                createdAt: createdAt,
                deletedAt: deletedAt,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pageId,
                required String toolType,
                required int colorValue,
                required double width,
                required double opacity,
                required String pointsJson,
                required String boundingBoxJson,
                required DateTime createdAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrokesTableCompanion.insert(
                id: id,
                pageId: pageId,
                toolType: toolType,
                colorValue: colorValue,
                width: width,
                opacity: opacity,
                pointsJson: pointsJson,
                boundingBoxJson: boundingBoxJson,
                createdAt: createdAt,
                deletedAt: deletedAt,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StrokesTableTable, StrokesTableData>(table),
                  $$StrokesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pageId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pageId,
                                referencedTable: $$StrokesTableTableReferences
                                    ._pageIdTable(db),
                                referencedColumn: $$StrokesTableTableReferences
                                    ._pageIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StrokesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StrokesTableTable,
      StrokesTableData,
      $$StrokesTableTableFilterComposer,
      $$StrokesTableTableOrderingComposer,
      $$StrokesTableTableAnnotationComposer,
      $$StrokesTableTableCreateCompanionBuilder,
      $$StrokesTableTableUpdateCompanionBuilder,
      (StrokesTableData, $$StrokesTableTableReferences),
      StrokesTableData,
      PrefetchHooks Function({bool pageId})
    >;
typedef $$StickyNotesTableTableCreateCompanionBuilder =
    StickyNotesTableCompanion Function({
      required String id,
      required String pageId,
      required double x,
      required double y,
      Value<double> width,
      Value<double> height,
      required String content,
      Value<String> colorHex,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StickyNotesTableTableUpdateCompanionBuilder =
    StickyNotesTableCompanion Function({
      Value<String> id,
      Value<String> pageId,
      Value<double> x,
      Value<double> y,
      Value<double> width,
      Value<double> height,
      Value<String> content,
      Value<String> colorHex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$StickyNotesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $StickyNotesTableTable,
          StickyNotesTableData
        > {
  $$StickyNotesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PagesTableTable _pageIdTable(_$AppDatabase db) =>
      db.pagesTable.createAlias('sticky_notes_table__page_id__pages_table__id');

  $$PagesTableTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<String>('page_id')!;

    final manager = $$PagesTableTableTableManager(
      $_db,
      $_db.pagesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StickyNotesTableTableFilterComposer
    extends Composer<_$AppDatabase, $StickyNotesTableTable> {
  $$StickyNotesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PagesTableTableFilterComposer get pageId {
    final $$PagesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableFilterComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StickyNotesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StickyNotesTableTable> {
  $$StickyNotesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PagesTableTableOrderingComposer get pageId {
    final $$PagesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableOrderingComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StickyNotesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StickyNotesTableTable> {
  $$StickyNotesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PagesTableTableAnnotationComposer get pageId {
    final $$PagesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StickyNotesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StickyNotesTableTable,
          StickyNotesTableData,
          $$StickyNotesTableTableFilterComposer,
          $$StickyNotesTableTableOrderingComposer,
          $$StickyNotesTableTableAnnotationComposer,
          $$StickyNotesTableTableCreateCompanionBuilder,
          $$StickyNotesTableTableUpdateCompanionBuilder,
          (StickyNotesTableData, $$StickyNotesTableTableReferences),
          StickyNotesTableData,
          PrefetchHooks Function({bool pageId})
        > {
  $$StickyNotesTableTableTableManager(
    _$AppDatabase db,
    $StickyNotesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StickyNotesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StickyNotesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StickyNotesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StickyNotesTableCompanion(
                id: id,
                pageId: pageId,
                x: x,
                y: y,
                width: width,
                height: height,
                content: content,
                colorHex: colorHex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pageId,
                required double x,
                required double y,
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                required String content,
                Value<String> colorHex = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StickyNotesTableCompanion.insert(
                id: id,
                pageId: pageId,
                x: x,
                y: y,
                width: width,
                height: height,
                content: content,
                colorHex: colorHex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StickyNotesTableTable, StickyNotesTableData>(
                    table,
                  ),
                  $$StickyNotesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pageId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pageId,
                                referencedTable:
                                    $$StickyNotesTableTableReferences
                                        ._pageIdTable(db),
                                referencedColumn:
                                    $$StickyNotesTableTableReferences
                                        ._pageIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StickyNotesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StickyNotesTableTable,
      StickyNotesTableData,
      $$StickyNotesTableTableFilterComposer,
      $$StickyNotesTableTableOrderingComposer,
      $$StickyNotesTableTableAnnotationComposer,
      $$StickyNotesTableTableCreateCompanionBuilder,
      $$StickyNotesTableTableUpdateCompanionBuilder,
      (StickyNotesTableData, $$StickyNotesTableTableReferences),
      StickyNotesTableData,
      PrefetchHooks Function({bool pageId})
    >;
typedef $$SyncQueueTableTableCreateCompanionBuilder =
    SyncQueueTableCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      required String operationType,
      required String payloadJson,
      Value<int> revision,
      required DateTime createdAt,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncQueueTableTableUpdateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<int> revision,
      Value<DateTime> createdAt,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTableTable,
          SyncQueueTableData,
          $$SyncQueueTableTableFilterComposer,
          $$SyncQueueTableTableOrderingComposer,
          $$SyncQueueTableTableAnnotationComposer,
          $$SyncQueueTableTableCreateCompanionBuilder,
          $$SyncQueueTableTableUpdateCompanionBuilder,
          (
            SyncQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueTableTable,
              SyncQueueTableData
            >,
          ),
          SyncQueueTableData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableTableManager(
    _$AppDatabase db,
    $SyncQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueTableCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operationType: operationType,
                payloadJson: payloadJson,
                revision: revision,
                createdAt: createdAt,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String operationType,
                required String payloadJson,
                Value<int> revision = const Value.absent(),
                required DateTime createdAt,
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueTableCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operationType: operationType,
                payloadJson: payloadJson,
                revision: revision,
                createdAt: createdAt,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTableTable, SyncQueueTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncQueueTableTable,
                    SyncQueueTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTableTable,
      SyncQueueTableData,
      $$SyncQueueTableTableFilterComposer,
      $$SyncQueueTableTableOrderingComposer,
      $$SyncQueueTableTableAnnotationComposer,
      $$SyncQueueTableTableCreateCompanionBuilder,
      $$SyncQueueTableTableUpdateCompanionBuilder,
      (
        SyncQueueTableData,
        BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>,
      ),
      SyncQueueTableData,
      PrefetchHooks Function()
    >;
typedef $$PageSearchIndexTableTableCreateCompanionBuilder =
    PageSearchIndexTableCompanion Function({
      required String id,
      required String pageId,
      required String notebookId,
      required String sourceType,
      required String textContent,
      Value<String?> boundingBoxesJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PageSearchIndexTableTableUpdateCompanionBuilder =
    PageSearchIndexTableCompanion Function({
      Value<String> id,
      Value<String> pageId,
      Value<String> notebookId,
      Value<String> sourceType,
      Value<String> textContent,
      Value<String?> boundingBoxesJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PageSearchIndexTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PageSearchIndexTableTable,
          PageSearchIndexTableData
        > {
  $$PageSearchIndexTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PagesTableTable _pageIdTable(_$AppDatabase db) => db.pagesTable
      .createAlias('page_search_index_table__page_id__pages_table__id');

  $$PagesTableTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<String>('page_id')!;

    final manager = $$PagesTableTableTableManager(
      $_db,
      $_db.pagesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NotebooksTableTable _notebookIdTable(_$AppDatabase db) => db
      .notebooksTable
      .createAlias('page_search_index_table__notebook_id__notebooks_table__id');

  $$NotebooksTableTableProcessedTableManager get notebookId {
    final $_column = $_itemColumn<String>('notebook_id')!;

    final manager = $$NotebooksTableTableTableManager(
      $_db,
      $_db.notebooksTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PageSearchIndexTableTableFilterComposer
    extends Composer<_$AppDatabase, $PageSearchIndexTableTable> {
  $$PageSearchIndexTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boundingBoxesJson => $composableBuilder(
    column: $table.boundingBoxesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PagesTableTableFilterComposer get pageId {
    final $$PagesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableFilterComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotebooksTableTableFilterComposer get notebookId {
    final $$NotebooksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableFilterComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PageSearchIndexTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PageSearchIndexTableTable> {
  $$PageSearchIndexTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boundingBoxesJson => $composableBuilder(
    column: $table.boundingBoxesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PagesTableTableOrderingComposer get pageId {
    final $$PagesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableOrderingComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotebooksTableTableOrderingComposer get notebookId {
    final $$NotebooksTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableOrderingComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PageSearchIndexTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PageSearchIndexTableTable> {
  $$PageSearchIndexTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boundingBoxesJson => $composableBuilder(
    column: $table.boundingBoxesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PagesTableTableAnnotationComposer get pageId {
    final $$PagesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotebooksTableTableAnnotationComposer get notebookId {
    final $$NotebooksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PageSearchIndexTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PageSearchIndexTableTable,
          PageSearchIndexTableData,
          $$PageSearchIndexTableTableFilterComposer,
          $$PageSearchIndexTableTableOrderingComposer,
          $$PageSearchIndexTableTableAnnotationComposer,
          $$PageSearchIndexTableTableCreateCompanionBuilder,
          $$PageSearchIndexTableTableUpdateCompanionBuilder,
          (PageSearchIndexTableData, $$PageSearchIndexTableTableReferences),
          PageSearchIndexTableData,
          PrefetchHooks Function({bool pageId, bool notebookId})
        > {
  $$PageSearchIndexTableTableTableManager(
    _$AppDatabase db,
    $PageSearchIndexTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PageSearchIndexTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PageSearchIndexTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PageSearchIndexTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<String> notebookId = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> textContent = const Value.absent(),
                Value<String?> boundingBoxesJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PageSearchIndexTableCompanion(
                id: id,
                pageId: pageId,
                notebookId: notebookId,
                sourceType: sourceType,
                textContent: textContent,
                boundingBoxesJson: boundingBoxesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pageId,
                required String notebookId,
                required String sourceType,
                required String textContent,
                Value<String?> boundingBoxesJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PageSearchIndexTableCompanion.insert(
                id: id,
                pageId: pageId,
                notebookId: notebookId,
                sourceType: sourceType,
                textContent: textContent,
                boundingBoxesJson: boundingBoxesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PageSearchIndexTableTable,
                    PageSearchIndexTableData
                  >(table),
                  $$PageSearchIndexTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pageId = false, notebookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pageId,
                                referencedTable:
                                    $$PageSearchIndexTableTableReferences
                                        ._pageIdTable(db),
                                referencedColumn:
                                    $$PageSearchIndexTableTableReferences
                                        ._pageIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (notebookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.notebookId,
                                referencedTable:
                                    $$PageSearchIndexTableTableReferences
                                        ._notebookIdTable(db),
                                referencedColumn:
                                    $$PageSearchIndexTableTableReferences
                                        ._notebookIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PageSearchIndexTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PageSearchIndexTableTable,
      PageSearchIndexTableData,
      $$PageSearchIndexTableTableFilterComposer,
      $$PageSearchIndexTableTableOrderingComposer,
      $$PageSearchIndexTableTableAnnotationComposer,
      $$PageSearchIndexTableTableCreateCompanionBuilder,
      $$PageSearchIndexTableTableUpdateCompanionBuilder,
      (PageSearchIndexTableData, $$PageSearchIndexTableTableReferences),
      PageSearchIndexTableData,
      PrefetchHooks Function({bool pageId, bool notebookId})
    >;
typedef $$AudioRecordingsTableTableCreateCompanionBuilder =
    AudioRecordingsTableCompanion Function({
      required String id,
      required String notebookId,
      Value<String?> pageId,
      Value<String> title,
      required String filePath,
      Value<int> durationMs,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AudioRecordingsTableTableUpdateCompanionBuilder =
    AudioRecordingsTableCompanion Function({
      Value<String> id,
      Value<String> notebookId,
      Value<String?> pageId,
      Value<String> title,
      Value<String> filePath,
      Value<int> durationMs,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$AudioRecordingsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AudioRecordingsTableTable,
          AudioRecordingsTableData
        > {
  $$AudioRecordingsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $NotebooksTableTable _notebookIdTable(_$AppDatabase db) => db
      .notebooksTable
      .createAlias('audio_recordings_table__notebook_id__notebooks_table__id');

  $$NotebooksTableTableProcessedTableManager get notebookId {
    final $_column = $_itemColumn<String>('notebook_id')!;

    final manager = $$NotebooksTableTableTableManager(
      $_db,
      $_db.notebooksTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PagesTableTable _pageIdTable(_$AppDatabase db) => db.pagesTable
      .createAlias('audio_recordings_table__page_id__pages_table__id');

  $$PagesTableTableProcessedTableManager? get pageId {
    final $_column = $_itemColumn<String>('page_id');
    if ($_column == null) return null;
    final manager = $$PagesTableTableTableManager(
      $_db,
      $_db.pagesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $AudioBookmarksTableTable,
    List<AudioBookmarksTableData>
  >
  _audioBookmarksTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.audioBookmarksTable,
        aliasName:
            'audio_recordings_table__id__audio_bookmarks_table__recording_id',
      );

  $$AudioBookmarksTableTableProcessedTableManager get audioBookmarksTableRefs {
    final manager = $$AudioBookmarksTableTableTableManager(
      $_db,
      $_db.audioBookmarksTable,
    ).filter((f) => f.recordingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _audioBookmarksTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AudioRecordingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AudioRecordingsTableTable> {
  $$AudioRecordingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$NotebooksTableTableFilterComposer get notebookId {
    final $$NotebooksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableFilterComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PagesTableTableFilterComposer get pageId {
    final $$PagesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableFilterComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> audioBookmarksTableRefs(
    Expression<bool> Function($$AudioBookmarksTableTableFilterComposer f) f,
  ) {
    final $$AudioBookmarksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioBookmarksTable,
      getReferencedColumn: (t) => t.recordingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioBookmarksTableTableFilterComposer(
            $db: $db,
            $table: $db.audioBookmarksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AudioRecordingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AudioRecordingsTableTable> {
  $$AudioRecordingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotebooksTableTableOrderingComposer get notebookId {
    final $$NotebooksTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableOrderingComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PagesTableTableOrderingComposer get pageId {
    final $$PagesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableOrderingComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AudioRecordingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AudioRecordingsTableTable> {
  $$AudioRecordingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$NotebooksTableTableAnnotationComposer get notebookId {
    final $$NotebooksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PagesTableTableAnnotationComposer get pageId {
    final $$PagesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> audioBookmarksTableRefs<T extends Object>(
    Expression<T> Function($$AudioBookmarksTableTableAnnotationComposer a) f,
  ) {
    final $$AudioBookmarksTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.audioBookmarksTable,
          getReferencedColumn: (t) => t.recordingId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AudioBookmarksTableTableAnnotationComposer(
                $db: $db,
                $table: $db.audioBookmarksTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AudioRecordingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AudioRecordingsTableTable,
          AudioRecordingsTableData,
          $$AudioRecordingsTableTableFilterComposer,
          $$AudioRecordingsTableTableOrderingComposer,
          $$AudioRecordingsTableTableAnnotationComposer,
          $$AudioRecordingsTableTableCreateCompanionBuilder,
          $$AudioRecordingsTableTableUpdateCompanionBuilder,
          (AudioRecordingsTableData, $$AudioRecordingsTableTableReferences),
          AudioRecordingsTableData,
          PrefetchHooks Function({
            bool notebookId,
            bool pageId,
            bool audioBookmarksTableRefs,
          })
        > {
  $$AudioRecordingsTableTableTableManager(
    _$AppDatabase db,
    $AudioRecordingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioRecordingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioRecordingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AudioRecordingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> notebookId = const Value.absent(),
                Value<String?> pageId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AudioRecordingsTableCompanion(
                id: id,
                notebookId: notebookId,
                pageId: pageId,
                title: title,
                filePath: filePath,
                durationMs: durationMs,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String notebookId,
                Value<String?> pageId = const Value.absent(),
                Value<String> title = const Value.absent(),
                required String filePath,
                Value<int> durationMs = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AudioRecordingsTableCompanion.insert(
                id: id,
                notebookId: notebookId,
                pageId: pageId,
                title: title,
                filePath: filePath,
                durationMs: durationMs,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AudioRecordingsTableTable,
                    AudioRecordingsTableData
                  >(table),
                  $$AudioRecordingsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                notebookId = false,
                pageId = false,
                audioBookmarksTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (audioBookmarksTableRefs) db.audioBookmarksTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (notebookId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.notebookId,
                                    referencedTable:
                                        $$AudioRecordingsTableTableReferences
                                            ._notebookIdTable(db),
                                    referencedColumn:
                                        $$AudioRecordingsTableTableReferences
                                            ._notebookIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (pageId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.pageId,
                                    referencedTable:
                                        $$AudioRecordingsTableTableReferences
                                            ._pageIdTable(db),
                                    referencedColumn:
                                        $$AudioRecordingsTableTableReferences
                                            ._pageIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (audioBookmarksTableRefs)
                        await $_getPrefetchedDataByColumns<
                          AudioRecordingsTableData,
                          $AudioRecordingsTableTable,
                          AudioBookmarksTableData,
                          $AudioBookmarksTableTable
                        >(
                          currentTable: table,
                          referencedTable: $$AudioRecordingsTableTableReferences
                              ._audioBookmarksTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AudioRecordingsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).audioBookmarksTableRefs,
                          currentColumn: 'id',
                          referencedColumn: 'recording_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AudioRecordingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AudioRecordingsTableTable,
      AudioRecordingsTableData,
      $$AudioRecordingsTableTableFilterComposer,
      $$AudioRecordingsTableTableOrderingComposer,
      $$AudioRecordingsTableTableAnnotationComposer,
      $$AudioRecordingsTableTableCreateCompanionBuilder,
      $$AudioRecordingsTableTableUpdateCompanionBuilder,
      (AudioRecordingsTableData, $$AudioRecordingsTableTableReferences),
      AudioRecordingsTableData,
      PrefetchHooks Function({
        bool notebookId,
        bool pageId,
        bool audioBookmarksTableRefs,
      })
    >;
typedef $$AudioBookmarksTableTableCreateCompanionBuilder =
    AudioBookmarksTableCompanion Function({
      required String id,
      required String recordingId,
      Value<String?> pageId,
      Value<String?> strokeId,
      required int timestampMs,
      required String label,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AudioBookmarksTableTableUpdateCompanionBuilder =
    AudioBookmarksTableCompanion Function({
      Value<String> id,
      Value<String> recordingId,
      Value<String?> pageId,
      Value<String?> strokeId,
      Value<int> timestampMs,
      Value<String> label,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AudioBookmarksTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AudioBookmarksTableTable,
          AudioBookmarksTableData
        > {
  $$AudioBookmarksTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AudioRecordingsTableTable _recordingIdTable(_$AppDatabase db) =>
      db.audioRecordingsTable.createAlias(
        'audio_bookmarks_table__recording_id__audio_recordings_table__id',
      );

  $$AudioRecordingsTableTableProcessedTableManager get recordingId {
    final $_column = $_itemColumn<String>('recording_id')!;

    final manager = $$AudioRecordingsTableTableTableManager(
      $_db,
      $_db.audioRecordingsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AudioBookmarksTableTableFilterComposer
    extends Composer<_$AppDatabase, $AudioBookmarksTableTable> {
  $$AudioBookmarksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strokeId => $composableBuilder(
    column: $table.strokeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AudioRecordingsTableTableFilterComposer get recordingId {
    final $$AudioRecordingsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.audioRecordingsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioRecordingsTableTableFilterComposer(
            $db: $db,
            $table: $db.audioRecordingsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AudioBookmarksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AudioBookmarksTableTable> {
  $$AudioBookmarksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strokeId => $composableBuilder(
    column: $table.strokeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AudioRecordingsTableTableOrderingComposer get recordingId {
    final $$AudioRecordingsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.recordingId,
          referencedTable: $db.audioRecordingsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AudioRecordingsTableTableOrderingComposer(
                $db: $db,
                $table: $db.audioRecordingsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AudioBookmarksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AudioBookmarksTableTable> {
  $$AudioBookmarksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get strokeId =>
      $composableBuilder(column: $table.strokeId, builder: (column) => column);

  GeneratedColumn<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AudioRecordingsTableTableAnnotationComposer get recordingId {
    final $$AudioRecordingsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.recordingId,
          referencedTable: $db.audioRecordingsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AudioRecordingsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.audioRecordingsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AudioBookmarksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AudioBookmarksTableTable,
          AudioBookmarksTableData,
          $$AudioBookmarksTableTableFilterComposer,
          $$AudioBookmarksTableTableOrderingComposer,
          $$AudioBookmarksTableTableAnnotationComposer,
          $$AudioBookmarksTableTableCreateCompanionBuilder,
          $$AudioBookmarksTableTableUpdateCompanionBuilder,
          (AudioBookmarksTableData, $$AudioBookmarksTableTableReferences),
          AudioBookmarksTableData,
          PrefetchHooks Function({bool recordingId})
        > {
  $$AudioBookmarksTableTableTableManager(
    _$AppDatabase db,
    $AudioBookmarksTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioBookmarksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioBookmarksTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AudioBookmarksTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recordingId = const Value.absent(),
                Value<String?> pageId = const Value.absent(),
                Value<String?> strokeId = const Value.absent(),
                Value<int> timestampMs = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AudioBookmarksTableCompanion(
                id: id,
                recordingId: recordingId,
                pageId: pageId,
                strokeId: strokeId,
                timestampMs: timestampMs,
                label: label,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recordingId,
                Value<String?> pageId = const Value.absent(),
                Value<String?> strokeId = const Value.absent(),
                required int timestampMs,
                required String label,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AudioBookmarksTableCompanion.insert(
                id: id,
                recordingId: recordingId,
                pageId: pageId,
                strokeId: strokeId,
                timestampMs: timestampMs,
                label: label,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AudioBookmarksTableTable,
                    AudioBookmarksTableData
                  >(table),
                  $$AudioBookmarksTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recordingId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recordingId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordingId,
                                referencedTable:
                                    $$AudioBookmarksTableTableReferences
                                        ._recordingIdTable(db),
                                referencedColumn:
                                    $$AudioBookmarksTableTableReferences
                                        ._recordingIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AudioBookmarksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AudioBookmarksTableTable,
      AudioBookmarksTableData,
      $$AudioBookmarksTableTableFilterComposer,
      $$AudioBookmarksTableTableOrderingComposer,
      $$AudioBookmarksTableTableAnnotationComposer,
      $$AudioBookmarksTableTableCreateCompanionBuilder,
      $$AudioBookmarksTableTableUpdateCompanionBuilder,
      (AudioBookmarksTableData, $$AudioBookmarksTableTableReferences),
      AudioBookmarksTableData,
      PrefetchHooks Function({bool recordingId})
    >;
typedef $$PageSnapshotsTableTableCreateCompanionBuilder =
    PageSnapshotsTableCompanion Function({
      required String id,
      required String pageId,
      required String notebookId,
      Value<int> versionNumber,
      Value<String> label,
      required String strokesJson,
      Value<String> stickyNotesJson,
      Value<String> templateId,
      Value<String?> templatePropertiesJson,
      Value<String> deviceInfo,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PageSnapshotsTableTableUpdateCompanionBuilder =
    PageSnapshotsTableCompanion Function({
      Value<String> id,
      Value<String> pageId,
      Value<String> notebookId,
      Value<int> versionNumber,
      Value<String> label,
      Value<String> strokesJson,
      Value<String> stickyNotesJson,
      Value<String> templateId,
      Value<String?> templatePropertiesJson,
      Value<String> deviceInfo,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PageSnapshotsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PageSnapshotsTableTable,
          PageSnapshotsTableData
        > {
  $$PageSnapshotsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PagesTableTable _pageIdTable(_$AppDatabase db) => db.pagesTable
      .createAlias('page_snapshots_table__page_id__pages_table__id');

  $$PagesTableTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<String>('page_id')!;

    final manager = $$PagesTableTableTableManager(
      $_db,
      $_db.pagesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NotebooksTableTable _notebookIdTable(_$AppDatabase db) => db
      .notebooksTable
      .createAlias('page_snapshots_table__notebook_id__notebooks_table__id');

  $$NotebooksTableTableProcessedTableManager get notebookId {
    final $_column = $_itemColumn<String>('notebook_id')!;

    final manager = $$NotebooksTableTableTableManager(
      $_db,
      $_db.notebooksTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PageSnapshotsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PageSnapshotsTableTable> {
  $$PageSnapshotsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stickyNotesJson => $composableBuilder(
    column: $table.stickyNotesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templatePropertiesJson => $composableBuilder(
    column: $table.templatePropertiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceInfo => $composableBuilder(
    column: $table.deviceInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PagesTableTableFilterComposer get pageId {
    final $$PagesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableFilterComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotebooksTableTableFilterComposer get notebookId {
    final $$NotebooksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableFilterComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PageSnapshotsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PageSnapshotsTableTable> {
  $$PageSnapshotsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stickyNotesJson => $composableBuilder(
    column: $table.stickyNotesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templatePropertiesJson => $composableBuilder(
    column: $table.templatePropertiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceInfo => $composableBuilder(
    column: $table.deviceInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PagesTableTableOrderingComposer get pageId {
    final $$PagesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableOrderingComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotebooksTableTableOrderingComposer get notebookId {
    final $$NotebooksTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableOrderingComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PageSnapshotsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PageSnapshotsTableTable> {
  $$PageSnapshotsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stickyNotesJson => $composableBuilder(
    column: $table.stickyNotesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templatePropertiesJson => $composableBuilder(
    column: $table.templatePropertiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceInfo => $composableBuilder(
    column: $table.deviceInfo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PagesTableTableAnnotationComposer get pageId {
    final $$PagesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pagesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.pagesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotebooksTableTableAnnotationComposer get notebookId {
    final $$NotebooksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.notebooksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PageSnapshotsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PageSnapshotsTableTable,
          PageSnapshotsTableData,
          $$PageSnapshotsTableTableFilterComposer,
          $$PageSnapshotsTableTableOrderingComposer,
          $$PageSnapshotsTableTableAnnotationComposer,
          $$PageSnapshotsTableTableCreateCompanionBuilder,
          $$PageSnapshotsTableTableUpdateCompanionBuilder,
          (PageSnapshotsTableData, $$PageSnapshotsTableTableReferences),
          PageSnapshotsTableData,
          PrefetchHooks Function({bool pageId, bool notebookId})
        > {
  $$PageSnapshotsTableTableTableManager(
    _$AppDatabase db,
    $PageSnapshotsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PageSnapshotsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PageSnapshotsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PageSnapshotsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<String> notebookId = const Value.absent(),
                Value<int> versionNumber = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> strokesJson = const Value.absent(),
                Value<String> stickyNotesJson = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String?> templatePropertiesJson = const Value.absent(),
                Value<String> deviceInfo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PageSnapshotsTableCompanion(
                id: id,
                pageId: pageId,
                notebookId: notebookId,
                versionNumber: versionNumber,
                label: label,
                strokesJson: strokesJson,
                stickyNotesJson: stickyNotesJson,
                templateId: templateId,
                templatePropertiesJson: templatePropertiesJson,
                deviceInfo: deviceInfo,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pageId,
                required String notebookId,
                Value<int> versionNumber = const Value.absent(),
                Value<String> label = const Value.absent(),
                required String strokesJson,
                Value<String> stickyNotesJson = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String?> templatePropertiesJson = const Value.absent(),
                Value<String> deviceInfo = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PageSnapshotsTableCompanion.insert(
                id: id,
                pageId: pageId,
                notebookId: notebookId,
                versionNumber: versionNumber,
                label: label,
                strokesJson: strokesJson,
                stickyNotesJson: stickyNotesJson,
                templateId: templateId,
                templatePropertiesJson: templatePropertiesJson,
                deviceInfo: deviceInfo,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PageSnapshotsTableTable, PageSnapshotsTableData>(
                    table,
                  ),
                  $$PageSnapshotsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pageId = false, notebookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pageId,
                                referencedTable:
                                    $$PageSnapshotsTableTableReferences
                                        ._pageIdTable(db),
                                referencedColumn:
                                    $$PageSnapshotsTableTableReferences
                                        ._pageIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (notebookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.notebookId,
                                referencedTable:
                                    $$PageSnapshotsTableTableReferences
                                        ._notebookIdTable(db),
                                referencedColumn:
                                    $$PageSnapshotsTableTableReferences
                                        ._notebookIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PageSnapshotsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PageSnapshotsTableTable,
      PageSnapshotsTableData,
      $$PageSnapshotsTableTableFilterComposer,
      $$PageSnapshotsTableTableOrderingComposer,
      $$PageSnapshotsTableTableAnnotationComposer,
      $$PageSnapshotsTableTableCreateCompanionBuilder,
      $$PageSnapshotsTableTableUpdateCompanionBuilder,
      (PageSnapshotsTableData, $$PageSnapshotsTableTableReferences),
      PageSnapshotsTableData,
      PrefetchHooks Function({bool pageId, bool notebookId})
    >;
typedef $$CustomTemplatesTableTableCreateCompanionBuilder =
    CustomTemplatesTableCompanion Function({
      required String id,
      required String title,
      Value<String> description,
      Value<String> category,
      Value<String> author,
      required String paperPropertiesJson,
      Value<String?> thumbnailBase64,
      Value<bool> isInstalled,
      Value<bool> isBuiltIn,
      Value<int> downloadCount,
      Value<double> rating,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CustomTemplatesTableTableUpdateCompanionBuilder =
    CustomTemplatesTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> description,
      Value<String> category,
      Value<String> author,
      Value<String> paperPropertiesJson,
      Value<String?> thumbnailBase64,
      Value<bool> isInstalled,
      Value<bool> isBuiltIn,
      Value<int> downloadCount,
      Value<double> rating,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CustomTemplatesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomTemplatesTableTable> {
  $$CustomTemplatesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paperPropertiesJson => $composableBuilder(
    column: $table.paperPropertiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailBase64 => $composableBuilder(
    column: $table.thumbnailBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInstalled => $composableBuilder(
    column: $table.isInstalled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadCount => $composableBuilder(
    column: $table.downloadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomTemplatesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomTemplatesTableTable> {
  $$CustomTemplatesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paperPropertiesJson => $composableBuilder(
    column: $table.paperPropertiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailBase64 => $composableBuilder(
    column: $table.thumbnailBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInstalled => $composableBuilder(
    column: $table.isInstalled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadCount => $composableBuilder(
    column: $table.downloadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomTemplatesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomTemplatesTableTable> {
  $$CustomTemplatesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get paperPropertiesJson => $composableBuilder(
    column: $table.paperPropertiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailBase64 => $composableBuilder(
    column: $table.thumbnailBase64,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isInstalled => $composableBuilder(
    column: $table.isInstalled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);

  GeneratedColumn<int> get downloadCount => $composableBuilder(
    column: $table.downloadCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomTemplatesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomTemplatesTableTable,
          CustomTemplatesTableData,
          $$CustomTemplatesTableTableFilterComposer,
          $$CustomTemplatesTableTableOrderingComposer,
          $$CustomTemplatesTableTableAnnotationComposer,
          $$CustomTemplatesTableTableCreateCompanionBuilder,
          $$CustomTemplatesTableTableUpdateCompanionBuilder,
          (
            CustomTemplatesTableData,
            BaseReferences<
              _$AppDatabase,
              $CustomTemplatesTableTable,
              CustomTemplatesTableData
            >,
          ),
          CustomTemplatesTableData,
          PrefetchHooks Function()
        > {
  $$CustomTemplatesTableTableTableManager(
    _$AppDatabase db,
    $CustomTemplatesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomTemplatesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomTemplatesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomTemplatesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> paperPropertiesJson = const Value.absent(),
                Value<String?> thumbnailBase64 = const Value.absent(),
                Value<bool> isInstalled = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<int> downloadCount = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomTemplatesTableCompanion(
                id: id,
                title: title,
                description: description,
                category: category,
                author: author,
                paperPropertiesJson: paperPropertiesJson,
                thumbnailBase64: thumbnailBase64,
                isInstalled: isInstalled,
                isBuiltIn: isBuiltIn,
                downloadCount: downloadCount,
                rating: rating,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> author = const Value.absent(),
                required String paperPropertiesJson,
                Value<String?> thumbnailBase64 = const Value.absent(),
                Value<bool> isInstalled = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<int> downloadCount = const Value.absent(),
                Value<double> rating = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomTemplatesTableCompanion.insert(
                id: id,
                title: title,
                description: description,
                category: category,
                author: author,
                paperPropertiesJson: paperPropertiesJson,
                thumbnailBase64: thumbnailBase64,
                isInstalled: isInstalled,
                isBuiltIn: isBuiltIn,
                downloadCount: downloadCount,
                rating: rating,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CustomTemplatesTableTable,
                    CustomTemplatesTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CustomTemplatesTableTable,
                    CustomTemplatesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomTemplatesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomTemplatesTableTable,
      CustomTemplatesTableData,
      $$CustomTemplatesTableTableFilterComposer,
      $$CustomTemplatesTableTableOrderingComposer,
      $$CustomTemplatesTableTableAnnotationComposer,
      $$CustomTemplatesTableTableCreateCompanionBuilder,
      $$CustomTemplatesTableTableUpdateCompanionBuilder,
      (
        CustomTemplatesTableData,
        BaseReferences<
          _$AppDatabase,
          $CustomTemplatesTableTable,
          CustomTemplatesTableData
        >,
      ),
      CustomTemplatesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoldersTableTableTableManager get foldersTable =>
      $$FoldersTableTableTableManager(_db, _db.foldersTable);
  $$NotebooksTableTableTableManager get notebooksTable =>
      $$NotebooksTableTableTableManager(_db, _db.notebooksTable);
  $$SectionsTableTableTableManager get sectionsTable =>
      $$SectionsTableTableTableManager(_db, _db.sectionsTable);
  $$PagesTableTableTableManager get pagesTable =>
      $$PagesTableTableTableManager(_db, _db.pagesTable);
  $$StrokesTableTableTableManager get strokesTable =>
      $$StrokesTableTableTableManager(_db, _db.strokesTable);
  $$StickyNotesTableTableTableManager get stickyNotesTable =>
      $$StickyNotesTableTableTableManager(_db, _db.stickyNotesTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
  $$PageSearchIndexTableTableTableManager get pageSearchIndexTable =>
      $$PageSearchIndexTableTableTableManager(_db, _db.pageSearchIndexTable);
  $$AudioRecordingsTableTableTableManager get audioRecordingsTable =>
      $$AudioRecordingsTableTableTableManager(_db, _db.audioRecordingsTable);
  $$AudioBookmarksTableTableTableManager get audioBookmarksTable =>
      $$AudioBookmarksTableTableTableManager(_db, _db.audioBookmarksTable);
  $$PageSnapshotsTableTableTableManager get pageSnapshotsTable =>
      $$PageSnapshotsTableTableTableManager(_db, _db.pageSnapshotsTable);
  $$CustomTemplatesTableTableTableManager get customTemplatesTable =>
      $$CustomTemplatesTableTableTableManager(_db, _db.customTemplatesTable);
}

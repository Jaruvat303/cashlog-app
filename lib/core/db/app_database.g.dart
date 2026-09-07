// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ScannedSlipsTable extends ScannedSlips
    with TableInfo<$ScannedSlipsTable, ScannedSlip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScannedSlipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localImageNameMeta = const VerificationMeta(
    'localImageName',
  );
  @override
  late final GeneratedColumn<String> localImageName = GeneratedColumn<String>(
    'local_image_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceFolderMeta = const VerificationMeta(
    'sourceFolder',
  );
  @override
  late final GeneratedColumn<String> sourceFolder = GeneratedColumn<String>(
    'source_folder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SlipStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SlipStatus>($ScannedSlipsTable.$converterstatus);
  static const VerificationMeta _serverTransactionIdMeta =
      const VerificationMeta('serverTransactionId');
  @override
  late final GeneratedColumn<int> serverTransactionId = GeneratedColumn<int>(
    'server_transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scannedAtMeta = const VerificationMeta(
    'scannedAt',
  );
  @override
  late final GeneratedColumn<DateTime> scannedAt = GeneratedColumn<DateTime>(
    'scanned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localImageName,
    sourceFolder,
    status,
    serverTransactionId,
    retryCount,
    lastErrorCode,
    scannedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scanned_slips';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScannedSlip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_image_name')) {
      context.handle(
        _localImageNameMeta,
        localImageName.isAcceptableOrUnknown(
          data['local_image_name']!,
          _localImageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localImageNameMeta);
    }
    if (data.containsKey('source_folder')) {
      context.handle(
        _sourceFolderMeta,
        sourceFolder.isAcceptableOrUnknown(
          data['source_folder']!,
          _sourceFolderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceFolderMeta);
    }
    if (data.containsKey('server_transaction_id')) {
      context.handle(
        _serverTransactionIdMeta,
        serverTransactionId.isAcceptableOrUnknown(
          data['server_transaction_id']!,
          _serverTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('scanned_at')) {
      context.handle(
        _scannedAtMeta,
        scannedAt.isAcceptableOrUnknown(data['scanned_at']!, _scannedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_scannedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localImageName};
  @override
  ScannedSlip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScannedSlip(
      localImageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_image_name'],
      )!,
      sourceFolder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_folder'],
      )!,
      status: $ScannedSlipsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      serverTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_transaction_id'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      scannedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scanned_at'],
      )!,
    );
  }

  @override
  $ScannedSlipsTable createAlias(String alias) {
    return $ScannedSlipsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SlipStatus, String, String> $converterstatus =
      const EnumNameConverter<SlipStatus>(SlipStatus.values);
}

class ScannedSlip extends DataClass implements Insertable<ScannedSlip> {
  final String localImageName;
  final String sourceFolder;
  final SlipStatus status;
  final int? serverTransactionId;
  final int retryCount;
  final String? lastErrorCode;
  final DateTime scannedAt;
  const ScannedSlip({
    required this.localImageName,
    required this.sourceFolder,
    required this.status,
    this.serverTransactionId,
    required this.retryCount,
    this.lastErrorCode,
    required this.scannedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_image_name'] = Variable<String>(localImageName);
    map['source_folder'] = Variable<String>(sourceFolder);
    {
      map['status'] = Variable<String>(
        $ScannedSlipsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || serverTransactionId != null) {
      map['server_transaction_id'] = Variable<int>(serverTransactionId);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    map['scanned_at'] = Variable<DateTime>(scannedAt);
    return map;
  }

  ScannedSlipsCompanion toCompanion(bool nullToAbsent) {
    return ScannedSlipsCompanion(
      localImageName: Value(localImageName),
      sourceFolder: Value(sourceFolder),
      status: Value(status),
      serverTransactionId: serverTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverTransactionId),
      retryCount: Value(retryCount),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      scannedAt: Value(scannedAt),
    );
  }

  factory ScannedSlip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScannedSlip(
      localImageName: serializer.fromJson<String>(json['localImageName']),
      sourceFolder: serializer.fromJson<String>(json['sourceFolder']),
      status: $ScannedSlipsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      serverTransactionId: serializer.fromJson<int?>(
        json['serverTransactionId'],
      ),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      scannedAt: serializer.fromJson<DateTime>(json['scannedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localImageName': serializer.toJson<String>(localImageName),
      'sourceFolder': serializer.toJson<String>(sourceFolder),
      'status': serializer.toJson<String>(
        $ScannedSlipsTable.$converterstatus.toJson(status),
      ),
      'serverTransactionId': serializer.toJson<int?>(serverTransactionId),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'scannedAt': serializer.toJson<DateTime>(scannedAt),
    };
  }

  ScannedSlip copyWith({
    String? localImageName,
    String? sourceFolder,
    SlipStatus? status,
    Value<int?> serverTransactionId = const Value.absent(),
    int? retryCount,
    Value<String?> lastErrorCode = const Value.absent(),
    DateTime? scannedAt,
  }) => ScannedSlip(
    localImageName: localImageName ?? this.localImageName,
    sourceFolder: sourceFolder ?? this.sourceFolder,
    status: status ?? this.status,
    serverTransactionId: serverTransactionId.present
        ? serverTransactionId.value
        : this.serverTransactionId,
    retryCount: retryCount ?? this.retryCount,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    scannedAt: scannedAt ?? this.scannedAt,
  );
  ScannedSlip copyWithCompanion(ScannedSlipsCompanion data) {
    return ScannedSlip(
      localImageName: data.localImageName.present
          ? data.localImageName.value
          : this.localImageName,
      sourceFolder: data.sourceFolder.present
          ? data.sourceFolder.value
          : this.sourceFolder,
      status: data.status.present ? data.status.value : this.status,
      serverTransactionId: data.serverTransactionId.present
          ? data.serverTransactionId.value
          : this.serverTransactionId,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      scannedAt: data.scannedAt.present ? data.scannedAt.value : this.scannedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScannedSlip(')
          ..write('localImageName: $localImageName, ')
          ..write('sourceFolder: $sourceFolder, ')
          ..write('status: $status, ')
          ..write('serverTransactionId: $serverTransactionId, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('scannedAt: $scannedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localImageName,
    sourceFolder,
    status,
    serverTransactionId,
    retryCount,
    lastErrorCode,
    scannedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScannedSlip &&
          other.localImageName == this.localImageName &&
          other.sourceFolder == this.sourceFolder &&
          other.status == this.status &&
          other.serverTransactionId == this.serverTransactionId &&
          other.retryCount == this.retryCount &&
          other.lastErrorCode == this.lastErrorCode &&
          other.scannedAt == this.scannedAt);
}

class ScannedSlipsCompanion extends UpdateCompanion<ScannedSlip> {
  final Value<String> localImageName;
  final Value<String> sourceFolder;
  final Value<SlipStatus> status;
  final Value<int?> serverTransactionId;
  final Value<int> retryCount;
  final Value<String?> lastErrorCode;
  final Value<DateTime> scannedAt;
  final Value<int> rowid;
  const ScannedSlipsCompanion({
    this.localImageName = const Value.absent(),
    this.sourceFolder = const Value.absent(),
    this.status = const Value.absent(),
    this.serverTransactionId = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.scannedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScannedSlipsCompanion.insert({
    required String localImageName,
    required String sourceFolder,
    required SlipStatus status,
    this.serverTransactionId = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    required DateTime scannedAt,
    this.rowid = const Value.absent(),
  }) : localImageName = Value(localImageName),
       sourceFolder = Value(sourceFolder),
       status = Value(status),
       scannedAt = Value(scannedAt);
  static Insertable<ScannedSlip> custom({
    Expression<String>? localImageName,
    Expression<String>? sourceFolder,
    Expression<String>? status,
    Expression<int>? serverTransactionId,
    Expression<int>? retryCount,
    Expression<String>? lastErrorCode,
    Expression<DateTime>? scannedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localImageName != null) 'local_image_name': localImageName,
      if (sourceFolder != null) 'source_folder': sourceFolder,
      if (status != null) 'status': status,
      if (serverTransactionId != null)
        'server_transaction_id': serverTransactionId,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (scannedAt != null) 'scanned_at': scannedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScannedSlipsCompanion copyWith({
    Value<String>? localImageName,
    Value<String>? sourceFolder,
    Value<SlipStatus>? status,
    Value<int?>? serverTransactionId,
    Value<int>? retryCount,
    Value<String?>? lastErrorCode,
    Value<DateTime>? scannedAt,
    Value<int>? rowid,
  }) {
    return ScannedSlipsCompanion(
      localImageName: localImageName ?? this.localImageName,
      sourceFolder: sourceFolder ?? this.sourceFolder,
      status: status ?? this.status,
      serverTransactionId: serverTransactionId ?? this.serverTransactionId,
      retryCount: retryCount ?? this.retryCount,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      scannedAt: scannedAt ?? this.scannedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localImageName.present) {
      map['local_image_name'] = Variable<String>(localImageName.value);
    }
    if (sourceFolder.present) {
      map['source_folder'] = Variable<String>(sourceFolder.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ScannedSlipsTable.$converterstatus.toSql(status.value),
      );
    }
    if (serverTransactionId.present) {
      map['server_transaction_id'] = Variable<int>(serverTransactionId.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (scannedAt.present) {
      map['scanned_at'] = Variable<DateTime>(scannedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScannedSlipsCompanion(')
          ..write('localImageName: $localImageName, ')
          ..write('sourceFolder: $sourceFolder, ')
          ..write('status: $status, ')
          ..write('serverTransactionId: $serverTransactionId, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('scannedAt: $scannedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedTransactionsTable extends CachedTransactions
    with TableInfo<$CachedTransactionsTable, CachedTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderNameMeta = const VerificationMeta(
    'senderName',
  );
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
    'sender_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiverNameMeta = const VerificationMeta(
    'receiverName',
  );
  @override
  late final GeneratedColumn<String> receiverName = GeneratedColumn<String>(
    'receiver_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromAccountIdMeta = const VerificationMeta(
    'fromAccountId',
  );
  @override
  late final GeneratedColumn<int> fromAccountId = GeneratedColumn<int>(
    'from_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<int> toAccountId = GeneratedColumn<int>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localImageNameMeta = const VerificationMeta(
    'localImageName',
  );
  @override
  late final GeneratedColumn<String> localImageName = GeneratedColumn<String>(
    'local_image_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isJunkMeta = const VerificationMeta('isJunk');
  @override
  late final GeneratedColumn<bool> isJunk = GeneratedColumn<bool>(
    'is_junk',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_junk" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amount,
    transactionType,
    senderName,
    receiverName,
    note,
    accountId,
    fromAccountId,
    toAccountId,
    source,
    localImageName,
    transactionDate,
    categoryId,
    isJunk,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('sender_name')) {
      context.handle(
        _senderNameMeta,
        senderName.isAcceptableOrUnknown(data['sender_name']!, _senderNameMeta),
      );
    }
    if (data.containsKey('receiver_name')) {
      context.handle(
        _receiverNameMeta,
        receiverName.isAcceptableOrUnknown(
          data['receiver_name']!,
          _receiverNameMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('from_account_id')) {
      context.handle(
        _fromAccountIdMeta,
        fromAccountId.isAcceptableOrUnknown(
          data['from_account_id']!,
          _fromAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('local_image_name')) {
      context.handle(
        _localImageNameMeta,
        localImageName.isAcceptableOrUnknown(
          data['local_image_name']!,
          _localImageNameMeta,
        ),
      );
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('is_junk')) {
      context.handle(
        _isJunkMeta,
        isJunk.isAcceptableOrUnknown(data['is_junk']!, _isJunkMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      senderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_name'],
      )!,
      receiverName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receiver_name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      ),
      fromAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_account_id'],
      ),
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_account_id'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      localImageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_image_name'],
      ),
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      isJunk: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_junk'],
      )!,
    );
  }

  @override
  $CachedTransactionsTable createAlias(String alias) {
    return $CachedTransactionsTable(attachedDatabase, alias);
  }
}

class CachedTransaction extends DataClass
    implements Insertable<CachedTransaction> {
  final int id;
  final double amount;
  final String transactionType;
  final String senderName;
  final String receiverName;
  final String note;
  final int? accountId;
  final int? fromAccountId;
  final int? toAccountId;
  final String source;
  final String? localImageName;
  final DateTime transactionDate;
  final int? categoryId;
  final bool isJunk;
  const CachedTransaction({
    required this.id,
    required this.amount,
    required this.transactionType,
    required this.senderName,
    required this.receiverName,
    required this.note,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    required this.source,
    this.localImageName,
    required this.transactionDate,
    this.categoryId,
    required this.isJunk,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount'] = Variable<double>(amount);
    map['transaction_type'] = Variable<String>(transactionType);
    map['sender_name'] = Variable<String>(senderName);
    map['receiver_name'] = Variable<String>(receiverName);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    if (!nullToAbsent || fromAccountId != null) {
      map['from_account_id'] = Variable<int>(fromAccountId);
    }
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<int>(toAccountId);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || localImageName != null) {
      map['local_image_name'] = Variable<String>(localImageName);
    }
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['is_junk'] = Variable<bool>(isJunk);
    return map;
  }

  CachedTransactionsCompanion toCompanion(bool nullToAbsent) {
    return CachedTransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      transactionType: Value(transactionType),
      senderName: Value(senderName),
      receiverName: Value(receiverName),
      note: Value(note),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      fromAccountId: fromAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromAccountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      source: Value(source),
      localImageName: localImageName == null && nullToAbsent
          ? const Value.absent()
          : Value(localImageName),
      transactionDate: Value(transactionDate),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      isJunk: Value(isJunk),
    );
  }

  factory CachedTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTransaction(
      id: serializer.fromJson<int>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      senderName: serializer.fromJson<String>(json['senderName']),
      receiverName: serializer.fromJson<String>(json['receiverName']),
      note: serializer.fromJson<String>(json['note']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      fromAccountId: serializer.fromJson<int?>(json['fromAccountId']),
      toAccountId: serializer.fromJson<int?>(json['toAccountId']),
      source: serializer.fromJson<String>(json['source']),
      localImageName: serializer.fromJson<String?>(json['localImageName']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      isJunk: serializer.fromJson<bool>(json['isJunk']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amount': serializer.toJson<double>(amount),
      'transactionType': serializer.toJson<String>(transactionType),
      'senderName': serializer.toJson<String>(senderName),
      'receiverName': serializer.toJson<String>(receiverName),
      'note': serializer.toJson<String>(note),
      'accountId': serializer.toJson<int?>(accountId),
      'fromAccountId': serializer.toJson<int?>(fromAccountId),
      'toAccountId': serializer.toJson<int?>(toAccountId),
      'source': serializer.toJson<String>(source),
      'localImageName': serializer.toJson<String?>(localImageName),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'categoryId': serializer.toJson<int?>(categoryId),
      'isJunk': serializer.toJson<bool>(isJunk),
    };
  }

  CachedTransaction copyWith({
    int? id,
    double? amount,
    String? transactionType,
    String? senderName,
    String? receiverName,
    String? note,
    Value<int?> accountId = const Value.absent(),
    Value<int?> fromAccountId = const Value.absent(),
    Value<int?> toAccountId = const Value.absent(),
    String? source,
    Value<String?> localImageName = const Value.absent(),
    DateTime? transactionDate,
    Value<int?> categoryId = const Value.absent(),
    bool? isJunk,
  }) => CachedTransaction(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    transactionType: transactionType ?? this.transactionType,
    senderName: senderName ?? this.senderName,
    receiverName: receiverName ?? this.receiverName,
    note: note ?? this.note,
    accountId: accountId.present ? accountId.value : this.accountId,
    fromAccountId: fromAccountId.present
        ? fromAccountId.value
        : this.fromAccountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    source: source ?? this.source,
    localImageName: localImageName.present
        ? localImageName.value
        : this.localImageName,
    transactionDate: transactionDate ?? this.transactionDate,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    isJunk: isJunk ?? this.isJunk,
  );
  CachedTransaction copyWithCompanion(CachedTransactionsCompanion data) {
    return CachedTransaction(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      senderName: data.senderName.present
          ? data.senderName.value
          : this.senderName,
      receiverName: data.receiverName.present
          ? data.receiverName.value
          : this.receiverName,
      note: data.note.present ? data.note.value : this.note,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      fromAccountId: data.fromAccountId.present
          ? data.fromAccountId.value
          : this.fromAccountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      source: data.source.present ? data.source.value : this.source,
      localImageName: data.localImageName.present
          ? data.localImageName.value
          : this.localImageName,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      isJunk: data.isJunk.present ? data.isJunk.value : this.isJunk,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTransaction(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('transactionType: $transactionType, ')
          ..write('senderName: $senderName, ')
          ..write('receiverName: $receiverName, ')
          ..write('note: $note, ')
          ..write('accountId: $accountId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('source: $source, ')
          ..write('localImageName: $localImageName, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('categoryId: $categoryId, ')
          ..write('isJunk: $isJunk')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    transactionType,
    senderName,
    receiverName,
    note,
    accountId,
    fromAccountId,
    toAccountId,
    source,
    localImageName,
    transactionDate,
    categoryId,
    isJunk,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTransaction &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.transactionType == this.transactionType &&
          other.senderName == this.senderName &&
          other.receiverName == this.receiverName &&
          other.note == this.note &&
          other.accountId == this.accountId &&
          other.fromAccountId == this.fromAccountId &&
          other.toAccountId == this.toAccountId &&
          other.source == this.source &&
          other.localImageName == this.localImageName &&
          other.transactionDate == this.transactionDate &&
          other.categoryId == this.categoryId &&
          other.isJunk == this.isJunk);
}

class CachedTransactionsCompanion extends UpdateCompanion<CachedTransaction> {
  final Value<int> id;
  final Value<double> amount;
  final Value<String> transactionType;
  final Value<String> senderName;
  final Value<String> receiverName;
  final Value<String> note;
  final Value<int?> accountId;
  final Value<int?> fromAccountId;
  final Value<int?> toAccountId;
  final Value<String> source;
  final Value<String?> localImageName;
  final Value<DateTime> transactionDate;
  final Value<int?> categoryId;
  final Value<bool> isJunk;
  const CachedTransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.senderName = const Value.absent(),
    this.receiverName = const Value.absent(),
    this.note = const Value.absent(),
    this.accountId = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.source = const Value.absent(),
    this.localImageName = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.isJunk = const Value.absent(),
  });
  CachedTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required double amount,
    required String transactionType,
    this.senderName = const Value.absent(),
    this.receiverName = const Value.absent(),
    this.note = const Value.absent(),
    this.accountId = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    required String source,
    this.localImageName = const Value.absent(),
    required DateTime transactionDate,
    this.categoryId = const Value.absent(),
    this.isJunk = const Value.absent(),
  }) : amount = Value(amount),
       transactionType = Value(transactionType),
       source = Value(source),
       transactionDate = Value(transactionDate);
  static Insertable<CachedTransaction> custom({
    Expression<int>? id,
    Expression<double>? amount,
    Expression<String>? transactionType,
    Expression<String>? senderName,
    Expression<String>? receiverName,
    Expression<String>? note,
    Expression<int>? accountId,
    Expression<int>? fromAccountId,
    Expression<int>? toAccountId,
    Expression<String>? source,
    Expression<String>? localImageName,
    Expression<DateTime>? transactionDate,
    Expression<int>? categoryId,
    Expression<bool>? isJunk,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (transactionType != null) 'transaction_type': transactionType,
      if (senderName != null) 'sender_name': senderName,
      if (receiverName != null) 'receiver_name': receiverName,
      if (note != null) 'note': note,
      if (accountId != null) 'account_id': accountId,
      if (fromAccountId != null) 'from_account_id': fromAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (source != null) 'source': source,
      if (localImageName != null) 'local_image_name': localImageName,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (categoryId != null) 'category_id': categoryId,
      if (isJunk != null) 'is_junk': isJunk,
    });
  }

  CachedTransactionsCompanion copyWith({
    Value<int>? id,
    Value<double>? amount,
    Value<String>? transactionType,
    Value<String>? senderName,
    Value<String>? receiverName,
    Value<String>? note,
    Value<int?>? accountId,
    Value<int?>? fromAccountId,
    Value<int?>? toAccountId,
    Value<String>? source,
    Value<String?>? localImageName,
    Value<DateTime>? transactionDate,
    Value<int?>? categoryId,
    Value<bool>? isJunk,
  }) {
    return CachedTransactionsCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      note: note ?? this.note,
      accountId: accountId ?? this.accountId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      source: source ?? this.source,
      localImageName: localImageName ?? this.localImageName,
      transactionDate: transactionDate ?? this.transactionDate,
      categoryId: categoryId ?? this.categoryId,
      isJunk: isJunk ?? this.isJunk,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
    }
    if (receiverName.present) {
      map['receiver_name'] = Variable<String>(receiverName.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (fromAccountId.present) {
      map['from_account_id'] = Variable<int>(fromAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<int>(toAccountId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (localImageName.present) {
      map['local_image_name'] = Variable<String>(localImageName.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (isJunk.present) {
      map['is_junk'] = Variable<bool>(isJunk.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('transactionType: $transactionType, ')
          ..write('senderName: $senderName, ')
          ..write('receiverName: $receiverName, ')
          ..write('note: $note, ')
          ..write('accountId: $accountId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('source: $source, ')
          ..write('localImageName: $localImageName, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('categoryId: $categoryId, ')
          ..write('isJunk: $isJunk')
          ..write(')'))
        .toString();
  }
}

class $CachedAccountsTable extends CachedAccounts
    with TableInfo<$CachedAccountsTable, CachedAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta(
    'openingBalance',
  );
  @override
  late final GeneratedColumn<double> openingBalance = GeneratedColumn<double>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchingKeywordsJsonMeta =
      const VerificationMeta('matchingKeywordsJson');
  @override
  late final GeneratedColumn<String> matchingKeywordsJson =
      GeneratedColumn<String>(
        'matching_keywords_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _bankIconMeta = const VerificationMeta(
    'bankIcon',
  );
  @override
  late final GeneratedColumn<String> bankIcon = GeneratedColumn<String>(
    'bank_icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    accountType,
    openingBalance,
    matchingKeywordsJson,
    bankIcon,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingBalanceMeta);
    }
    if (data.containsKey('matching_keywords_json')) {
      context.handle(
        _matchingKeywordsJsonMeta,
        matchingKeywordsJson.isAcceptableOrUnknown(
          data['matching_keywords_json']!,
          _matchingKeywordsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matchingKeywordsJsonMeta);
    }
    if (data.containsKey('bank_icon')) {
      context.handle(
        _bankIconMeta,
        bankIcon.isAcceptableOrUnknown(data['bank_icon']!, _bankIconMeta),
      );
    } else if (isInserting) {
      context.missing(_bankIconMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      )!,
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opening_balance'],
      )!,
      matchingKeywordsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matching_keywords_json'],
      )!,
      bankIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_icon'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $CachedAccountsTable createAlias(String alias) {
    return $CachedAccountsTable(attachedDatabase, alias);
  }
}

class CachedAccount extends DataClass implements Insertable<CachedAccount> {
  final int id;
  final String name;
  final String accountType;
  final double openingBalance;
  final String matchingKeywordsJson;
  final String bankIcon;
  final bool isActive;
  const CachedAccount({
    required this.id,
    required this.name,
    required this.accountType,
    required this.openingBalance,
    required this.matchingKeywordsJson,
    required this.bankIcon,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['account_type'] = Variable<String>(accountType);
    map['opening_balance'] = Variable<double>(openingBalance);
    map['matching_keywords_json'] = Variable<String>(matchingKeywordsJson);
    map['bank_icon'] = Variable<String>(bankIcon);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  CachedAccountsCompanion toCompanion(bool nullToAbsent) {
    return CachedAccountsCompanion(
      id: Value(id),
      name: Value(name),
      accountType: Value(accountType),
      openingBalance: Value(openingBalance),
      matchingKeywordsJson: Value(matchingKeywordsJson),
      bankIcon: Value(bankIcon),
      isActive: Value(isActive),
    );
  }

  factory CachedAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAccount(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      accountType: serializer.fromJson<String>(json['accountType']),
      openingBalance: serializer.fromJson<double>(json['openingBalance']),
      matchingKeywordsJson: serializer.fromJson<String>(
        json['matchingKeywordsJson'],
      ),
      bankIcon: serializer.fromJson<String>(json['bankIcon']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'accountType': serializer.toJson<String>(accountType),
      'openingBalance': serializer.toJson<double>(openingBalance),
      'matchingKeywordsJson': serializer.toJson<String>(matchingKeywordsJson),
      'bankIcon': serializer.toJson<String>(bankIcon),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  CachedAccount copyWith({
    int? id,
    String? name,
    String? accountType,
    double? openingBalance,
    String? matchingKeywordsJson,
    String? bankIcon,
    bool? isActive,
  }) => CachedAccount(
    id: id ?? this.id,
    name: name ?? this.name,
    accountType: accountType ?? this.accountType,
    openingBalance: openingBalance ?? this.openingBalance,
    matchingKeywordsJson: matchingKeywordsJson ?? this.matchingKeywordsJson,
    bankIcon: bankIcon ?? this.bankIcon,
    isActive: isActive ?? this.isActive,
  );
  CachedAccount copyWithCompanion(CachedAccountsCompanion data) {
    return CachedAccount(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      matchingKeywordsJson: data.matchingKeywordsJson.present
          ? data.matchingKeywordsJson.value
          : this.matchingKeywordsJson,
      bankIcon: data.bankIcon.present ? data.bankIcon.value : this.bankIcon,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAccount(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('matchingKeywordsJson: $matchingKeywordsJson, ')
          ..write('bankIcon: $bankIcon, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    accountType,
    openingBalance,
    matchingKeywordsJson,
    bankIcon,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAccount &&
          other.id == this.id &&
          other.name == this.name &&
          other.accountType == this.accountType &&
          other.openingBalance == this.openingBalance &&
          other.matchingKeywordsJson == this.matchingKeywordsJson &&
          other.bankIcon == this.bankIcon &&
          other.isActive == this.isActive);
}

class CachedAccountsCompanion extends UpdateCompanion<CachedAccount> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> accountType;
  final Value<double> openingBalance;
  final Value<String> matchingKeywordsJson;
  final Value<String> bankIcon;
  final Value<bool> isActive;
  const CachedAccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.accountType = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.matchingKeywordsJson = const Value.absent(),
    this.bankIcon = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  CachedAccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String accountType,
    required double openingBalance,
    required String matchingKeywordsJson,
    required String bankIcon,
    required bool isActive,
  }) : name = Value(name),
       accountType = Value(accountType),
       openingBalance = Value(openingBalance),
       matchingKeywordsJson = Value(matchingKeywordsJson),
       bankIcon = Value(bankIcon),
       isActive = Value(isActive);
  static Insertable<CachedAccount> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? accountType,
    Expression<double>? openingBalance,
    Expression<String>? matchingKeywordsJson,
    Expression<String>? bankIcon,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (accountType != null) 'account_type': accountType,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (matchingKeywordsJson != null)
        'matching_keywords_json': matchingKeywordsJson,
      if (bankIcon != null) 'bank_icon': bankIcon,
      if (isActive != null) 'is_active': isActive,
    });
  }

  CachedAccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? accountType,
    Value<double>? openingBalance,
    Value<String>? matchingKeywordsJson,
    Value<String>? bankIcon,
    Value<bool>? isActive,
  }) {
    return CachedAccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      openingBalance: openingBalance ?? this.openingBalance,
      matchingKeywordsJson: matchingKeywordsJson ?? this.matchingKeywordsJson,
      bankIcon: bankIcon ?? this.bankIcon,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<double>(openingBalance.value);
    }
    if (matchingKeywordsJson.present) {
      map['matching_keywords_json'] = Variable<String>(
        matchingKeywordsJson.value,
      );
    }
    if (bankIcon.present) {
      map['bank_icon'] = Variable<String>(bankIcon.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('matchingKeywordsJson: $matchingKeywordsJson, ')
          ..write('bankIcon: $bankIcon, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $CachedCategoriesTable extends CachedCategories
    with TableInfo<$CachedCategoriesTable, CachedCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, type, iconKey, colorHex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
    );
  }

  @override
  $CachedCategoriesTable createAlias(String alias) {
    return $CachedCategoriesTable(attachedDatabase, alias);
  }
}

class CachedCategory extends DataClass implements Insertable<CachedCategory> {
  final int id;
  final String name;
  final String type;
  final String iconKey;
  final String colorHex;
  const CachedCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorHex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['icon_key'] = Variable<String>(iconKey);
    map['color_hex'] = Variable<String>(colorHex);
    return map;
  }

  CachedCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      iconKey: Value(iconKey),
      colorHex: Value(colorHex),
    );
  }

  factory CachedCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'iconKey': serializer.toJson<String>(iconKey),
      'colorHex': serializer.toJson<String>(colorHex),
    };
  }

  CachedCategory copyWith({
    int? id,
    String? name,
    String? type,
    String? iconKey,
    String? colorHex,
  }) => CachedCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    iconKey: iconKey ?? this.iconKey,
    colorHex: colorHex ?? this.colorHex,
  );
  CachedCategory copyWithCompanion(CachedCategoriesCompanion data) {
    return CachedCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorHex: $colorHex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, iconKey, colorHex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.iconKey == this.iconKey &&
          other.colorHex == this.colorHex);
}

class CachedCategoriesCompanion extends UpdateCompanion<CachedCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String> iconKey;
  final Value<String> colorHex;
  const CachedCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorHex = const Value.absent(),
  });
  CachedCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    required String iconKey,
    required String colorHex,
  }) : name = Value(name),
       type = Value(type),
       iconKey = Value(iconKey),
       colorHex = Value(colorHex);
  static Insertable<CachedCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? iconKey,
    Expression<String>? colorHex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorHex != null) 'color_hex': colorHex,
    });
  }

  CachedCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String>? iconKey,
    Value<String>? colorHex,
  }) {
    return CachedCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorHex: $colorHex')
          ..write(')'))
        .toString();
  }
}

class $PendingManualActionsTable extends PendingManualActions
    with TableInfo<$PendingManualActionsTable, PendingManualAction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingManualActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
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
  static const VerificationMeta _targetTransactionIdMeta =
      const VerificationMeta('targetTransactionId');
  @override
  late final GeneratedColumn<int> targetTransactionId = GeneratedColumn<int>(
    'target_transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actionType,
    payloadJson,
    targetTransactionId,
    createdAt,
    retryCount,
    lastErrorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_manual_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingManualAction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
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
    if (data.containsKey('target_transaction_id')) {
      context.handle(
        _targetTransactionIdMeta,
        targetTransactionId.isAcceptableOrUnknown(
          data['target_transaction_id']!,
          _targetTransactionIdMeta,
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
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingManualAction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingManualAction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      targetTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_transaction_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
    );
  }

  @override
  $PendingManualActionsTable createAlias(String alias) {
    return $PendingManualActionsTable(attachedDatabase, alias);
  }
}

class PendingManualAction extends DataClass
    implements Insertable<PendingManualAction> {
  final int id;
  final String actionType;
  final String payloadJson;
  final int? targetTransactionId;
  final DateTime createdAt;
  final int retryCount;
  final String? lastErrorCode;
  const PendingManualAction({
    required this.id,
    required this.actionType,
    required this.payloadJson,
    this.targetTransactionId,
    required this.createdAt,
    required this.retryCount,
    this.lastErrorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action_type'] = Variable<String>(actionType);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || targetTransactionId != null) {
      map['target_transaction_id'] = Variable<int>(targetTransactionId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    return map;
  }

  PendingManualActionsCompanion toCompanion(bool nullToAbsent) {
    return PendingManualActionsCompanion(
      id: Value(id),
      actionType: Value(actionType),
      payloadJson: Value(payloadJson),
      targetTransactionId: targetTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetTransactionId),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
    );
  }

  factory PendingManualAction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingManualAction(
      id: serializer.fromJson<int>(json['id']),
      actionType: serializer.fromJson<String>(json['actionType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      targetTransactionId: serializer.fromJson<int?>(
        json['targetTransactionId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'actionType': serializer.toJson<String>(actionType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'targetTransactionId': serializer.toJson<int?>(targetTransactionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
    };
  }

  PendingManualAction copyWith({
    int? id,
    String? actionType,
    String? payloadJson,
    Value<int?> targetTransactionId = const Value.absent(),
    DateTime? createdAt,
    int? retryCount,
    Value<String?> lastErrorCode = const Value.absent(),
  }) => PendingManualAction(
    id: id ?? this.id,
    actionType: actionType ?? this.actionType,
    payloadJson: payloadJson ?? this.payloadJson,
    targetTransactionId: targetTransactionId.present
        ? targetTransactionId.value
        : this.targetTransactionId,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
  );
  PendingManualAction copyWithCompanion(PendingManualActionsCompanion data) {
    return PendingManualAction(
      id: data.id.present ? data.id.value : this.id,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      targetTransactionId: data.targetTransactionId.present
          ? data.targetTransactionId.value
          : this.targetTransactionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingManualAction(')
          ..write('id: $id, ')
          ..write('actionType: $actionType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('targetTransactionId: $targetTransactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actionType,
    payloadJson,
    targetTransactionId,
    createdAt,
    retryCount,
    lastErrorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingManualAction &&
          other.id == this.id &&
          other.actionType == this.actionType &&
          other.payloadJson == this.payloadJson &&
          other.targetTransactionId == this.targetTransactionId &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastErrorCode == this.lastErrorCode);
}

class PendingManualActionsCompanion
    extends UpdateCompanion<PendingManualAction> {
  final Value<int> id;
  final Value<String> actionType;
  final Value<String> payloadJson;
  final Value<int?> targetTransactionId;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastErrorCode;
  const PendingManualActionsCompanion({
    this.id = const Value.absent(),
    this.actionType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.targetTransactionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
  });
  PendingManualActionsCompanion.insert({
    this.id = const Value.absent(),
    required String actionType,
    required String payloadJson,
    this.targetTransactionId = const Value.absent(),
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
  }) : actionType = Value(actionType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<PendingManualAction> custom({
    Expression<int>? id,
    Expression<String>? actionType,
    Expression<String>? payloadJson,
    Expression<int>? targetTransactionId,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastErrorCode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actionType != null) 'action_type': actionType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (targetTransactionId != null)
        'target_transaction_id': targetTransactionId,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
    });
  }

  PendingManualActionsCompanion copyWith({
    Value<int>? id,
    Value<String>? actionType,
    Value<String>? payloadJson,
    Value<int?>? targetTransactionId,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String?>? lastErrorCode,
  }) {
    return PendingManualActionsCompanion(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      payloadJson: payloadJson ?? this.payloadJson,
      targetTransactionId: targetTransactionId ?? this.targetTransactionId,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (targetTransactionId.present) {
      map['target_transaction_id'] = Variable<int>(targetTransactionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingManualActionsCompanion(')
          ..write('id: $id, ')
          ..write('actionType: $actionType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('targetTransactionId: $targetTransactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScannedSlipsTable scannedSlips = $ScannedSlipsTable(this);
  late final $CachedTransactionsTable cachedTransactions =
      $CachedTransactionsTable(this);
  late final $CachedAccountsTable cachedAccounts = $CachedAccountsTable(this);
  late final $CachedCategoriesTable cachedCategories = $CachedCategoriesTable(
    this,
  );
  late final $PendingManualActionsTable pendingManualActions =
      $PendingManualActionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    scannedSlips,
    cachedTransactions,
    cachedAccounts,
    cachedCategories,
    pendingManualActions,
  ];
}

typedef $$ScannedSlipsTableCreateCompanionBuilder =
    ScannedSlipsCompanion Function({
      required String localImageName,
      required String sourceFolder,
      required SlipStatus status,
      Value<int?> serverTransactionId,
      Value<int> retryCount,
      Value<String?> lastErrorCode,
      required DateTime scannedAt,
      Value<int> rowid,
    });
typedef $$ScannedSlipsTableUpdateCompanionBuilder =
    ScannedSlipsCompanion Function({
      Value<String> localImageName,
      Value<String> sourceFolder,
      Value<SlipStatus> status,
      Value<int?> serverTransactionId,
      Value<int> retryCount,
      Value<String?> lastErrorCode,
      Value<DateTime> scannedAt,
      Value<int> rowid,
    });

class $$ScannedSlipsTableFilterComposer
    extends Composer<_$AppDatabase, $ScannedSlipsTable> {
  $$ScannedSlipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localImageName => $composableBuilder(
    column: $table.localImageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceFolder => $composableBuilder(
    column: $table.sourceFolder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SlipStatus, SlipStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get serverTransactionId => $composableBuilder(
    column: $table.serverTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScannedSlipsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScannedSlipsTable> {
  $$ScannedSlipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localImageName => $composableBuilder(
    column: $table.localImageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceFolder => $composableBuilder(
    column: $table.sourceFolder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverTransactionId => $composableBuilder(
    column: $table.serverTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScannedSlipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScannedSlipsTable> {
  $$ScannedSlipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localImageName => $composableBuilder(
    column: $table.localImageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceFolder => $composableBuilder(
    column: $table.sourceFolder,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SlipStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get serverTransactionId => $composableBuilder(
    column: $table.serverTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scannedAt =>
      $composableBuilder(column: $table.scannedAt, builder: (column) => column);
}

class $$ScannedSlipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScannedSlipsTable,
          ScannedSlip,
          $$ScannedSlipsTableFilterComposer,
          $$ScannedSlipsTableOrderingComposer,
          $$ScannedSlipsTableAnnotationComposer,
          $$ScannedSlipsTableCreateCompanionBuilder,
          $$ScannedSlipsTableUpdateCompanionBuilder,
          (
            ScannedSlip,
            BaseReferences<_$AppDatabase, $ScannedSlipsTable, ScannedSlip>,
          ),
          ScannedSlip,
          PrefetchHooks Function()
        > {
  $$ScannedSlipsTableTableManager(_$AppDatabase db, $ScannedSlipsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScannedSlipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScannedSlipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScannedSlipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localImageName = const Value.absent(),
                Value<String> sourceFolder = const Value.absent(),
                Value<SlipStatus> status = const Value.absent(),
                Value<int?> serverTransactionId = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<DateTime> scannedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScannedSlipsCompanion(
                localImageName: localImageName,
                sourceFolder: sourceFolder,
                status: status,
                serverTransactionId: serverTransactionId,
                retryCount: retryCount,
                lastErrorCode: lastErrorCode,
                scannedAt: scannedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localImageName,
                required String sourceFolder,
                required SlipStatus status,
                Value<int?> serverTransactionId = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                required DateTime scannedAt,
                Value<int> rowid = const Value.absent(),
              }) => ScannedSlipsCompanion.insert(
                localImageName: localImageName,
                sourceFolder: sourceFolder,
                status: status,
                serverTransactionId: serverTransactionId,
                retryCount: retryCount,
                lastErrorCode: lastErrorCode,
                scannedAt: scannedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScannedSlipsTable, ScannedSlip>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ScannedSlipsTable,
                    ScannedSlip
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScannedSlipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScannedSlipsTable,
      ScannedSlip,
      $$ScannedSlipsTableFilterComposer,
      $$ScannedSlipsTableOrderingComposer,
      $$ScannedSlipsTableAnnotationComposer,
      $$ScannedSlipsTableCreateCompanionBuilder,
      $$ScannedSlipsTableUpdateCompanionBuilder,
      (
        ScannedSlip,
        BaseReferences<_$AppDatabase, $ScannedSlipsTable, ScannedSlip>,
      ),
      ScannedSlip,
      PrefetchHooks Function()
    >;
typedef $$CachedTransactionsTableCreateCompanionBuilder =
    CachedTransactionsCompanion Function({
      Value<int> id,
      required double amount,
      required String transactionType,
      Value<String> senderName,
      Value<String> receiverName,
      Value<String> note,
      Value<int?> accountId,
      Value<int?> fromAccountId,
      Value<int?> toAccountId,
      required String source,
      Value<String?> localImageName,
      required DateTime transactionDate,
      Value<int?> categoryId,
      Value<bool> isJunk,
    });
typedef $$CachedTransactionsTableUpdateCompanionBuilder =
    CachedTransactionsCompanion Function({
      Value<int> id,
      Value<double> amount,
      Value<String> transactionType,
      Value<String> senderName,
      Value<String> receiverName,
      Value<String> note,
      Value<int?> accountId,
      Value<int?> fromAccountId,
      Value<int?> toAccountId,
      Value<String> source,
      Value<String?> localImageName,
      Value<DateTime> transactionDate,
      Value<int?> categoryId,
      Value<bool> isJunk,
    });

class $$CachedTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedTransactionsTable> {
  $$CachedTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiverName => $composableBuilder(
    column: $table.receiverName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localImageName => $composableBuilder(
    column: $table.localImageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isJunk => $composableBuilder(
    column: $table.isJunk,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedTransactionsTable> {
  $$CachedTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiverName => $composableBuilder(
    column: $table.receiverName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localImageName => $composableBuilder(
    column: $table.localImageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isJunk => $composableBuilder(
    column: $table.isJunk,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedTransactionsTable> {
  $$CachedTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiverName => $composableBuilder(
    column: $table.receiverName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get localImageName => $composableBuilder(
    column: $table.localImageName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isJunk =>
      $composableBuilder(column: $table.isJunk, builder: (column) => column);
}

class $$CachedTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedTransactionsTable,
          CachedTransaction,
          $$CachedTransactionsTableFilterComposer,
          $$CachedTransactionsTableOrderingComposer,
          $$CachedTransactionsTableAnnotationComposer,
          $$CachedTransactionsTableCreateCompanionBuilder,
          $$CachedTransactionsTableUpdateCompanionBuilder,
          (
            CachedTransaction,
            BaseReferences<
              _$AppDatabase,
              $CachedTransactionsTable,
              CachedTransaction
            >,
          ),
          CachedTransaction,
          PrefetchHooks Function()
        > {
  $$CachedTransactionsTableTableManager(
    _$AppDatabase db,
    $CachedTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<String> senderName = const Value.absent(),
                Value<String> receiverName = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<int?> fromAccountId = const Value.absent(),
                Value<int?> toAccountId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> localImageName = const Value.absent(),
                Value<DateTime> transactionDate = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<bool> isJunk = const Value.absent(),
              }) => CachedTransactionsCompanion(
                id: id,
                amount: amount,
                transactionType: transactionType,
                senderName: senderName,
                receiverName: receiverName,
                note: note,
                accountId: accountId,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                source: source,
                localImageName: localImageName,
                transactionDate: transactionDate,
                categoryId: categoryId,
                isJunk: isJunk,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double amount,
                required String transactionType,
                Value<String> senderName = const Value.absent(),
                Value<String> receiverName = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<int?> fromAccountId = const Value.absent(),
                Value<int?> toAccountId = const Value.absent(),
                required String source,
                Value<String?> localImageName = const Value.absent(),
                required DateTime transactionDate,
                Value<int?> categoryId = const Value.absent(),
                Value<bool> isJunk = const Value.absent(),
              }) => CachedTransactionsCompanion.insert(
                id: id,
                amount: amount,
                transactionType: transactionType,
                senderName: senderName,
                receiverName: receiverName,
                note: note,
                accountId: accountId,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                source: source,
                localImageName: localImageName,
                transactionDate: transactionDate,
                categoryId: categoryId,
                isJunk: isJunk,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedTransactionsTable, CachedTransaction>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedTransactionsTable,
                    CachedTransaction
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedTransactionsTable,
      CachedTransaction,
      $$CachedTransactionsTableFilterComposer,
      $$CachedTransactionsTableOrderingComposer,
      $$CachedTransactionsTableAnnotationComposer,
      $$CachedTransactionsTableCreateCompanionBuilder,
      $$CachedTransactionsTableUpdateCompanionBuilder,
      (
        CachedTransaction,
        BaseReferences<
          _$AppDatabase,
          $CachedTransactionsTable,
          CachedTransaction
        >,
      ),
      CachedTransaction,
      PrefetchHooks Function()
    >;
typedef $$CachedAccountsTableCreateCompanionBuilder =
    CachedAccountsCompanion Function({
      Value<int> id,
      required String name,
      required String accountType,
      required double openingBalance,
      required String matchingKeywordsJson,
      required String bankIcon,
      required bool isActive,
    });
typedef $$CachedAccountsTableUpdateCompanionBuilder =
    CachedAccountsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> accountType,
      Value<double> openingBalance,
      Value<String> matchingKeywordsJson,
      Value<String> bankIcon,
      Value<bool> isActive,
    });

class $$CachedAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAccountsTable> {
  $$CachedAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchingKeywordsJson => $composableBuilder(
    column: $table.matchingKeywordsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankIcon => $composableBuilder(
    column: $table.bankIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAccountsTable> {
  $$CachedAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchingKeywordsJson => $composableBuilder(
    column: $table.matchingKeywordsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankIcon => $composableBuilder(
    column: $table.bankIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAccountsTable> {
  $$CachedAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchingKeywordsJson => $composableBuilder(
    column: $table.matchingKeywordsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankIcon =>
      $composableBuilder(column: $table.bankIcon, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$CachedAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedAccountsTable,
          CachedAccount,
          $$CachedAccountsTableFilterComposer,
          $$CachedAccountsTableOrderingComposer,
          $$CachedAccountsTableAnnotationComposer,
          $$CachedAccountsTableCreateCompanionBuilder,
          $$CachedAccountsTableUpdateCompanionBuilder,
          (
            CachedAccount,
            BaseReferences<_$AppDatabase, $CachedAccountsTable, CachedAccount>,
          ),
          CachedAccount,
          PrefetchHooks Function()
        > {
  $$CachedAccountsTableTableManager(
    _$AppDatabase db,
    $CachedAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<double> openingBalance = const Value.absent(),
                Value<String> matchingKeywordsJson = const Value.absent(),
                Value<String> bankIcon = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => CachedAccountsCompanion(
                id: id,
                name: name,
                accountType: accountType,
                openingBalance: openingBalance,
                matchingKeywordsJson: matchingKeywordsJson,
                bankIcon: bankIcon,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String accountType,
                required double openingBalance,
                required String matchingKeywordsJson,
                required String bankIcon,
                required bool isActive,
              }) => CachedAccountsCompanion.insert(
                id: id,
                name: name,
                accountType: accountType,
                openingBalance: openingBalance,
                matchingKeywordsJson: matchingKeywordsJson,
                bankIcon: bankIcon,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedAccountsTable, CachedAccount>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedAccountsTable,
                    CachedAccount
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedAccountsTable,
      CachedAccount,
      $$CachedAccountsTableFilterComposer,
      $$CachedAccountsTableOrderingComposer,
      $$CachedAccountsTableAnnotationComposer,
      $$CachedAccountsTableCreateCompanionBuilder,
      $$CachedAccountsTableUpdateCompanionBuilder,
      (
        CachedAccount,
        BaseReferences<_$AppDatabase, $CachedAccountsTable, CachedAccount>,
      ),
      CachedAccount,
      PrefetchHooks Function()
    >;
typedef $$CachedCategoriesTableCreateCompanionBuilder =
    CachedCategoriesCompanion Function({
      Value<int> id,
      required String name,
      required String type,
      required String iconKey,
      required String colorHex,
    });
typedef $$CachedCategoriesTableUpdateCompanionBuilder =
    CachedCategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> type,
      Value<String> iconKey,
      Value<String> colorHex,
    });

class $$CachedCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);
}

class $$CachedCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCategoriesTable,
          CachedCategory,
          $$CachedCategoriesTableFilterComposer,
          $$CachedCategoriesTableOrderingComposer,
          $$CachedCategoriesTableAnnotationComposer,
          $$CachedCategoriesTableCreateCompanionBuilder,
          $$CachedCategoriesTableUpdateCompanionBuilder,
          (
            CachedCategory,
            BaseReferences<
              _$AppDatabase,
              $CachedCategoriesTable,
              CachedCategory
            >,
          ),
          CachedCategory,
          PrefetchHooks Function()
        > {
  $$CachedCategoriesTableTableManager(
    _$AppDatabase db,
    $CachedCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
              }) => CachedCategoriesCompanion(
                id: id,
                name: name,
                type: type,
                iconKey: iconKey,
                colorHex: colorHex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String type,
                required String iconKey,
                required String colorHex,
              }) => CachedCategoriesCompanion.insert(
                id: id,
                name: name,
                type: type,
                iconKey: iconKey,
                colorHex: colorHex,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedCategoriesTable, CachedCategory>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedCategoriesTable,
                    CachedCategory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCategoriesTable,
      CachedCategory,
      $$CachedCategoriesTableFilterComposer,
      $$CachedCategoriesTableOrderingComposer,
      $$CachedCategoriesTableAnnotationComposer,
      $$CachedCategoriesTableCreateCompanionBuilder,
      $$CachedCategoriesTableUpdateCompanionBuilder,
      (
        CachedCategory,
        BaseReferences<_$AppDatabase, $CachedCategoriesTable, CachedCategory>,
      ),
      CachedCategory,
      PrefetchHooks Function()
    >;
typedef $$PendingManualActionsTableCreateCompanionBuilder =
    PendingManualActionsCompanion Function({
      Value<int> id,
      required String actionType,
      required String payloadJson,
      Value<int?> targetTransactionId,
      required DateTime createdAt,
      Value<int> retryCount,
      Value<String?> lastErrorCode,
    });
typedef $$PendingManualActionsTableUpdateCompanionBuilder =
    PendingManualActionsCompanion Function({
      Value<int> id,
      Value<String> actionType,
      Value<String> payloadJson,
      Value<int?> targetTransactionId,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String?> lastErrorCode,
    });

class $$PendingManualActionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingManualActionsTable> {
  $$PendingManualActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetTransactionId => $composableBuilder(
    column: $table.targetTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingManualActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingManualActionsTable> {
  $$PendingManualActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetTransactionId => $composableBuilder(
    column: $table.targetTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingManualActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingManualActionsTable> {
  $$PendingManualActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetTransactionId => $composableBuilder(
    column: $table.targetTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );
}

class $$PendingManualActionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingManualActionsTable,
          PendingManualAction,
          $$PendingManualActionsTableFilterComposer,
          $$PendingManualActionsTableOrderingComposer,
          $$PendingManualActionsTableAnnotationComposer,
          $$PendingManualActionsTableCreateCompanionBuilder,
          $$PendingManualActionsTableUpdateCompanionBuilder,
          (
            PendingManualAction,
            BaseReferences<
              _$AppDatabase,
              $PendingManualActionsTable,
              PendingManualAction
            >,
          ),
          PendingManualAction,
          PrefetchHooks Function()
        > {
  $$PendingManualActionsTableTableManager(
    _$AppDatabase db,
    $PendingManualActionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingManualActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingManualActionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingManualActionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int?> targetTransactionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
              }) => PendingManualActionsCompanion(
                id: id,
                actionType: actionType,
                payloadJson: payloadJson,
                targetTransactionId: targetTransactionId,
                createdAt: createdAt,
                retryCount: retryCount,
                lastErrorCode: lastErrorCode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String actionType,
                required String payloadJson,
                Value<int?> targetTransactionId = const Value.absent(),
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
              }) => PendingManualActionsCompanion.insert(
                id: id,
                actionType: actionType,
                payloadJson: payloadJson,
                targetTransactionId: targetTransactionId,
                createdAt: createdAt,
                retryCount: retryCount,
                lastErrorCode: lastErrorCode,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingManualActionsTable, PendingManualAction>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingManualActionsTable,
                    PendingManualAction
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingManualActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingManualActionsTable,
      PendingManualAction,
      $$PendingManualActionsTableFilterComposer,
      $$PendingManualActionsTableOrderingComposer,
      $$PendingManualActionsTableAnnotationComposer,
      $$PendingManualActionsTableCreateCompanionBuilder,
      $$PendingManualActionsTableUpdateCompanionBuilder,
      (
        PendingManualAction,
        BaseReferences<
          _$AppDatabase,
          $PendingManualActionsTable,
          PendingManualAction
        >,
      ),
      PendingManualAction,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScannedSlipsTableTableManager get scannedSlips =>
      $$ScannedSlipsTableTableManager(_db, _db.scannedSlips);
  $$CachedTransactionsTableTableManager get cachedTransactions =>
      $$CachedTransactionsTableTableManager(_db, _db.cachedTransactions);
  $$CachedAccountsTableTableManager get cachedAccounts =>
      $$CachedAccountsTableTableManager(_db, _db.cachedAccounts);
  $$CachedCategoriesTableTableManager get cachedCategories =>
      $$CachedCategoriesTableTableManager(_db, _db.cachedCategories);
  $$PendingManualActionsTableTableManager get pendingManualActions =>
      $$PendingManualActionsTableTableManager(_db, _db.pendingManualActions);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

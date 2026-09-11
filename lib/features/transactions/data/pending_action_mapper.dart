import 'dart:convert';

import '../../../core/db/app_database.dart' show PendingManualAction;
import '../../../core/network/failure.dart';
import '../domain/pending_action.dart';

PendingAction pendingActionFromRow(PendingManualAction row) => PendingAction(
  id: row.id,
  actionType: pendingActionTypeFromWire(row.actionType),
  payload: jsonDecode(row.payloadJson) as Map<String, dynamic>,
  targetTransactionId: row.targetTransactionId,
  createdAt: row.createdAt,
  retryCount: row.retryCount,
  lastErrorCode: row.lastErrorCode,
);

/// Reverse of `Failure.fromErrorCode` — every `Failure` subtype maps back to
/// a stable tag so `lastErrorCode` always has something displayable, even for
/// subtypes (`NoConnectionFailure`, `UnknownFailure`) with no message
/// guaranteed. Exhaustive over the sealed `Failure` type: the compiler flags
/// this switch if a new subtype is ever added.
String? errorTagForFailure(Failure failure) => switch (failure) {
  TimeoutFailure() => 'DATABASE_TIMEOUT',
  GeminiUnavailableFailure() => 'GEMINI_SERVICE_ERROR',
  InternalDbFailure() => 'INTERNAL_DATABASE_ERROR',
  ContextCanceledFailure() => 'REQUEST_CANCELED',
  NoConnectionFailure() => 'NO_CONNECTION',
  NotFoundFailure() => 'RESOURCE_NOT_FOUND',
  DuplicateRequestFailure() => 'DUPLICATE_RESOURCE',
  InvalidInputFailure() => 'INVALID_INPUT_PARAMETERS',
  SlipParseFailedFailure() => 'SLIP_PARSE_FAILED',
  AccountInactiveFailure() => 'ACCOUNT_INACTIVE',
  TransferSameAccountFailure() => 'TRANSFER_SAME_ACCOUNT',
  CategoryNotAllowedForTransferFailure() => 'CATEGORY_NOT_ALLOWED_FOR_TRANSFER',
  GeminiQuotaExhaustedFailure() => 'GEMINI_QUOTA_EXHAUSTED',
  UnknownFailure(code: final code) => code,
};

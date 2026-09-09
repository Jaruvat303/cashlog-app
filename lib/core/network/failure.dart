import 'package:dio/dio.dart';

/// How a [Failure] should be handled by callers, per spec §4 retry table.
enum RetryPolicy {
  /// Auto-retry (dio_client's retry interceptor already attempts this
  /// before a Failure ever reaches a repository).
  transient,

  /// Surface to the user, no auto-retry.
  permanent,

  /// ErrGeminiQuotaExhausted: don't retry immediately — the next scan
  /// cycle picks it up. Handled by the slip-scan feature (T10/T15), not here.
  specialCase,
}

/// Errors are always surfaced as `Either<Failure, T>` — never thrown across
/// layers. dio_client's interceptor is the only place a DioException gets
/// caught and converted into one of these.
sealed class Failure {
  const Failure({this.message, this.statusCode});

  final String? message;
  final int? statusCode;

  RetryPolicy get retryPolicy;

  /// Maps a backend `error_code` string to its typed Failure. Falls back to
  /// [UnknownFailure] for anything unrecognized so an unfamiliar/future
  /// error code can never crash the app.
  ///
  /// These string keys are the real values `internal/delivery/http/middleware/
  /// error_handler.go` (cashlog-api) sends — UPPER_SNAKE_CASE, not the
  /// `ErrXxx` Go identifier names CLAUDE.md/spec §4 describe. Confirmed by
  /// reading that file directly (T10); the old `ErrXxx` keys never matched
  /// anything live, so every real error response was silently falling
  /// through to [UnknownFailure] before this fix.
  ///
  /// One genuine spec conflict found in the process: the backend collapses
  /// what spec §4 lists as two codes with opposite retry policies —
  /// `ErrGeminiUnavailable` (transient) and `ErrGeminiEmptyResponse`
  /// (permanent) — into a single `GEMINI_SERVICE_ERROR`, with no way for the
  /// client to tell them apart. Treated as transient here (approved default):
  /// dio's retry cap is 2 attempts (~2s), so a wrongly-retried permanent
  /// error costs little, while a wrongly-surfaced transient one costs a
  /// needless user-facing failure on every slip scan.
  factory Failure.fromErrorCode(
    String? code, {
    String? message,
    int? statusCode,
  }) {
    return switch (code) {
      'DATABASE_TIMEOUT' => TimeoutFailure(message: message, statusCode: statusCode),
      'GEMINI_SERVICE_ERROR' => GeminiUnavailableFailure(message: message, statusCode: statusCode),
      'INTERNAL_DATABASE_ERROR' || 'INTERNAL_SERVER_ERROR' => InternalDbFailure(message: message, statusCode: statusCode),
      'REQUEST_CANCELED' => ContextCanceledFailure(message: message, statusCode: statusCode),
      'RESOURCE_NOT_FOUND' || 'URL_NOT_FOUND' => NotFoundFailure(message: message, statusCode: statusCode),
      'DUPLICATE_RESOURCE' => DuplicateRequestFailure(message: message, statusCode: statusCode),
      'INVALID_INPUT_PARAMETERS' || 'BAD_REQUEST_PARAMETERS' => InvalidInputFailure(message: message, statusCode: statusCode),
      'SLIP_PARSE_FAILED' => SlipParseFailedFailure(message: message, statusCode: statusCode),
      'ACCOUNT_INACTIVE' => AccountInactiveFailure(message: message, statusCode: statusCode),
      'TRANSFER_SAME_ACCOUNT' => TransferSameAccountFailure(message: message, statusCode: statusCode),
      'CATEGORY_NOT_ALLOWED_FOR_TRANSFER' => CategoryNotAllowedForTransferFailure(message: message, statusCode: statusCode),
      'GEMINI_QUOTA_EXHAUSTED' => GeminiQuotaExhaustedFailure(message: message, statusCode: statusCode),
      _ => UnknownFailure(code: code, message: message, statusCode: statusCode),
    };
  }

  /// Maps transport-level errors (no HTTP response at all, or an unparseable
  /// body) that never reach [fromErrorCode].
  factory Failure.fromDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout =>
        TimeoutFailure(message: e.message),
      DioExceptionType.connectionError => NoConnectionFailure(message: e.message),
      DioExceptionType.cancel => ContextCanceledFailure(message: e.message),
      DioExceptionType.badResponse => UnknownFailure(
          code: null,
          message: e.message,
          statusCode: e.response?.statusCode,
        ),
      DioExceptionType.badCertificate ||
      DioExceptionType.unknown =>
        UnknownFailure(code: null, message: e.message),
    };
  }
}

// ── Transient — auto-retry ────────────────────────────────────────────────

final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.transient;
}

/// Also covers what spec §4 calls `ErrGeminiEmptyResponse` — the backend
/// merges both into `GEMINI_SERVICE_ERROR` with no way to distinguish them
/// (see [Failure.fromErrorCode]'s doc comment).
final class GeminiUnavailableFailure extends Failure {
  const GeminiUnavailableFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.transient;
}

final class InternalDbFailure extends Failure {
  const InternalDbFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.transient;
}

final class ContextCanceledFailure extends Failure {
  const ContextCanceledFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.transient;
}

/// Client never reached the server at all (no connectivity, DNS, etc).
/// Not a named backend error_code, but transient in the same sense.
final class NoConnectionFailure extends Failure {
  const NoConnectionFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.transient;
}

// ── Permanent — surface to user, no auto-retry ────────────────────────────

final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.permanent;
}

final class DuplicateRequestFailure extends Failure {
  const DuplicateRequestFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.permanent;
}

final class InvalidInputFailure extends Failure {
  const InvalidInputFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.permanent;
}

final class SlipParseFailedFailure extends Failure {
  const SlipParseFailedFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.permanent;
}

final class AccountInactiveFailure extends Failure {
  const AccountInactiveFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.permanent;
}

final class TransferSameAccountFailure extends Failure {
  const TransferSameAccountFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.permanent;
}

final class CategoryNotAllowedForTransferFailure extends Failure {
  const CategoryNotAllowedForTransferFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.permanent;
}

// ── Special case ───────────────────────────────────────────────────────────

final class GeminiQuotaExhaustedFailure extends Failure {
  const GeminiQuotaExhaustedFailure({super.message, super.statusCode});
  @override
  RetryPolicy get retryPolicy => RetryPolicy.specialCase;
}

// ── Catch-all ──────────────────────────────────────────────────────────────

/// Anything not recognized above: a new/unseen backend error_code, a
/// malformed error body, or a transport error with no code at all. This is
/// what guarantees an unrecognized error never crashes the app.
final class UnknownFailure extends Failure {
  const UnknownFailure({this.code, super.message, super.statusCode});
  final String? code;
  @override
  RetryPolicy get retryPolicy => RetryPolicy.permanent;
}

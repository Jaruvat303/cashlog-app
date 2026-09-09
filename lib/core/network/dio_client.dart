import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../env/env.dart';
import 'failure.dart';

part 'dio_client.g.dart';

/// Transient failures (per spec §4 retry table) get this many automatic
/// retries before giving up and surfacing to the caller.
const _maxRetries = 2;
const _retryDelay = Duration(seconds: 1);

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-API-Key'] = Env.apiKey;
        handler.next(options);
      },
    ),
  );

  dio.interceptors.add(_ErrorAndRetryInterceptor(dio));

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
  }

  return dio;
}

/// Maps every DioException to a [Failure] (attached as `DioException.error`)
/// and auto-retries transient ones per spec §4, so a repository never has to
/// duplicate this logic.
class _ErrorAndRetryInterceptor extends Interceptor {
  _ErrorAndRetryInterceptor(this._dio);

  final Dio _dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final failure = _mapToFailure(err);
    final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;

    if (failure.retryPolicy == RetryPolicy.transient && retryCount < _maxRetries) {
      await Future<void>.delayed(_retryDelay);
      final options = err.requestOptions..extra['retryCount'] = retryCount + 1;
      try {
        final response = await _dio.fetch(options);
        return handler.resolve(response);
      } on DioException catch (retryError) {
        return onError(retryError, handler);
      }
    }

    handler.next(err.copyWith(error: failure));
  }

  Failure _mapToFailure(DioException err) {
    final data = err.response?.data;
    if (data is Map) {
      // Envelope confirmed against dev: {"success","error_code","message"}.
      // The actual error_code values (e.g. BAD_REQUEST_PARAMETERS,
      // RESOURCE_NOT_FOUND, GEMINI_SERVICE_ERROR) are UPPER_SNAKE_CASE, not
      // the ErrXxx names CLAUDE.md/spec §4 describe — confirmed by reading
      // cashlog-api's error_handler.go directly (T10) and fixed in
      // Failure.fromErrorCode's switch keys. CLIENT_ERROR (a generic fiber
      // fallback for status codes with no dedicated case) still falls
      // through to UnknownFailure by design, not by omission.
      final errorField = data['error'];
      final code = (data['error_code'] ?? data['code'] ?? (errorField is Map ? errorField['code'] : null))?.toString();
      final message = (data['message'] ?? (errorField is String ? errorField : null) ?? (errorField is Map ? errorField['message'] : null))?.toString();
      return Failure.fromErrorCode(code, message: message, statusCode: err.response?.statusCode);
    }
    return Failure.fromDioException(err);
  }
}

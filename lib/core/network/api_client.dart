import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dio_client.dart';
import 'failure.dart';

part 'api_client.g.dart';

/// Thin wrapper so repositories never touch [Dio]/[DioException] directly —
/// every call comes back as `Either<Failure, T>`, never a thrown exception
/// (CLAUDE.md: error handling pattern).
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) parse,
  }) => _run(() => _dio.get(path, queryParameters: queryParameters), parse);

  Future<Either<Failure, T>> post<T>(
    String path, {
    Object? data,
    required T Function(dynamic data) parse,
  }) => _run(() => _dio.post(path, data: data), parse);

  Future<Either<Failure, T>> patch<T>(
    String path, {
    Object? data,
    required T Function(dynamic data) parse,
  }) => _run(() => _dio.patch(path, data: data), parse);

  Future<Either<Failure, T>> delete<T>(
    String path, {
    required T Function(dynamic data) parse,
  }) => _run(() => _dio.delete(path), parse);

  Future<Either<Failure, T>> _run<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) parse,
  ) async {
    try {
      final response = await request();
      return Right(parse(response.data));
    } on DioException catch (e) {
      final failure = e.error;
      return Left(failure is Failure ? failure : Failure.fromDioException(e));
    } catch (e) {
      // Defensive catch-all (e.g. a bad `parse` cast) — this is what
      // guarantees an unrecognized error never crashes the app instead of
      // surfacing as an unhandled exception.
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

@riverpod
ApiClient apiClient(Ref ref) => ApiClient(ref.watch(dioProvider));

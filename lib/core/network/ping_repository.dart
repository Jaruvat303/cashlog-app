import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 'failure.dart';

part 'ping_repository.g.dart';

/// T1 scaffold-verification only: proves the dio client + X-API-Key
/// interceptor + `Either<Failure, T>` pattern work end-to-end against a real
/// deployment. Not a feature — features/ start at T4.
class PingRepository {
  PingRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Hits GET /api/v1/accounts (exercises the X-API-Key interceptor, unlike
  /// /health which needs no auth) and returns the raw decoded JSON.
  Future<Either<Failure, dynamic>> pingAccounts() {
    return _apiClient.get<dynamic>(
      '/api/v1/accounts',
      parse: (data) => data,
    );
  }
}

@riverpod
PingRepository pingRepository(Ref ref) => PingRepository(ref.watch(apiClientProvider));

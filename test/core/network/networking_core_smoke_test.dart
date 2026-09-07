// T1 DoD verification — hits the real dev Cloud Run deployment (read-only
// GET requests only). Run with:
//   flutter test --dart-define-from-file=env/dev.json test/core/network/networking_core_smoke_test.dart
import 'package:cashlog/core/network/api_client.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/core/network/ping_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GET /api/v1/accounts succeeds against dev and returns Right', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = await container.read(pingRepositoryProvider).pingAccounts();

    expect(
      result,
      isA<Right<Failure, dynamic>>(),
      reason: 'expected success, got: ${result.fold((f) => f, (r) => r)}',
    );
  });

  test('an unrecognized error maps to Failure instead of throwing', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final apiClient = container.read(apiClientProvider);
    final result = await apiClient.get<dynamic>(
      '/api/v1/this-route-does-not-exist',
      parse: (data) => data,
    );

    result.fold(
      (failure) => expect(failure, isA<Failure>()),
      (data) => fail('expected a Failure for a nonexistent route, got: $data'),
    );
  });
}

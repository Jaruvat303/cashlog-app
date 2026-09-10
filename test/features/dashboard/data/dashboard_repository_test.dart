// Same "fake dio HttpClientAdapter stands in for the network" reasoning as
// categories_repository_test.dart — this never lets a real request happen,
// and lets a canned JSON body exercise the real ApiClient/mapper path.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cashlog/core/network/api_client.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body, this.statusCode);

  final Map<String, dynamic> body;
  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    lastRequest = options;
    return ResponseBody.fromString(jsonEncode(body), statusCode, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('fetchSummary sends year/month as query params and parses the response', () async {
    final adapter = _FakeAdapter({
      'data': {
        'total_income': 5000,
        'total_expense': 2000,
        'total_transfer': 0,
        'scope': 'monthly',
        'year': 2026,
        'month': 9,
        'income': [],
        'expense': [
          {'category_id': 1, 'category_name': 'Food', 'icon_key': 'restaurant-fill', 'color_hex': '#EF4444', 'total_amount': 2000},
        ],
      },
    }, 200);
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = DashboardRepository(ApiClient(dio));

    final result = await repository.fetchSummary(year: 2026, month: 9);

    expect(adapter.lastRequest?.path, '/api/v1/transactions/summary');
    expect(adapter.lastRequest?.queryParameters, {'year': 2026, 'month': 9});
    result.fold((failure) => fail('expected success, got $failure'), (summary) {
      expect(summary.totalIncome, 5000);
      expect(summary.expense.single.categoryName, 'Food');
    });
  });

  test('fetchSummary surfaces a Left(Failure) on a non-2xx response', () async {
    final adapter = _FakeAdapter({'error_code': 'ErrInternalDB', 'message': 'db down'}, 500);
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = DashboardRepository(ApiClient(dio));

    final result = await repository.fetchSummary(year: 2026, month: 9);

    expect(result.isLeft(), isTrue);
  });
}

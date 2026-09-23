// Same "fake dio HttpClientAdapter stands in for the network" reasoning as
// categories_repository_test.dart — this never lets a real request happen,
// and lets a canned JSON body exercise the real ApiClient/mapper path.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cashlog/core/network/api_client.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/trend_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body, this.statusCode);

  final Map<String, dynamic> body;
  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'fetchSummary sends year/month as query params and parses the response',
    () async {
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
            {
              'category_id': 1,
              'category_name': 'Food',
              'icon_key': 'restaurant-fill',
              'color_hex': '#EF4444',
              'total_amount': 2000,
            },
          ],
        },
      }, 200);
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = DashboardRepository(ApiClient(dio));

      final result = await repository.fetchSummary(year: 2026, month: 9);

      expect(adapter.lastRequest?.path, '/api/v1/transactions/summary');
      expect(adapter.lastRequest?.queryParameters, {'year': 2026, 'month': 9});
      result.fold((failure) => fail('expected success, got $failure'), (
        summary,
      ) {
        expect(summary.totalIncome, 5000);
        expect(summary.expense.single.categoryName, 'Food');
      });
    },
  );

  test('fetchSummary surfaces a Left(Failure) on a non-2xx response', () async {
    final adapter = _FakeAdapter({
      'error_code': 'ErrInternalDB',
      'message': 'db down',
    }, 500);
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = DashboardRepository(ApiClient(dio));

    final result = await repository.fetchSummary(year: 2026, month: 9);

    expect(result.isLeft(), isTrue);
  });

  test('fetchTrend sends granularity and year as query params in month mode and parses the response', () async {
    final adapter = _FakeAdapter({
      'success': true,
      'message': '',
      'data': {
        'granularity': 'month',
        'year': 2026,
        'buckets': [
          {
            'year': 2026,
            'month': 1,
            'total_income': 45000,
            'total_expense': 32000,
            'net': 13000,
          },
        ],
      },
    }, 200);
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = DashboardRepository(ApiClient(dio));

    final result = await repository.fetchTrend(const TrendQuery.month(2026));

    expect(adapter.lastRequest?.path, '/api/v1/transactions/trend');
    expect(adapter.lastRequest?.queryParameters, {
      'granularity': 'month',
      'year': 2026,
    });
    result.fold((failure) => fail('expected success, got $failure'), (summary) {
      expect(summary.granularity, TrendGranularity.month);
      expect(summary.year, 2026);
      expect(summary.buckets, hasLength(1));
    });
  });

  test('fetchTrend omits year entirely in year mode', () async {
    final adapter = _FakeAdapter({
      'success': true,
      'message': '',
      'data': {
        'granularity': 'year',
        'year': null,
        'buckets': [
          {
            'year': 2026,
            'month': null,
            'total_income': 610250.75,
            'total_expense': 356000,
            'net': 254250.75,
          },
        ],
      },
    }, 200);
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = DashboardRepository(ApiClient(dio));

    final result = await repository.fetchTrend(const TrendQuery.year());

    expect(adapter.lastRequest?.path, '/api/v1/transactions/trend');
    expect(adapter.lastRequest?.queryParameters, {'granularity': 'year'});
    result.fold((failure) => fail('expected success, got $failure'), (summary) {
      expect(summary.granularity, TrendGranularity.year);
      expect(summary.year, isNull);
      expect(summary.buckets.single.month, isNull);
    });
  });

  test('fetchTrend surfaces a Left(Failure) on a non-2xx response', () async {
    final adapter = _FakeAdapter({
      'error_code': 'BAD_REQUEST_PARAMETERS',
      'message': 'year is required in month mode',
    }, 400);
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = DashboardRepository(ApiClient(dio));

    final result = await repository.fetchTrend(const TrendQuery.month(2026));

    expect(result.isLeft(), isTrue);
  });
}

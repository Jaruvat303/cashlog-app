import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../domain/dashboard_summary.dart';
import '../domain/trend_summary.dart';
import 'dashboard_mapper.dart';
import 'trend_mapper.dart';

part 'dashboard_repository.g.dart';

/// No local table backs this (spec §8's `cached_dashboard_summary` was
/// deliberately never added — the backend already has a 1h Redis cache) —
/// every call is a live `GET /api/v1/transactions/summary`, same as the two
/// "no dedicated endpoint" reads in this codebase resolve *away* from the
/// network instead of toward it (accounts §12.1, categories) — this one goes
/// the other way on purpose, since spec §11 says the summary is
/// in-memory-only, never disk-cached.
///
/// Confirmed against the live dev swagger doc: the endpoint lives under
/// `/transactions/summary`, not a top-level `/summary` as the ticket text
/// assumed — verified directly against a real `GET` response before fixing
/// this (the response envelope/field shapes already matched
/// `dashboard_mapper.dart` exactly, only the path was wrong).
class DashboardRepository {
  DashboardRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Either<Failure, DashboardSummary>> fetchSummary({
    required int year,
    required int month,
  }) => _apiClient.get<DashboardSummary>(
    '/api/v1/transactions/summary',
    queryParameters: {'year': year, 'month': month},
    parse: (data) =>
        dashboardSummaryFromJson((data as Map)['data'] as Map<String, dynamic>),
  );

  /// No local table backs this either, same reasoning as [fetchSummary]
  /// (spec's in-memory-only trend data decision) — `year` is only ever sent
  /// on the wire when [TrendQuery] carries one (month mode); year mode's
  /// `TrendQuery.year` always has `year == null`, so it's omitted here by
  /// construction rather than by a second branch that could drift out of
  /// sync with the query type.
  Future<Either<Failure, TrendSummary>> fetchTrend(TrendQuery query) =>
      _apiClient.get<TrendSummary>(
        '/api/v1/transactions/trend',
        queryParameters: {
          'granularity': query.granularity.queryValue,
          if (query.year != null) 'year': query.year,
        },
        parse: (data) =>
            trendSummaryFromJson((data as Map)['data'] as Map<String, dynamic>),
      );
}

@riverpod
DashboardRepository dashboardRepository(Ref ref) =>
    DashboardRepository(ref.watch(apiClientProvider));

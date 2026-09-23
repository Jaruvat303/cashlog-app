import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/segmented_tabs.dart';
import '../../domain/trend_summary.dart';
import '../providers/trend_providers.dart';
import '../widgets/trend_bar_chart.dart';

/// "เปรียบเทียบรายรับ–รายจ่าย" — pushed from an icon button on the "ดูสรุป" tab's
/// AppBar (`TransactionsPage`, route `/summary/trend`). Opens in monthly mode
/// for the current year (spec user story 2); ◀ year ▶ is visible only in
/// monthly mode and hidden in yearly mode (only one time control relevant to
/// what's on screen at once).
class TrendPage extends ConsumerStatefulWidget {
  const TrendPage({super.key});

  @override
  ConsumerState<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends ConsumerState<TrendPage> {
  TrendGranularity _granularity = TrendGranularity.month;
  late int _year = DateTime.now().year;

  TrendQuery get _query => _granularity == TrendGranularity.month
      ? TrendQuery.month(_year)
      : const TrendQuery.year();

  @override
  Widget build(BuildContext context) {
    final trendAsync = ref.watch(trendProvider(_query));
    // Read in the background, regardless of which mode is currently shown —
    // its `.value` is the cheapest available source for "how far back can
    // the year switcher go" (one bucket per year the backend has data for),
    // and it's `keepAlive` so yearly mode reuses this exact fetch rather
    // than triggering a second one when the user switches to it. Its own
    // loading/error state is deliberately ignored here (see
    // `_canGoBack` below) — this read exists only to learn a bound, not to
    // render anything itself.
    final yearModeAsync = ref.watch(trendProvider(const TrendQuery.year()));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('เปรียบเทียบรายรับ–รายจ่าย'),
      ),
      body: RefreshIndicator(
        // Spec addition: `trendProvider` is `keepAlive`, so an edit made
        // outside the app (e.g. curl against dev) would otherwise never be
        // reflected here — pull-to-refresh forces exactly the currently
        // shown query to refetch. `ref.refresh(...future)` both invalidates
        // and awaits the new fetch, which is exactly the `Future<void>`
        // `RefreshIndicator.onRefresh` needs.
        onRefresh: () => ref.refresh(trendProvider(_query).future),
        child: ListView(
          // A `ListView` (not a plain `Column`) with `AlwaysScrollableScrollPhysics`
          // — `RefreshIndicator` needs a scrollable child, and content that
          // already fits the screen (e.g. a short error/loading state) would
          // otherwise never register the pull gesture at all.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _ModeToggle(
              granularity: _granularity,
              onChanged: (granularity) =>
                  setState(() => _granularity = granularity),
            ),
            if (_granularity == TrendGranularity.month) ...[
              const SizedBox(height: 12),
              _YearSwitcher(
                year: _year,
                canGoForward: _year < DateTime.now().year,
                // Permissive while the year-mode bound is still unknown
                // (loading, or errored) or simply hasn't been fetched yet —
                // never block back-navigation on an unrelated read failing.
                canGoBack:
                    _earliestYear(yearModeAsync) == null ||
                    _year > _earliestYear(yearModeAsync)!,
                onBack: () => setState(() => _year -= 1),
                onForward: () => setState(() => _year += 1),
              ),
            ],
            const SizedBox(height: 16),
            trendAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'โหลดไม่สำเร็จ: $error',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        key: const Key('trendRetryButton'),
                        onPressed: () => ref.invalidate(trendProvider(_query)),
                        child: const Text('ลองอีกครั้ง'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (summary) => TrendBarChart(summary: summary),
            ),
          ],
        ),
      ),
    );
  }

  int? _earliestYear(AsyncValue<TrendSummary> yearModeAsync) {
    final buckets = yearModeAsync.value?.buckets;
    if (buckets == null || buckets.isEmpty) return null;
    return buckets.map((b) => b.year).reduce((a, b) => a < b ? a : b);
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.granularity, required this.onChanged});

  final TrendGranularity granularity;
  final ValueChanged<TrendGranularity> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedTabs<TrendGranularity>(
      values: const [TrendGranularity.month, TrendGranularity.year],
      labels: const ['รายเดือน', 'รายปี'],
      selected: granularity,
      onChanged: onChanged,
    );
  }
}

class _YearSwitcher extends StatelessWidget {
  const _YearSwitcher({
    required this.year,
    required this.canGoForward,
    required this.canGoBack,
    required this.onBack,
    required this.onForward,
  });

  final int year;
  final bool canGoForward;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _YearArrow(
          key: const Key('trendYearBack'),
          icon: RemixIcon.arrowLeftSLine,
          onTap: canGoBack ? onBack : null,
        ),
        const SizedBox(width: 16),
        Text(
          '${buddhistYear(year)}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(width: 16),
        _YearArrow(
          key: const Key('trendYearForward'),
          icon: RemixIcon.arrowRightSLine,
          onTap: canGoForward ? onForward : null,
        ),
      ],
    );
  }
}

class _YearArrow extends StatelessWidget {
  const _YearArrow({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.textFaint : AppColors.textSecondary,
        ),
      ),
    );
  }
}

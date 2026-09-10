import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../providers/transactions_feed_providers.dart';
import '../widgets/transaction_list_tile.dart';
import 'transaction_form_page.dart';

/// How close to the bottom (in pixels) triggers the next page fetch.
const double _kLoadMoreThreshold = 300;

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Cache paints first via monthTransactionsProvider's drift watch; this
    // kicks off the paged API sync for the currently selected month
    // (CLAUDE.md: online-only + read cache). Silent, same as
    // Accounts/CategoriesPage's initial load — the cached list is already
    // on screen either way.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final month = ref.read(selectedMonthProvider);
      _loadFirstPage(month.year, month.month, showErrorSnackBar: false);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - _kLoadMoreThreshold) return;
    final month = ref.read(selectedMonthProvider);
    ref.read(transactionsFeedSyncProvider(month.year, month.month).notifier).loadNextPage();
  }

  Future<void> _loadFirstPage(int year, int month, {bool showErrorSnackBar = true}) async {
    final result = await ref.read(transactionsFeedSyncProvider(year, month).notifier).loadFirstPage();
    if (!mounted || !showErrorSnackBar) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message ?? 'Could not refresh transactions'))),
      (_) {},
    );
  }

  void _switchMonth(void Function() mutateSelection) {
    mutateSelection();
    final month = ref.read(selectedMonthProvider);
    // A new month's data is a different list entirely — jump back to the
    // top rather than leaving the scroll offset wherever it was.
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _loadFirstPage(month.year, month.month, showErrorSnackBar: false);
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final year = month.year;
    final monthNum = month.month;

    final transactionsAsync = ref.watch(monthTransactionsProvider(year, monthNum));
    final feedMeta = ref.watch(transactionsFeedSyncProvider(year, monthNum));
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final categoriesById = {for (final category in categories) category.id: category};
    final isLoadingMore = feedMeta?.isLoadingMore ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _switchMonth(() => ref.read(selectedMonthProvider.notifier).previous()),
              ),
              Text(monthYearLabel(month), style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _switchMonth(() => ref.read(selectedMonthProvider.notifier).next()),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFirstPage(year, monthNum),
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Failed to load transactions: $error')),
          data: (transactions) {
            if (transactions.isEmpty) {
              return ListView(
                children: const [
                  Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No transactions this month'))),
                ],
              );
            }
            return ListView.builder(
              controller: _scrollController,
              itemCount: transactions.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= transactions.length) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()));
                }
                return TransactionListTile(transaction: transactions[index], categoriesById: categoriesById);
              },
            );
          },
        ),
      ),
      // T6's only reachable entry point, kept as-is.
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionFormPage())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

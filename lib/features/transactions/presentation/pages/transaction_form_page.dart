import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/cache/cache_invalidator.dart';
import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/datetime.dart';
import '../../../../shared/widgets/anchored_dropdown_panel.dart';
import '../../../../shared/widgets/category_picker_sheet.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/widgets/segmented_tabs.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_providers.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../../../slip_scan/data/slip_gallery_repository.dart';
import '../../data/pending_actions_repository.dart';
import '../../data/transactions_repository.dart';
import '../../domain/pending_action.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_validation.dart';
import '../widgets/transaction_form_fields.dart';

/// The mockup's `EditTransaction` screen — the full-edit escape hatch for
/// abnormal data (junk rows, fixing amount/account/note), per CLAUDE.md.
/// Creating a *new* transaction now lives on `AddTransactionPage` instead
/// (the mockup's separate `AddTransaction`/`Income`/`Transfer` screens with
/// their numpad + type tabs) — this page only ever edits an existing one.
class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, required this.initial});

  final Transaction initial;

  @override
  ConsumerState<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  // Ticket 13: pre-formatted the same way `AmountInputFormatter` formats
  // every keystroke, so this opens already matching Add's live-typed
  // comma-grouped style instead of only starting to match it after the
  // user's first edit.
  late final _amountController = TextEditingController(text: formatAmountForInput(widget.initial.amount));
  late final _noteController = TextEditingController(text: widget.initial.note);
  late TransactionType _type = widget.initial.type;
  late DateTime _date = widget.initial.transactionDate;
  int? _accountId;
  int? _fromAccountId;
  int? _toAccountId;
  int? _categoryId;
  bool _isSubmitting = false;
  String? _transferError;
  Future<Uint8List?>? _slipImageFuture;

  @override
  void initState() {
    super.initState();
    _accountId = widget.initial.accountId;
    _fromAccountId = widget.initial.fromAccountId;
    _toAccountId = widget.initial.toAccountId;
    _categoryId = widget.initial.categoryId;

    final imageName = widget.initial.localImageName;
    if (imageName != null && imageName.isNotEmpty) {
      _slipImageFuture = _lookupSlipImageBytes(ref.read(slipGalleryRepositoryProvider), imageName);
    }
  }

  /// Best-effort, on-device-only lookup, re-run every time this page opens —
  /// no caching/persistence of the result. A miss at either step (no
  /// matching filename, or the asset was deleted since it was scanned)
  /// resolves to `null` rather than throwing, so the slip section falls back
  /// to the placeholder silently instead of surfacing an error state.
  Future<Uint8List?> _lookupSlipImageBytes(SlipGalleryRepository repo, String filename) async {
    final candidates = await repo.queryConfiguredAlbums();
    for (final candidate in candidates) {
      if (candidate.filename == filename) return repo.readBytes(candidate.id);
    }
    return null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickCategory() async {
    final categoryType = _type == TransactionType.income ? CategoryType.income : CategoryType.expense;
    final selection = await showCategoryGridPicker(context, categoryType: categoryType, currentCategoryId: _categoryId, subtitle: 'เลือกหมวดหมู่สำหรับรายการนี้');
    if (selection == null) return;
    setState(() => _categoryId = selection.categoryId);
  }

  Future<void> _pickAccount(BuildContext anchorContext, List<Account> accounts, void Function(int id) onPicked) async {
    final result = await showAnchoredDropdown<int>(
      anchorContext: anchorContext,
      panelBuilder: (context, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final a in accounts) DropdownPanelOption(key: Key('accountOption_${a.id}'), label: a.name, onTap: () => close(a.id))],
      ),
    );
    if (result != null) onPicked(result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type == TransactionType.transfer) {
      final error = validateTransferAccounts(_fromAccountId, _toAccountId);
      if (error != null) {
        setState(() => _transferError = error);
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _transferError = null;
    });
    final repo = ref.read(transactionsRepositoryProvider);
    final amount = parseAmountInput(_amountController.text);
    final note = _noteController.text.trim();
    final isTransfer = _type == TransactionType.transfer;

    final result = await repo.update(
      widget.initial.id,
      type: _type,
      amount: amount,
      date: _date,
      note: note,
      accountId: isTransfer ? null : _accountId,
      fromAccountId: isTransfer ? _fromAccountId : null,
      toAccountId: isTransfer ? _toAccountId : null,
      categoryId: isTransfer ? null : _categoryId,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    await result.fold(
      (failure) => _handleFailure(failure, amount: amount, note: note, isTransfer: isTransfer),
      (_) async {
        _invalidateAffectedMonths();
        Navigator.of(context).pop(true);
      },
    );
  }

  /// A transient failure (network cut, timeout, etc.) gets snapshotted into
  /// `pending_manual_actions` so the user's typed data isn't lost; a
  /// permanent one stays snackbar-only, since retrying an identical payload
  /// against it can't succeed.
  Future<void> _handleFailure(Failure failure, {required double amount, required String note, required bool isTransfer}) async {
    final payload = updateTransactionPayload(
      type: _type,
      amount: amount,
      date: _date,
      note: note,
      accountId: isTransfer ? null : _accountId,
      fromAccountId: isTransfer ? _fromAccountId : null,
      toAccountId: isTransfer ? _toAccountId : null,
      categoryId: isTransfer ? null : _categoryId,
      originalDate: widget.initial.transactionDate,
    );

    final queued = await ref
        .read(pendingActionsRepositoryProvider)
        .recordIfTransient(
          failure: failure,
          actionType: PendingActionType.updateTransaction,
          payload: payload,
          targetTransactionId: widget.initial.id,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(queued ? 'ไม่มีการเชื่อมต่อ — บันทึกไว้ในคิวลองใหม่แล้ว' : (failure.message ?? 'ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง'))),
    );
  }

  /// CLAUDE.md: invalidate only the affected month's cache — both the old
  /// and new month when an edit moves the date across a month boundary.
  void _invalidateAffectedMonths() {
    ref.read(cacheInvalidatorProvider).invalidateMonths(monthsAffectedByEdit(widget.initial.transactionDate, _date));
  }

  /// Ticket 04's sole delete path for any transaction, junk or not: real
  /// delete → invalidate the transaction's month → transient failures queue
  /// into `pending_manual_actions`.
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบรายการนี้ใช่ไหม'),
        content: const Text('การลบไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('ลบ')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final transaction = widget.initial;
    final result = await ref.read(transactionsRepositoryProvider).delete(transaction.id);
    if (!context.mounted) return;

    await result.fold(
      (failure) async {
        final queued = await ref
            .read(pendingActionsRepositoryProvider)
            .recordIfTransient(
              failure: failure,
              actionType: PendingActionType.deleteTransaction,
              payload: deleteTransactionPayload(date: transaction.transactionDate),
              targetTransactionId: transaction.id,
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(queued ? 'ไม่มีการเชื่อมต่อ — บันทึกไว้ในคิวลองใหม่แล้ว' : (failure.message ?? 'ลบรายการไม่สำเร็จ'))),
        );
      },
      (_) async {
        ref.read(cacheInvalidatorProvider).invalidateMonth(transaction.transactionDate.year, transaction.transactionDate.month);
        if (context.mounted) Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(activeAccountsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final categories = categoriesAsync.value ?? const [];
    final category = _findCategory(categories, _categoryId);
    final isTransfer = _type == TransactionType.transfer;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircularIconButton(icon: RemixIcon.arrowLeftLine, onTap: () => Navigator.of(context).pop()),
                    const Text('แก้ไขรายการ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    // Ticket 04: a direct delete action (trash icon) replaces
                    // the old overflow ("...") button, which never actually
                    // opened a menu — this is the page's sole delete entry
                    // point now (the old bottom "ลบรายการ" text button is
                    // gone, avoiding two controls for the same action).
                    CircularIconButton(
                      key: const Key('deleteTransactionButton'),
                      icon: RemixIcon.deleteBinLine,
                      iconColor: AppColors.expense,
                      onTap: _isSubmitting ? null : () => _confirmDelete(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  children: [
                    SegmentedTabs<TransactionType>(
                      values: TransactionType.values,
                      labels: TransactionType.values.map((t) => t.label).toList(),
                      selected: _type,
                      onChanged: (type) => setState(() {
                        _type = type;
                        _transferError = null;
                        _categoryId = null;
                        if (type == TransactionType.transfer) {
                          _accountId = null;
                        } else {
                          _fromAccountId = null;
                          _toAccountId = null;
                        }
                      }),
                    ),
                    const SizedBox(height: 12),
                    accountsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text('โหลดบัญชีไม่สำเร็จ: $error'),
                      data: (accounts) {
                        final account = _findAccount(accounts, _accountId);
                        final from = _findAccount(accounts, _fromAccountId);
                        final to = _findAccount(accounts, _toAccountId);
                        return TransactionFormFields(
                          type: _type,
                          amountController: _amountController,
                          amountValidator: (value) {
                            // `value` now carries `AmountInputFormatter`'s
                            // thousands-commas (e.g. "1,234.50") — strip them
                            // before parsing, same as [parseAmountInput].
                            final parsed = double.tryParse((value ?? '').replaceAll(',', ''));
                            if (parsed == null) return 'กรอกตัวเลขให้ถูกต้อง';
                            if (parsed <= 0) return 'ต้องมากกว่า 0';
                            return null;
                          },
                          category: category,
                          accountName: account?.name,
                          fromAccountName: from?.name,
                          toAccountName: to?.name,
                          dateLabel: relativeDayLabel(_date),
                          onCategoryTap: _pickCategory,
                          onDateTap: (anchorContext) => _pickDate(),
                          onAccountTap: (anchorContext) => _pickAccount(anchorContext, accounts, (id) => setState(() => _accountId = id)),
                          onFromAccountTap: (anchorContext) => _pickAccount(anchorContext, accounts, (id) => setState(() {
                            _fromAccountId = id;
                            _transferError = null;
                          })),
                          onToAccountTap: (anchorContext) => _pickAccount(anchorContext, accounts, (id) => setState(() {
                            _toAccountId = id;
                            _transferError = null;
                          })),
                          transferError: _transferError,
                          noteController: _noteController,
                        );
                      },
                    ),
                    if (isTransfer) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'การย้ายเงินไม่นับเป็นรายรับหรือรายจ่าย ใช้สำหรับโอนเงินระหว่างบัญชีของคุณเอง เติมเงินกระเป๋า หรือจ่ายหนี้',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 20),
                    PrimaryGradientButton(key: const Key('submitButton'), label: 'บันทึก', onTap: _isSubmitting ? null : _submit, enabled: !_isSubmitting),
                    // Ticket 04: "ข้อมูลจากสลิป" always sits at the bottom of
                    // the form now (spec: the fields edited most often —
                    // amount, category, account — should be reachable
                    // first), previously the form's very first item.
                    const SizedBox(height: 20),
                    _SlipInfoCard(transaction: widget.initial, future: _slipImageFuture),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Account? _findAccount(List<Account> accounts, int? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Category? _findCategory(List<Category> categories, int? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// The mockup's "ข้อมูลจากสลิป" card — reuses the exact same on-device slip
/// lookup `_lookupSlipImageBytes` already performs (no new data plumbing):
/// sender/receiver/timestamp come straight off [Transaction], the thumbnail
/// from the same gallery lookup the old inline slip preview used.
class _SlipInfoCard extends StatelessWidget {
  const _SlipInfoCard({required this.transaction, required this.future});

  final Transaction transaction;
  final Future<Uint8List?>? future;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final counterparty = isIncome ? transaction.senderName : transaction.receiverName;
    return Container(
      key: const Key('slipInfoCard'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.cardLarge), boxShadow: const [AppShadows.card]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ข้อมูลจากสลิป', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                if (counterparty.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(RemixIcon.userLine, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(counterparty, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(dateTimeLabel(transaction.transactionDate), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Thumbnail(future: future),
        ],
      ),
    );
  }
}

/// Ticket 04: tapping a resolved thumbnail opens [showFullScreenImageViewer]
/// (pinch-zoom/pan + close button, presented as an overlay dialog rather than
/// a new route — see that widget's own doc comment for why closing it never
/// touches the form underneath). The placeholder (no image resolved) stays
/// inert — there's nothing to view yet — so only the real thumbnail carries
/// the "แตะเพื่อดูสลิป" tap hint.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.future});

  final Future<Uint8List?>? future;

  static const _width = 64.0;
  static const _height = 84.0;

  @override
  Widget build(BuildContext context) {
    final pendingFuture = future;
    if (pendingFuture == null) return _placeholder();
    return FutureBuilder<Uint8List?>(
      future: pendingFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done || bytes == null) return _placeholder();
        return Column(
          children: [
            InkWell(
              key: const Key('slipThumbnailTapTarget'),
              borderRadius: BorderRadius.circular(10),
              onTap: () => showFullScreenImageViewer(context, bytes),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(bytes, key: const Key('slipThumbnail'), width: _width, height: _height, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 4),
            // Bounded to the thumbnail's own width — an unconstrained Text
            // here sizes to its own intrinsic width, which under some font
            // metrics can exceed what's left in `_SlipInfoCard`'s Row and
            // overflow it (the Row's other child is `Expanded`, but this
            // Column is not, so nothing else caps it).
            const SizedBox(
              width: _width,
              child: Text(
                'แตะเพื่อดูสลิป',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      key: const Key('slipImagePlaceholder'),
      width: _width,
      height: _height,
      decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(10)),
      child: const Icon(RemixIcon.imageLine, color: Colors.white, size: 20),
    );
  }
}

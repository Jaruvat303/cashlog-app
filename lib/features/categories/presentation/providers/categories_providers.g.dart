// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(allCategories)
final allCategoriesProvider = AllCategoriesProvider._();

final class AllCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Category>>,
          List<Category>,
          Stream<List<Category>>
        >
    with $FutureModifier<List<Category>>, $StreamProvider<List<Category>> {
  AllCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allCategoriesHash();

  @$internal
  @override
  $StreamProviderElement<List<Category>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Category>> create(Ref ref) {
    return allCategories(ref);
  }
}

String _$allCategoriesHash() => r'f4e8e4024fa79c36651aff1134f24813df7a50a4';

/// Drives the pull-to-refresh / initial-load API sync. The list itself is
/// always sourced from [allCategoriesProvider]'s drift watch, so a
/// successful refresh here shows up there automatically once it upserts —
/// mirrors `AccountsRefresh`.

@ProviderFor(CategoriesRefresh)
final categoriesRefreshProvider = CategoriesRefreshProvider._();

/// Drives the pull-to-refresh / initial-load API sync. The list itself is
/// always sourced from [allCategoriesProvider]'s drift watch, so a
/// successful refresh here shows up there automatically once it upserts —
/// mirrors `AccountsRefresh`.
final class CategoriesRefreshProvider
    extends $AsyncNotifierProvider<CategoriesRefresh, void> {
  /// Drives the pull-to-refresh / initial-load API sync. The list itself is
  /// always sourced from [allCategoriesProvider]'s drift watch, so a
  /// successful refresh here shows up there automatically once it upserts —
  /// mirrors `AccountsRefresh`.
  CategoriesRefreshProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesRefreshProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesRefreshHash();

  @$internal
  @override
  CategoriesRefresh create() => CategoriesRefresh();
}

String _$categoriesRefreshHash() => r'5f4ab9f1f855451d9a432c666831425e8f3febe4';

/// Drives the pull-to-refresh / initial-load API sync. The list itself is
/// always sourced from [allCategoriesProvider]'s drift watch, so a
/// successful refresh here shows up there automatically once it upserts —
/// mirrors `AccountsRefresh`.

abstract class _$CategoriesRefresh extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

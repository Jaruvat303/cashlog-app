// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yearly_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(earliestTrendYear)
final earliestTrendYearProvider = EarliestTrendYearProvider._();

final class EarliestTrendYearProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  EarliestTrendYearProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'earliestTrendYearProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$earliestTrendYearHash();

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    return earliestTrendYear(ref);
  }
}

String _$earliestTrendYearHash() => r'b674166efe7e208d7a4e53269f3d701ad4c24f40';

@ProviderFor(yearlySummary)
final yearlySummaryProvider = YearlySummaryFamily._();

final class YearlySummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<YearlySummary>,
          YearlySummary,
          FutureOr<YearlySummary>
        >
    with $FutureModifier<YearlySummary>, $FutureProvider<YearlySummary> {
  YearlySummaryProvider._({
    required YearlySummaryFamily super.from,
    required int super.argument,
  }) : super(
         retry: _noRetry,
         name: r'yearlySummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$yearlySummaryHash();

  @override
  String toString() {
    return r'yearlySummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<YearlySummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<YearlySummary> create(Ref ref) {
    final argument = this.argument as int;
    return yearlySummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is YearlySummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$yearlySummaryHash() => r'aa83fb3fdbbeefea11bc9b9999af911ac69f98b7';

final class YearlySummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<YearlySummary>, int> {
  YearlySummaryFamily._()
    : super(
        retry: _noRetry,
        name: r'yearlySummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  YearlySummaryProvider call(int year) =>
      YearlySummaryProvider._(argument: year, from: this);

  @override
  String toString() => r'yearlySummaryProvider';
}

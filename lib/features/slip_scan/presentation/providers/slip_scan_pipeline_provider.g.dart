// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slip_scan_pipeline_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SlipScanPipeline)
final slipScanPipelineProvider = SlipScanPipelineProvider._();

final class SlipScanPipelineProvider
    extends $NotifierProvider<SlipScanPipeline, SlipScanProgress> {
  SlipScanPipelineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slipScanPipelineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slipScanPipelineHash();

  @$internal
  @override
  SlipScanPipeline create() => SlipScanPipeline();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SlipScanProgress value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SlipScanProgress>(value),
    );
  }
}

String _$slipScanPipelineHash() => r'da51f3f7ec38ea9ae5d7079271b22df5aec9ec1f';

abstract class _$SlipScanPipeline extends $Notifier<SlipScanProgress> {
  SlipScanProgress build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SlipScanProgress, SlipScanProgress>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SlipScanProgress, SlipScanProgress>,
              SlipScanProgress,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

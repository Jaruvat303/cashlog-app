import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Opens the mockup's white rounded dropdown-panel directly below the
/// tapped element (`anchorContext`) — backs the date/account/month-year
/// pickers. Call `close([value])` from inside [panelBuilder] to dismiss and
/// resolve the returned future; tapping outside the panel also dismisses it
/// with a `null` result.
Future<T?> showAnchoredDropdown<T>({
  required BuildContext anchorContext,
  required Widget Function(
    BuildContext context,
    void Function([T? value]) close,
  )
  panelBuilder,
  double? width,
  Offset offset = const Offset(0, 8),
}) {
  final overlayState = Overlay.of(anchorContext);
  final renderBox = anchorContext.findRenderObject() as RenderBox;
  final overlayBox = overlayState.context.findRenderObject() as RenderBox;
  final anchorSize = renderBox.size;
  final anchorTopLeft = renderBox.localToGlobal(
    Offset.zero,
    ancestor: overlayBox,
  );

  final completer = Completer<T?>();
  late OverlayEntry entry;

  void close([T? value]) {
    if (!completer.isCompleted) completer.complete(value);
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (context) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => close(),
            ),
          ),
          Positioned(
            left: anchorTopLeft.dx,
            top: anchorTopLeft.dy + anchorSize.height + offset.dy,
            width: width ?? anchorSize.width,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33141428),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: panelBuilder(context, close),
              ),
            ),
          ),
        ],
      );
    },
  );
  overlayState.insert(entry);
  return completer.future;
}

/// One plain-text row inside an [showAnchoredDropdown] panel.
class DropdownPanelOption extends StatelessWidget {
  const DropdownPanelOption({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.pillChipBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

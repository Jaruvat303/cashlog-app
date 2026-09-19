import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The pill segmented-control motif used for type tabs (รายรับ/รายจ่าย/
/// โอนเงิน) on Home/Summary/Add/Edit-transaction, and the income/expense tabs
/// on Categories/SelectCategory.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.trackColor = AppColors.tabTrackBg,
  }) : assert(values.length == labels.length);

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: trackColor, borderRadius: BorderRadius.circular(AppRadii.control)),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: _Segment(label: labels[i], active: values[i] == selected, onTap: () => onChanged(values[i])),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active ? AppColors.accentGradient : null,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

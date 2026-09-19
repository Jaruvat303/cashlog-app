import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The reusable "form row" pill: leading icon, label + value, trailing
/// chevron. Backs the category/date/account selectors on the transaction
/// forms.
class PillFormRow extends StatelessWidget {
  const PillFormRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.iconColor = AppColors.accentA,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.control),
            boxShadow: const [AppShadows.card],
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

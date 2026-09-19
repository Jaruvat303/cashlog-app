import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The full-width accent-gradient CTA used for save/transfer/select actions.
class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.height = 52,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadii.control + 2),
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(AppRadii.control + 2),
              boxShadow: const [AppShadows.accent],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The gradient hero-card motif repeated across the redesigned screens:
/// Home's expense summary, Accounts' net-worth banner and per-account rows,
/// AccountDetail's balance hero, and Summary's per-account mini cards.
class GradientHeroCard extends StatelessWidget {
  const GradientHeroCard({
    super.key,
    required this.child,
    this.gradient = AppColors.accentGradient,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = AppRadii.hero,
    this.showDecoration = true,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool showDecoration;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (showDecoration) ...[
              Positioned(right: -30, top: -34, child: _blurCircle(120)),
              Positioned(right: -14, bottom: -46, child: _blurCircle(90)),
            ],
            child,
          ],
        ),
      ),
    );
  }

  Widget _blurCircle(double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

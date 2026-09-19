import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The 38px white circular icon button used for back/close/more/add actions
/// in every redesigned top bar.
class CircularIconButton extends StatelessWidget {
  const CircularIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 38,
    this.background = AppColors.surface,
    this.gradient,
    this.iconColor = AppColors.textPrimary,
    this.iconSize = 18,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color background;
  final Gradient? gradient;
  final Color iconColor;
  final double iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gradient == null ? background : null,
          gradient: gradient,
          boxShadow: [gradient == null ? AppShadows.card : AppShadows.accent],
        ),
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

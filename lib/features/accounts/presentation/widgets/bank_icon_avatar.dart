import 'package:flutter/material.dart';

import '../../domain/bank_icon.dart';

class BankIconAvatar extends StatelessWidget {
  const BankIconAvatar({super.key, required this.bankIconCode, this.radius = 20});

  final String bankIconCode;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bankIcon = resolveBankIcon(bankIconCode);
    return CircleAvatar(
      radius: radius,
      backgroundColor: bankIcon.color.withValues(alpha: 0.15),
      child: Icon(bankIcon.icon, color: bankIcon.color, size: radius),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The styled-container-plus-`TextFormField` treatment
/// `TransactionFormPage`/`AddTransactionPage` (ticket 04) established for
/// their note field — `AppColors.surface` + `AppRadii.control` +
/// `AppShadows.card`, a leading icon, no visible border — pulled out as a
/// shared widget once a second form (`AccountFormPage`, ticket 05) needed
/// the exact same look, so a third (`CategoryFormPage`, ticket 06) reuses it
/// instead of re-inlining the same `Container`/`TextFormField` pairing
/// again.
class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
    required this.icon,
    required this.controller,
    required this.hintText,
    this.helperText,
    this.keyboardType,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.validator,
  });

  final IconData icon;
  final TextEditingController controller;
  final String hintText;
  final String? helperText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int? minLines;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.control),
        boxShadow: const [AppShadows.card],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(icon, size: 16, color: AppColors.accentA),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              minLines: minLines,
              maxLines: maxLines,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                helperText: helperText,
                hintStyle: const TextStyle(
                  color: AppColors.accentA,
                  fontSize: 14,
                ),
                counterText: '',
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }
}

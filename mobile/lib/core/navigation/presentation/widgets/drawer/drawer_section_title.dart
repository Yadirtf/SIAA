import 'package:flutter/material.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';

class DrawerSectionTitle extends StatelessWidget {
  final String title;

  const DrawerSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SIAASpacing.lg,
        SIAASpacing.md,
        SIAASpacing.lg,
        SIAASpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? SIAAColors.neutral500 : SIAAColors.neutral400,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';
import '../../../domain/models/nav_item.dart';

class DrawerNavItemTile extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const DrawerNavItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        isSelected ? item.iconSelected : item.icon,
        color: isSelected
            ? SIAAColors.primary500
            : (isDark ? SIAAColors.neutral400 : SIAAColors.neutral600),
        size: 22,
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? SIAAColors.primary500
              : (isDark ? SIAAColors.neutral200 : SIAAColors.neutral700),
        ),
      ),
      selected: isSelected,
      selectedTileColor: SIAAColors.primary500.withValues(alpha: 0.08),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SIAASpacing.lg,
        vertical: 2,
      ),
      minVerticalPadding: 0,
    );
  }
}

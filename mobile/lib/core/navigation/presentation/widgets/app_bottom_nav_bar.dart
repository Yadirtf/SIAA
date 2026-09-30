import 'package:flutter/material.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';
import '../../domain/models/nav_item.dart';

class AppBottomNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeIndex = currentIndex.clamp(0, items.length - 1);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? SIAAColors.surfaceDark : SIAAColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        indicatorColor: SIAAColors.primary500.withValues(alpha: 0.15),
        destinations: items
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(
                    item.iconSelected,
                    color: SIAAColors.primary500,
                  ),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

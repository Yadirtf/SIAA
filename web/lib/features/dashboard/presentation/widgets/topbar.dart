import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../models/nav_item.dart';

class DashboardTopbar extends StatelessWidget {
  final NavSection currentSection;
  final VoidCallback? onMenuPressed;

  const DashboardTopbar({
    super.key,
    required this.currentSection,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final navItem = NavItem.items.firstWhere(
      (item) => item.section == currentSection,
      orElse: () => NavItem.items.first,
    );

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: onMenuPressed,
              tooltip: 'Menú de navegación',
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  navItem.title,
                  style: AppTextStyles.h2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Gestión y configuración institucional',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          _buildUserSection(context),
        ],
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => curr is Authenticated || curr is Unauthenticated,
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;
          final primaryRole = user.roles.isNotEmpty ? user.roles.first : 'Usuario';

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusInfoBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  primaryRole.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.statusInfoText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryAccent.withOpacity(0.15),
                child: Text(
                  user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : user.correo,
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.correo,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted, size: 20),
                tooltip: 'Cerrar sesión',
                onPressed: () {
                  context.read<AuthBloc>().add(const LogoutRequestedEvent());
                },
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

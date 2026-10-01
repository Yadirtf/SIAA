import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

// ─── Banner de acción ────────────────────────────────────────────

class ParametrosAviso extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const ParametrosAviso({
    super.key,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: isError
          ? AppColors.accentRose.withValues(alpha: 0.08)
          : AppColors.accentEmerald.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 16,
            color: isError ? AppColors.accentRose : AppColors.accentEmerald,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isError ? AppColors.accentRose : AppColors.accentEmerald,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            color: AppColors.textMuted,
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}

// ─── Vista de error ──────────────────────────────────────────────

class ParametrosErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ParametrosErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune_rounded, size: 52, color: AppColors.border),
          const SizedBox(height: 16),
          const Text(
            'No se pudieron cargar los parámetros',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}

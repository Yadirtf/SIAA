import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/dispositivo_model.dart';
import 'aprobar_dispositivo_dialog.dart';
import 'revocar_dispositivo_dialog.dart';

class DispositivoCard extends StatelessWidget {
  final DispositivoModel dispositivo;
  final VoidCallback onAprobar;
  final ValueChanged<String?> onRevocar;

  const DispositivoCard({
    super.key,
    required this.dispositivo,
    required this.onAprobar,
    required this.onRevocar,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = dispositivo.so.toLowerCase().contains('ios');
    final isAndroid = dispositivo.so.toLowerCase().contains('android');
    final icon = isIos
        ? Icons.phone_iphone_rounded
        : (isAndroid
              ? Icons.phone_android_rounded
              : Icons.devices_other_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dispositivo.esPendiente
              ? AppColors.accentAmber.withOpacity(0.5)
              : AppColors.border,
          width: dispositivo.esPendiente ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dispositivo.modelo,
                      style: AppTextStyles.h3.copyWith(fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    _buildStatusChip(),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _infoSpan(Icons.system_update_alt_rounded, dispositivo.so),
                    _infoSpan(Icons.apps_rounded, 'v${dispositivo.versionApp}'),
                    _infoSpan(
                      Icons.fingerprint_rounded,
                      'ID: ${_truncate(dispositivo.instalacionId, 16)}',
                      onCopy: () =>
                          _copyToClipboard(context, dispositivo.instalacionId),
                    ),
                    if (dispositivo.creadoEn != null)
                      _infoSpan(
                        Icons.calendar_today_rounded,
                        'Registrado: ${_formatDate(dispositivo.creadoEn!)}',
                      ),
                    if (dispositivo.revocadoEn != null)
                      _infoSpan(
                        Icons.cancel_outlined,
                        'Revocado: ${_formatDate(dispositivo.revocadoEn!)}',
                        isDanger: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Color get _iconBgColor {
    if (dispositivo.esRevocado) return AppColors.statusDangerBg;
    if (dispositivo.esPendiente) return AppColors.statusWarningBg;
    return AppColors.statusSuccessBg;
  }

  Color get _iconColor {
    if (dispositivo.esRevocado) return AppColors.statusDangerText;
    if (dispositivo.esPendiente) return AppColors.statusWarningText;
    return AppColors.statusSuccessText;
  }

  Widget _buildStatusChip() {
    Color bg = AppColors.statusSuccessBg;
    Color fg = AppColors.statusSuccessText;
    if (dispositivo.esPendiente) {
      bg = AppColors.statusWarningBg;
      fg = AppColors.statusWarningText;
    } else if (dispositivo.esRevocado) {
      bg = AppColors.statusDangerBg;
      fg = AppColors.statusDangerText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dispositivo.estadoTexto.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _infoSpan(
    IconData icon,
    String text, {
    VoidCallback? onCopy,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDanger ? AppColors.accentRose : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDanger ? AppColors.accentRose : AppColors.textSecondary,
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.copy_rounded,
              size: 12,
              color: AppColors.textMuted,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (dispositivo.esRevocado) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dispositivo.esPendiente) ...[
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentEmerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Aprobar'),
            onPressed: () => AprobarDispositivoDialog.show(
              context,
              dispositivo: dispositivo,
              onAprobar: onAprobar,
            ),
          ),
          const SizedBox(width: 8),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentRose,
            side: const BorderSide(color: AppColors.accentRose),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.block_rounded, size: 16),
          label: const Text('Revocar'),
          onPressed: () => RevocarDispositivoDialog.show(
            context,
            dispositivo: dispositivo,
            onRevocar: onRevocar,
          ),
        ),
      ],
    );
  }

  String _truncate(String str, int maxLen) {
    if (str.length <= maxLen) return str;
    return '${str.substring(0, maxLen)}...';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID de instalación copiado al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

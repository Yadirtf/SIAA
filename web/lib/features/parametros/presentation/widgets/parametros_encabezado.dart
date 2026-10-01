import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

const _niveles = ['Global', 'Sede', 'Facultad', 'Bloque', 'Aula', 'Asignación'];

/// Título de la pantalla, la cascada de niveles y el acceso a la guía.
class ParametrosEncabezado extends StatelessWidget {
  const ParametrosEncabezado({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primaryAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parametrización Jerárquica', style: AppTextStyles.h2),
                    Text(
                      'Reglas de marcaje: horarios de entrada y salida, '
                      'tardanza, precisión del GPS y seguridad del celular.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const GuiaCascadaDialog(),
                ),
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: const Text('¿Cómo funciona?'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 4,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Del más general al más específico: ',
                style: AppTextStyles.bodySmall,
              ),
              for (var i = 0; i < _niveles.length; i++) ...[
                _Nivel(_niveles[i], i),
                if (i < _niveles.length - 1)
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Nivel extends StatelessWidget {
  final String nombre;
  final int orden;

  const _Nivel(this.nombre, this.orden);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: orden == 0
          ? AppColors.surfaceMuted
          : AppColors.primaryAccent.withValues(alpha: 0.06 + orden * 0.04),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      nombre,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: orden == 0 ? AppColors.textMuted : AppColors.primaryAccent,
      ),
    ),
  );
}

/// Explica la herencia entre niveles y cuándo surte efecto un cambio.
class GuiaCascadaDialog extends StatelessWidget {
  const GuiaCascadaDialog({super.key});

  static const _pasos = [
    (
      Icons.public_rounded,
      'Global es la regla de toda la institución',
      'Todos los parámetros tienen un valor Global. Si no se cambia nada '
          'más, ese valor rige en todas las sedes y aulas.',
    ),
    (
      Icons.account_tree_outlined,
      'Los niveles específicos reemplazan al general',
      'Elija un ámbito (por ejemplo una Sede o un Aula) y cambie un valor: '
          'ese valor rige solo ahí y en lo que está debajo. El orden es '
          'Global, Sede, Facultad, Bloque, Aula y Asignación; gana el más '
          'específico.',
    ),
    (
      Icons.label_outline_rounded,
      'Cada fila dice de dónde viene su valor',
      '"Definido aquí" significa que el ámbito elegido tiene su propio '
          'valor. "Heredado de Global" (u otro nivel) significa que viene de '
          'un nivel superior; al editarlo se crea un valor propio para este '
          'ámbito.',
    ),
    (
      Icons.event_repeat_rounded,
      'Cuándo surte efecto un cambio',
      'Los ajustes de marcaje (horarios, tardanza, GPS y seguridad) quedan '
          'fijos en cada clase cuando se generan sus sesiones: un cambio '
          'aplica a las sesiones que se generen después. La retención de '
          'coordenadas aplica de inmediato.',
    ),
    (
      Icons.info_outline_rounded,
      'Ayuda por parámetro',
      'Use el icono de información de cada fila para ver qué controla, el '
          'rango permitido y una recomendación.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cómo funciona la parametrización', style: AppTextStyles.h3),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (icono, titulo, texto) in _pasos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icono, size: 20, color: AppColors.primaryAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(texto, style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}

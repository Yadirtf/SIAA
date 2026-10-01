import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/hora_12h.dart';
import '../../domain/models/parametro_model.dart';

/// Ventanas de marcaje calculadas para una clase de ejemplo (7:00 a 9:00 a. m.)
/// con los valores que rigen en el ámbito elegido.
class VentanasEjemplo {
  static const inicio = 7 * 60;
  static const fin = 9 * 60;

  final int entradaAntes;
  final int entradaDespues;
  final int tardanza;
  final String salida;
  final int salidaAntes;
  final int salidaDespues;

  const VentanasEjemplo({
    required this.entradaAntes,
    required this.entradaDespues,
    required this.tardanza,
    required this.salida,
    required this.salidaAntes,
    required this.salidaDespues,
  });

  factory VentanasEjemplo.desde(List<ParametroEfectivoModel> params) {
    Object? valor(String clave) {
      for (final p in params) {
        if (p.clave == clave) return p.valor;
      }
      return null;
    }

    int entero(String clave, int defecto) =>
        (valor(clave) as num?)?.toInt() ?? defecto;
    return VentanasEjemplo(
      entradaAntes: entero('holgura_entrada_antes_min', 15),
      entradaDespues: entero('holgura_entrada_despues_min', 15),
      tardanza: entero('umbral_tardanza_min', 10),
      salida: valor('salida_obligatoria')?.toString() ?? 'DESACTIVADO',
      salidaAntes: entero('holgura_salida_antes_min', 10),
      salidaDespues: entero('holgura_salida_despues_min', 20),
    );
  }

  bool get conSalida => salida == 'OPCIONAL' || salida == 'OBLIGATORIO';

  /// La tardanza nunca se alcanza si la entrada cierra antes del umbral.
  bool get tardanzaInalcanzable => tardanza >= entradaDespues;

  int get desde => inicio - entradaAntes - 10;
  int get hasta => (conSalida ? fin + salidaDespues : fin) + 10;

  static String hora(int minutos) => hora12h(minutos ~/ 60 % 24, minutos % 60);

  List<String> get descripcion => [
    'Entrada: de ${hora(inicio - entradaAntes)} a ${hora(inicio + entradaDespues)}',
    tardanzaInalcanzable
        ? 'Cualquier entrada aceptada cuenta como Presente: el umbral de '
              'tardanza ($tardanza min) no es menor que el cierre '
              '($entradaDespues min).'
        : 'Presente hasta ${hora(inicio + tardanza)}; desde ahí y hasta '
              '${hora(inicio + entradaDespues)} cuenta como Tardanza.',
    conSalida
        ? 'Salida: de ${hora(fin - salidaAntes)} a ${hora(fin + salidaDespues)}'
        : 'Sin marcaje de salida.',
  ];
}

class LineaTiempoClase extends StatelessWidget {
  final VentanasEjemplo v;

  const LineaTiempoClase({super.key, required this.v});

  Widget _franja(
    double ancho,
    int a,
    int b,
    Color color, {
    double top = 18,
    double alto = 14,
  }) {
    final total = (v.hasta - v.desde).toDouble();
    final izq = (a - v.desde) / total * ancho;
    final der = (b - v.desde) / total * ancho;
    return Positioned(
      left: izq,
      width: (der - izq).clamp(2, ancho),
      top: top,
      height: alto,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _leyenda(Color color, String texto) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(texto, style: AppTextStyles.bodySmall),
    ],
  );

  @override
  Widget build(BuildContext context) {
    const clase = AppColors.border;
    const entrada = AppColors.accentEmerald;
    const tarde = AppColors.accentAmber;
    const salida = AppColors.accentCyan;
    final inicio = VentanasEjemplo.inicio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return SizedBox(
              height: 50,
              child: Stack(
                children: [
                  _franja(
                    w,
                    inicio,
                    VentanasEjemplo.fin,
                    clase,
                    top: 14,
                    alto: 22,
                  ),
                  _franja(
                    w,
                    inicio - v.entradaAntes,
                    inicio + v.entradaDespues,
                    entrada,
                  ),
                  if (!v.tardanzaInalcanzable)
                    _franja(
                      w,
                      inicio + v.tardanza,
                      inicio + v.entradaDespues,
                      tarde,
                    ),
                  if (v.conSalida)
                    _franja(
                      w,
                      VentanasEjemplo.fin - v.salidaAntes,
                      VentanasEjemplo.fin + v.salidaDespues,
                      salida,
                    ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Text(
                      VentanasEjemplo.hora(v.desde),
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Text(
                      VentanasEjemplo.hora(v.hasta),
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _leyenda(clase, 'Clase 7:00 a. m. - 9:00 a. m.'),
            _leyenda(entrada, 'Puede marcar entrada'),
            _leyenda(tarde, 'Tardanza'),
            if (v.conSalida) _leyenda(salida, 'Puede marcar salida'),
          ],
        ),
        const SizedBox(height: 8),
        for (final linea in v.descripcion)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('• $linea', style: AppTextStyles.bodyMedium),
          ),
      ],
    );
  }
}

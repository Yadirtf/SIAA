import 'package:flutter/material.dart';

import '../../data/models/academico_models.dart';
import '../helpers/filtro_sesiones.dart';

/// Filtros de la tabla de sesiones: periodo, sede, bloque, aula, docente,
/// estado y búsqueda libre. El periodo se consulta al servidor; el resto se
/// aplica sobre las sesiones ya cargadas.
class FiltrosSesionesBar extends StatelessWidget {
  final List<PeriodoModel> periodos;
  final String? periodoId;
  final ValueChanged<String?> onPeriodo;
  final FiltroSesiones filtro;
  final OpcionesSesiones opciones;
  final ValueChanged<FiltroSesiones> onCambio;

  const FiltrosSesionesBar({
    super.key,
    required this.periodos,
    required this.periodoId,
    required this.onPeriodo,
    required this.filtro,
    required this.opciones,
    required this.onCambio,
  });

  Widget _lista(
    String etiqueta,
    IconData icono,
    String? valor,
    Map<String, String> opciones,
    ValueChanged<String?> onChanged, {
    double ancho = 200,
  }) {
    // Si la opción elegida ya no existe en el rango, se muestra "Todos".
    final actual = opciones.containsKey(valor) ? valor : null;
    return SizedBox(
      width: ancho,
      child: DropdownButtonFormField<String?>(
        key: ValueKey('$etiqueta-$actual-${opciones.length}'),
        initialValue: actual,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: Icon(icono),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todos')),
          for (final e in opciones.entries)
            DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = filtro;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _lista(
          'Periodo',
          Icons.calendar_month_outlined,
          periodoId,
          {for (final p in periodos) p.id: '${p.codigo} - ${p.nombre}'},
          onPeriodo,
          ancho: 240,
        ),
        _lista(
          'Sede',
          Icons.location_city_outlined,
          f.sedeId,
          opciones.sedes,
          (v) => onCambio(
            f.copiar(
              sedeId: () => v,
              bloqueId: () => null,
              espacioId: () => null,
            ),
          ),
        ),
        _lista(
          'Bloque',
          Icons.domain_outlined,
          f.bloqueId,
          opciones.bloques,
          (v) => onCambio(f.copiar(bloqueId: () => v, espacioId: () => null)),
        ),
        _lista(
          'Aula',
          Icons.meeting_room_outlined,
          f.espacioId,
          opciones.aulas,
          (v) => onCambio(f.copiar(espacioId: () => v)),
          ancho: 220,
        ),
        _lista(
          'Docente',
          Icons.person_outline_rounded,
          f.docenteId,
          opciones.docentes,
          (v) => onCambio(f.copiar(docenteId: () => v)),
          ancho: 220,
        ),
        _lista(
          'Estado',
          Icons.flag_outlined,
          f.estado,
          estadosSesion,
          (v) => onCambio(f.copiar(estado: () => v)),
          ancho: 180,
        ),
        SizedBox(
          width: 300,
          child: TextFormField(
            initialValue: f.texto,
            decoration: const InputDecoration(
              labelText: 'Buscar asignatura, grupo, docente o aula',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
            onChanged: (v) => onCambio(filtro.copiar(texto: v)),
          ),
        ),
        if (f.activo)
          TextButton.icon(
            onPressed: () => onCambio(const FiltroSesiones()),
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Limpiar filtros'),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/edicion_remote_datasource.dart';
import '../../../../core/widgets/formulario_edicion_dialog.dart';
import '../../data/models/geo_models.dart';
import '../bloc/geo_bloc.dart';
import '../bloc/geo_event.dart';
import '../bloc/geo_state.dart';

/// Formularios de edición de sedes, bloques y espacios (US-GEO-01): corregir
/// códigos, nombres y datos básicos sin recrear el registro.

CampoEdicion _codigo(String v) => CampoEdicion(
  clave: 'codigo',
  etiqueta: 'Código',
  valor: v,
  icono: Icons.code_rounded,
);

CampoEdicion _nombre(String v) => CampoEdicion(
  clave: 'nombre',
  etiqueta: 'Nombre',
  valor: v,
  icono: Icons.edit_note_rounded,
);

/// Recarga la vista de geo conservando la sede y el bloque elegidos.
void _recargar(GeoBloc bloc) {
  final s = bloc.state;
  bloc.add(
    s is GeoLoaded
        ? LoadGeoDataEvent(
            sedeId: s.selectedSedeId,
            bloqueId: s.selectedBloqueId,
          )
        : const LoadGeoDataEvent(),
  );
}

Future<void> editarSede(BuildContext context, SedeModel sede) async {
  final ds = context.read<EdicionRemoteDataSource>();
  final bloc = context.read<GeoBloc>();
  final ok = await editarConFormulario(
    context,
    titulo: 'Editar sede',
    campos: [
      _codigo(sede.codigo),
      _nombre(sede.nombre),
      CampoEdicion(
        clave: 'direccion',
        etiqueta: 'Dirección',
        valor: sede.direccion ?? '',
        requerido: false,
        icono: Icons.place_outlined,
      ),
    ],
    guardar: (v) => ds.actualizar('${ApiConstants.sedes}/${sede.id}', v),
  );
  if (ok) _recargar(bloc);
}

Future<void> editarBloque(BuildContext context, BloqueModel bloque) async {
  final ds = context.read<EdicionRemoteDataSource>();
  final bloc = context.read<GeoBloc>();
  final ok = await editarConFormulario(
    context,
    titulo: 'Editar bloque',
    nota:
        'Puede agregar pisos nuevos. Los pisos actuales '
        '(${bloque.pisos.join(', ')}) se conservan porque puede haber aulas en ellos.',
    campos: [
      _codigo(bloque.codigo),
      _nombre(bloque.nombre),
      const CampoEdicion(
        clave: 'pisosNuevos',
        etiqueta: 'Pisos a agregar (ej: 4, 5)',
        valor: '',
        requerido: false,
        icono: Icons.layers_outlined,
      ),
    ],
    guardar: (v) => ds.actualizar('${ApiConstants.bloques}/${bloque.id}', {
      'codigo': v['codigo'],
      'nombre': v['nombre'],
      'pisos': parsearPisos(v['pisosNuevos'] ?? ''),
    }),
  );
  if (ok) _recargar(bloc);
}

/// "4, 5 6" → [4, 5, 6]; ignora lo que no es número.
List<int> parsearPisos(String texto) => texto
    .split(RegExp(r'[,\s;]+'))
    .map((p) => int.tryParse(p.trim()))
    .whereType<int>()
    .toList();

Future<void> editarEspacio(BuildContext context, EspacioModel e) async {
  final ds = context.read<EdicionRemoteDataSource>();
  final bloc = context.read<GeoBloc>();
  Map<String, dynamic>? actualizado;
  await editarConFormulario(
    context,
    titulo: 'Editar espacio',
    campos: [
      _codigo(e.codigo),
      _nombre(e.nombre),
      CampoEdicion(
        clave: 'capacidad',
        etiqueta: 'Capacidad (estudiantes)',
        valor: '${e.capacidad}',
        tipo: TipoCampo.entero,
        icono: Icons.event_seat_outlined,
      ),
      CampoEdicion(
        clave: 'tipo',
        etiqueta: 'Tipo',
        valor: e.tipo,
        tipo: TipoCampo.opciones,
        icono: Icons.category_outlined,
        opciones: const {
          'AULA': 'Aula',
          'LABORATORIO': 'Laboratorio',
          'AUDITORIO': 'Auditorio',
          'TALLER': 'Taller',
        },
      ),
    ],
    guardar: (v) async {
      actualizado = await ds.actualizar('${ApiConstants.espacios}/${e.id}', {
        'codigo': v['codigo'],
        'nombre': v['nombre'],
        'capacidad': int.parse(v['capacidad']!),
        'tipo': v['tipo'],
      }, parcial: true);
    },
  );
  final json = actualizado;
  if (json != null && json['id'] != null) {
    bloc.add(EspacioActualizadoEvent(EspacioModel.fromJson(json)));
  } else if (json != null) {
    _recargar(bloc);
  }
}

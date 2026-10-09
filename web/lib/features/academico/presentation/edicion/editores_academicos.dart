import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/edicion_remote_datasource.dart';
import '../../../../core/widgets/formulario_edicion_dialog.dart';
import '../../data/models/academico_models.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../dialogs/periodo_dialog.dart';

/// Formularios de edición de la estructura académica (US-ACA-01 AC-04). Cada
/// uno abre los datos actuales, guarda con PUT y recarga las listas.

Future<void> _editar(
  BuildContext context, {
  required String titulo,
  required String url,
  required List<CampoEdicion> campos,
  required Map<String, dynamic> Function(Map<String, String> v) cuerpo,
  String? nota,
  bool confirmaSolapamiento = false,
}) async {
  final ds = context.read<EdicionRemoteDataSource>();
  final bloc = context.read<AcademicoBloc>();
  final ok = await editarConFormulario(
    context,
    titulo: titulo,
    campos: campos,
    nota: nota,
    guardar: (v) => confirmaSolapamiento
        ? guardarPeriodoConfirmando(
            context,
            (confirmar) => ds.actualizar(url, {
              ...cuerpo(v),
              if (confirmar) 'confirmarSolapamiento': true,
            }),
          )
        : ds.actualizar(url, cuerpo(v)),
  );
  if (ok) bloc.add(const LoadAcademicoDataEvent());
}

CampoEdicion _codigo(String valor) => CampoEdicion(
  clave: 'codigo',
  etiqueta: 'Código',
  valor: valor,
  icono: Icons.code_rounded,
);

CampoEdicion _nombre(String valor) => CampoEdicion(
  clave: 'nombre',
  etiqueta: 'Nombre',
  valor: valor,
  icono: Icons.edit_note_rounded,
);

Future<void> editarFacultad(BuildContext context, FacultadModel f) => _editar(
  context,
  titulo: 'Editar facultad',
  url: '${ApiConstants.facultades}/${f.id}',
  campos: [_codigo(f.codigo), _nombre(f.nombre)],
  cuerpo: (v) => {'codigo': v['codigo'], 'nombre': v['nombre']},
);

Future<void> editarPrograma(BuildContext context, ProgramaModel p) => _editar(
  context,
  titulo: 'Editar programa',
  url: '${ApiConstants.programas}/${p.id}',
  campos: [_codigo(p.codigo), _nombre(p.nombre)],
  cuerpo: (v) => {'codigo': v['codigo'], 'nombre': v['nombre']},
);

Future<void> editarAsignatura(BuildContext context, AsignaturaModel a) =>
    _editar(
      context,
      titulo: 'Editar asignatura',
      url: '${ApiConstants.asignaturas}/${a.id}',
      campos: [
        _codigo(a.codigo),
        _nombre(a.nombre),
        CampoEdicion(
          clave: 'creditos',
          etiqueta: 'Créditos',
          valor: '${a.creditos}',
          tipo: TipoCampo.entero,
          icono: Icons.star_outline_rounded,
        ),
      ],
      cuerpo: (v) => {
        'codigo': v['codigo'],
        'nombre': v['nombre'],
        'creditos': int.parse(v['creditos']!),
      },
    );

Future<void> editarGrupo(BuildContext context, GrupoModel g) => _editar(
  context,
  titulo: 'Editar grupo',
  url: '${ApiConstants.grupos}/${g.id}',
  campos: [
    CampoEdicion(
      clave: 'numero',
      etiqueta: 'Número del grupo',
      valor: g.numero,
      icono: Icons.tag_rounded,
    ),
    CampoEdicion(
      clave: 'cupo',
      etiqueta: 'Cupo',
      valor: '${g.cupo}',
      tipo: TipoCampo.entero,
      icono: Icons.people_outline_rounded,
    ),
  ],
  cuerpo: (v) => {'numero': v['numero'], 'cupo': int.parse(v['cupo']!)},
);

Future<void> editarPeriodo(BuildContext context, PeriodoModel p) => _editar(
  context,
  titulo: 'Editar periodo académico',
  url: '${ApiConstants.periodos}/${p.id}',
  nota:
      'Si amplía las fechas, pulse "Generar sesiones" después para crear las '
      'clases de los días nuevos. Un periodo cerrado ya no se puede modificar.',
  confirmaSolapamiento: true,
  campos: [
    _codigo(p.codigo),
    _nombre(p.nombre),
    CampoEdicion(
      clave: 'fechaInicio',
      etiqueta: 'Fecha de inicio',
      valor: _fecha(p.fechaInicio),
      tipo: TipoCampo.fecha,
    ),
    CampoEdicion(
      clave: 'fechaFin',
      etiqueta: 'Fecha de fin',
      valor: _fecha(p.fechaFin),
      tipo: TipoCampo.fecha,
    ),
    CampoEdicion(
      clave: 'estado',
      etiqueta: 'Estado',
      valor: p.estado,
      tipo: TipoCampo.opciones,
      icono: Icons.flag_outlined,
      opciones: estadosPeriodo,
    ),
  ],
  cuerpo: (v) => {
    'codigo': v['codigo'],
    'nombre': v['nombre'],
    'fechaInicio': v['fechaInicio'],
    'fechaFin': v['fechaFin'],
    'estado': v['estado'],
    if (p.sedeId != null) 'sedeId': p.sedeId,
  },
);

String _fecha(String f) => f.length >= 10 ? f.substring(0, 10) : f;

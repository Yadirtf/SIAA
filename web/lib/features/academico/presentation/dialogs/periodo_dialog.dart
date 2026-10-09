import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/confirmacion_requerida.dart';
import '../../../../core/widgets/advertencias_dialog.dart';
import '../../../../core/widgets/confirmar_operacion.dart';
import '../../../../core/widgets/formulario_edicion_dialog.dart';
import '../../data/models/academico_models.dart';
import '../../domain/academico_repository.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';

/// Estados que puede tener un periodo académico, con su etiqueta.
const estadosPeriodo = {
  'PLANEACION': 'Planeación',
  'ACTIVO': 'Activo',
  'CERRADO': 'Cerrado',
};

/// Guarda un periodo y, si el servidor avisa que se cruza con otro periodo
/// activo de la sede (409 CONFIRMACION_REQUERIDA, US-ACA-01 AC-03), pregunta
/// y lo reenvía con `confirmarSolapamiento`. Si el usuario no confirma, lanza
/// [OperacionCancelada] para que el formulario siga abierto sin error.
Future<void> guardarPeriodoConfirmando<T>(
  BuildContext context,
  Future<T> Function(bool confirmarSolapamiento) guardar,
) async {
  final ok = await ejecutarConConfirmacion(
    context,
    guardar,
    titulo: 'El periodo se cruza con otro activo',
    textoConfirmar: 'Activarlo de todos modos',
  );
  if (!ok) throw const OperacionCancelada();
}

/// Formulario de un periodo nuevo (US-ACA-01). Al guardar recarga la
/// estructura académica y muestra las advertencias del servidor, si las hay.
Future<void> crearPeriodo(BuildContext context) async {
  final repo = context.read<AcademicoRepository>();
  final bloc = context.read<AcademicoBloc>();
  PeriodoModel? creado;
  final ok = await editarConFormulario(
    context,
    titulo: 'Nuevo periodo académico',
    campos: const [
      CampoEdicion(
        clave: 'codigo',
        etiqueta: 'Código (ej: 2026-1)',
        valor: '',
        icono: Icons.code_rounded,
      ),
      CampoEdicion(
        clave: 'nombre',
        etiqueta: 'Nombre',
        valor: '',
        icono: Icons.edit_note_rounded,
      ),
      CampoEdicion(
        clave: 'fechaInicio',
        etiqueta: 'Fecha de inicio',
        valor: '',
        tipo: TipoCampo.fecha,
      ),
      CampoEdicion(
        clave: 'fechaFin',
        etiqueta: 'Fecha de fin',
        valor: '',
        tipo: TipoCampo.fecha,
      ),
      CampoEdicion(
        clave: 'estado',
        etiqueta: 'Estado inicial',
        valor: 'PLANEACION',
        tipo: TipoCampo.opciones,
        icono: Icons.flag_outlined,
        opciones: estadosPeriodo,
      ),
    ],
    guardar: (v) => guardarPeriodoConfirmando(
      context,
      (confirmar) async => creado = await repo.createPeriodo(
        codigo: v['codigo']!,
        nombre: v['nombre']!,
        fechaInicio: v['fechaInicio']!,
        fechaFin: v['fechaFin']!,
        estado: v['estado']!,
        confirmarSolapamiento: confirmar,
      ),
    ),
  );
  if (!ok) return;
  bloc.add(const LoadAcademicoDataEvent());
  if (context.mounted) {
    await mostrarAdvertencias(
      context,
      titulo: 'Periodo creado con advertencias',
      advertencias: creado?.advertencias ?? const [],
    );
  }
}

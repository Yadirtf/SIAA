import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../dashboard/presentation/models/nav_item.dart';
import '../../domain/reportes_operativos_repository.dart';
import '../bloc/asistencia_grupo_cubit.dart';
import '../bloc/ocupacion_cubit.dart';
import '../bloc/tablero_cubit.dart';
import 'asistencia_estudiantil_screen.dart';
import 'ocupacion_screen.dart';
import 'tablero_screen.dart';

/// Pantalla de un reporte operativo con su cubit propio: se crea al entrar en
/// la sección y se cierra al salir (el tablero deja de actualizarse).
Widget pantallaReporteOperativo(NavSection seccion, List<String> permisos) {
  switch (seccion) {
    case NavSection.tablero:
      return BlocProvider(
        key: const ValueKey('tablero'),
        create: (ctx) =>
            TableroCubit(repository: ctx.read<ReportesOperativosRepository>())
              ..iniciar(),
        child: const TableroScreen(),
      );
    case NavSection.ocupacion:
      return BlocProvider(
        key: const ValueKey('ocupacion'),
        create: (ctx) => OcupacionCubit(
          repository: ctx.read<ReportesOperativosRepository>(),
        ),
        child: OcupacionScreen(
          puedeExportar: permisos.contains('reporte:exportar'),
        ),
      );
    default:
      return BlocProvider(
        key: const ValueKey('asistencia-estudiantil'),
        create: (ctx) => AsistenciaGrupoCubit(
          repository: ctx.read<ReportesOperativosRepository>(),
        ),
        child: const AsistenciaEstudiantilScreen(),
      );
  }
}

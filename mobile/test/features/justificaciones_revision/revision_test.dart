// revision_test.dart — Bandeja y decisión de justificaciones (RF-JUS-002)
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/catalogo_justificacion.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/justificacion_model.dart';
import 'package:siaa_mobile/features/justificaciones_revision/data/resolutor_nombres.dart';
import 'package:siaa_mobile/features/justificaciones_revision/data/revision_remote_datasource.dart';
import 'package:siaa_mobile/features/justificaciones_revision/presentation/cubit/revision_detalle_cubit.dart';
import 'package:siaa_mobile/features/justificaciones_revision/presentation/cubit/revision_lista_cubit.dart';
import 'package:siaa_mobile/features/justificaciones_revision/presentation/screens/revision_justificaciones_screen.dart';

Justificacion _j(String estado) => Justificacion.fromJson({
      'id': 'j-1',
      'sesionId': 's-1',
      'docenteId': 'doc-1',
      'tipo': 'INCAPACIDAD',
      'descripcion': 'Incapacidad médica de 2 días',
      'estado': estado,
      'fechaSesion': '2026-09-28',
      'nombreSesion': 'Cálculo I - Grupo 01',
      'adjuntos': [
        {
          'id': 'a-1',
          'nombre': 'soporte.pdf',
          'mime': 'application/pdf',
          'tamano': 2048
        },
      ],
      'historial': [
        {
          'estado': 'RADICADA',
          'actorId': 'doc-1',
          'en': '2026-09-28T15:00:00Z'
        },
      ],
    });

class _RemoteFake extends RevisionRemoteDataSource {
  String estadoActual = 'RADICADA';
  final List<String?> filtros = [];
  final List<(String, String?)> revisiones = [];
  bool sinPermisoUsuarios = false;
  _RemoteFake() : super(dio: Dio());

  @override
  Future<PaginaJustificaciones> listar({String? estado, int pagina = 1}) async {
    filtros.add(estado);
    return PaginaJustificaciones(items: [_j(estadoActual)], total: 1);
  }

  @override
  Future<Justificacion> obtener(String id) async => _j(estadoActual);

  @override
  Future<Justificacion> revisar(String id,
      {required String estado, String? observaciones}) async {
    revisiones.add((estado, observaciones));
    estadoActual = estado;
    return _j(estado);
  }

  @override
  Future<Uint8List> descargarSoporte(String id, String soporteId) async =>
      Uint8List(0);

  @override
  Future<String> nombreUsuario(String id) async {
    if (sinPermisoUsuarios) {
      throw DioException(requestOptions: RequestOptions());
    }
    return id == 'doc-1' ? 'Ana Gómez' : 'Coordinador Uno';
  }
}

void main() {
  test('la bandeja inicia en RADICADA y resuelve el nombre del docente',
      () async {
    final remote = _RemoteFake();
    final cubit = RevisionListaCubit(remote: remote);
    await cubit.cargar();
    expect(remote.filtros.single, 'RADICADA');
    expect(cubit.state.nombreDocente('doc-1'), 'Ana Gómez');
    await cubit.cambiarFiltro(null);
    expect(remote.filtros.last, isNull);
    await cubit.close();
  });

  test('sin usuario:leer muestra "Docente", nunca el id', () async {
    final remote = _RemoteFake()..sinPermisoUsuarios = true;
    final cubit = RevisionListaCubit(remote: remote);
    await cubit.cargar();
    expect(cubit.state.nombreDocente('doc-1'), 'Docente');
    await cubit.close();
  });

  test('tomar, rechazar (con observaciones) y estados cerrados', () async {
    final remote = _RemoteFake();
    final cubit =
        RevisionDetalleCubit(remote, ResolutorNombres(remote), _j('RADICADA'));
    expect(cubit.state.puedeTomar, isTrue);
    expect(await cubit.tomarEnRevision(), isNull);
    expect(remote.revisiones.last.$1, 'EN_REVISION');
    expect(await cubit.rechazar('corto'), contains('al menos 10'));
    expect(remote.revisiones.length, 1);
    expect(await cubit.rechazar('Soporte ilegible, adjunte otro'), isNull);
    expect(remote.revisiones.last,
        ('RECHAZADA', 'Soporte ilegible, adjunte otro'));
    expect(cubit.state.puedeDecidir, isFalse);
    expect(
        cubit.state.justificacion.estado, EstadoJustificacion.rechazada.codigo);
    await cubit.close();
  });

  testWidgets(
      'la pantalla muestra docente y sesión por nombre y abre el detalle',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RevisionJustificacionesScreen(remote: _RemoteFake()))));
    await tester.pumpAndSettle();
    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.textContaining('Cálculo I - Grupo 01'), findsOneWidget);
    await tester.tap(find.text('Ana Gómez'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar justificación'), findsOneWidget);
    expect(find.text('Aprobar'), findsOneWidget);
    expect(find.text('Tomar en revisión'), findsOneWidget);
    expect(find.text('soporte.pdf'), findsOneWidget);
  });
}

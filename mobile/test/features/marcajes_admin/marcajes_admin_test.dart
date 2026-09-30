// marcajes_admin_test.dart — Consulta administrativa de marcajes y ajustes (US-MAR-09)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_historial_model.dart';
import 'package:siaa_mobile/features/marcajes_admin/data/marcajes_admin_remote_datasource.dart';
import 'package:siaa_mobile/features/marcajes_admin/domain/filtro_marcajes.dart';
import 'package:siaa_mobile/features/marcajes_admin/presentation/cubit/marcajes_admin_cubit.dart';
import 'package:siaa_mobile/features/marcajes_admin/presentation/cubit/marcajes_admin_state.dart';
import 'package:siaa_mobile/features/marcajes_admin/presentation/screens/marcajes_admin_screen.dart';

import '../../helpers/auth_sesion.dart';
import '../marcaje/domain/historial_nombres_test.dart' show itemBackend;

class _RemoteFake extends MarcajesAdminRemoteDataSource {
  final List<FiltroMarcajes> consultas = [];
  final List<(String, Map<String, dynamic>)> ajustes = [];
  Object? error;
  _RemoteFake() : super(dio: Dio());

  @override
  Future<HistorialPaginadoModel> listar(FiltroMarcajes filtro) async {
    consultas.add(filtro);
    if (error != null) throw error!;
    return HistorialPaginadoModel.fromJson({
      'items': [itemBackend],
      'total': 1,
      'pagina': filtro.pagina,
      'limite': 20,
      'totalPaginas': 1,
    });
  }

  @override
  Future<void> ajustar(String marcajeId, AjusteMarcaje ajuste) async {
    ajustes.add((marcajeId, ajuste.toJson()));
  }
}

void main() {
  test('FiltroMarcajes arma la consulta con fechas RFC 3339', () {
    final q = FiltroMarcajes(
      resultado: 'AUSENTE',
      desde: DateTime(2026, 9, 1),
      hasta: DateTime(2026, 9, 30),
    ).toQuery();
    expect(q['resultado'], 'AUSENTE');
    expect(q['pagina'], 1);
    expect(q['limite'], 20);
    expect(
        DateTime.parse(q['desde'] as String).toLocal(), DateTime(2026, 9, 1));
    expect(DateTime.parse(q['hasta'] as String).toLocal(),
        DateTime(2026, 9, 30, 23, 59, 59));
  });

  test('AjusteMarcaje produce el cuerpo de PATCH /marcajes/:id', () {
    expect(const AjusteMarcaje.anular(' motivo ').toJson(),
        {'accion': 'ANULAR', 'anulado': true, 'motivo': 'motivo'});
    expect(const AjusteMarcaje.corregir('PRESENTE', 'x').toJson(), {
      'accion': 'AJUSTAR',
      'anulado': false,
      'nuevoResultado': 'PRESENTE',
      'motivo': 'x',
    });
  });

  test('el cubit filtra, informa errores y exige motivo de 20 caracteres',
      () async {
    final remote = _RemoteFake();
    final cubit = MarcajesAdminCubit(remote: remote);
    await cubit.cargar();
    expect(cubit.state.estado, EstadoMarcajesAdmin.listo);
    expect(cubit.state.items.single.usuarioNombre, 'Ana Gómez');

    cubit.filtrarResultado('TARDANZA');
    await Future<void>.delayed(Duration.zero);
    expect(remote.consultas.last.resultado, 'TARDANZA');

    expect(await cubit.ajustar('m-1', const AjusteMarcaje.anular('corto')),
        contains('20 caracteres'));
    expect(remote.ajustes, isEmpty);
    const motivo = 'Falla del GPS verificada por soporte';
    expect(
        await cubit.ajustar('m-1', const AjusteMarcaje.anular(motivo)), isNull);
    expect(remote.ajustes.single.$1, 'm-1');

    remote.error = Exception('Sin conexión');
    await cubit.cargar();
    expect(cubit.state.estado, EstadoMarcajesAdmin.error);
    expect(cubit.state.error, 'Sin conexión');
    await cubit.close();
  });

  testWidgets(
      'la pantalla lista por nombre y el detalle oculta acciones sin permiso',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: MarcajesAdminScreen(remote: _RemoteFake()))));
    await tester.pumpAndSettle();
    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.textContaining('Cálculo I · Grupo 01'), findsOneWidget);
    await tester.tap(find.text('Ana Gómez'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del marcaje'), findsOneWidget);
    expect(find.text('Anular'), findsNothing);
  });

  testWidgets('con marcaje:ajustar se anula con motivo obligatorio',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final remote = _RemoteFake();
    final auth = await tester
        .runAsync(() => authBlocCon(['marcaje:leer', 'marcaje:ajustar']));
    await tester.pumpWidget(BlocProvider<AuthBloc>.value(
      value: auth!,
      child: MaterialApp(
          home: Scaffold(body: MarcajesAdminScreen(remote: remote))),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Gómez'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anular'));
    await tester.pumpAndSettle();
    final boton = find.widgetWithText(FilledButton, 'Anular');
    expect(tester.widget<FilledButton>(boton).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('motivo-ajuste')),
        'Marcaje duplicado por reintento');
    await tester.pump();
    await tester.tap(boton);
    await tester.pumpAndSettle();
    expect(remote.ajustes.single.$2['anulado'], isTrue);
    expect(find.text('Marcaje anulado'), findsOneWidget);
  });
}

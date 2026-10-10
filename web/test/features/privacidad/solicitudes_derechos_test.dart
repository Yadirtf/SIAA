import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/dashboard/presentation/models/nav_item.dart';
import 'package:siaa_web/features/privacidad/data/derechos_remote_datasource.dart';
import 'package:siaa_web/features/privacidad/data/models/solicitud_derecho_model.dart';
import 'package:siaa_web/features/privacidad/presentation/bloc/solicitudes_derechos_cubit.dart';
import 'package:siaa_web/features/privacidad/presentation/screens/solicitudes_derechos_screen.dart';

/// Bandeja en memoria: registra las operaciones y resuelve los casos.
class _FakeDerechos extends DerechosRemoteDataSource {
  final List<String> llamadas = [];
  List<Map<String, dynamic>> casos = [
    {
      'id': 's1',
      'tipo': 'RECTIFICACION',
      'estado': 'RADICADA',
      'titularNombre': 'Carlos Pérez',
      'titularCorreo': 'docente@siaa.edu.co',
      'descripcion': 'Mi apellido está mal escrito',
      'cambios': {'apellido': 'Pérez Rojas'},
      'radicadaEn': '2026-10-01T15:00:00Z',
      'venceEn': '2026-10-22T04:59:59Z',
      'vencida': false,
    },
  ];
  ApiException? errorResolver;

  @override
  Future<List<SolicitudDerechoModel>> listar({bool soloAbiertas = true}) async {
    llamadas.add('listar:$soloAbiertas');
    return casos
        .map(SolicitudDerechoModel.fromJson)
        .where((s) => !soloAbiertas || s.abierta)
        .toList();
  }

  @override
  Future<void> asumir(String id) async {
    llamadas.add('asumir:$id');
    casos.first['estado'] = 'EN_TRAMITE';
  }

  @override
  Future<void> resolver(
    String id, {
    required bool atendida,
    required String respuesta,
  }) async {
    llamadas.add('resolver:$id:$atendida:$respuesta');
    if (errorResolver != null) throw errorResolver!;
    casos.first['estado'] = atendida ? 'ATENDIDA' : 'DENEGADA';
  }
}

void main() {
  test('la bandeja exige usuario:editar', () {
    Set<NavSection> visibles(List<String> p) =>
        NavItem.visiblesPara(p).map((i) => i.section).toSet();
    expect(visibles(const []), isNot(contains(NavSection.solicitudesDerechos)));
    expect(
      visibles(const ['usuario:editar']),
      contains(NavSection.solicitudesDerechos),
    );
  });

  test('asumir y resolver recargan la bandeja; un error se muestra', () async {
    final remote = _FakeDerechos();
    final cubit = SolicitudesDerechosCubit(remote: remote);
    addTearDown(cubit.close);
    await cubit.cargar();
    expect(cubit.state.solicitudes.single.estadoLegible, 'Radicada');

    await cubit.asumir('s1');
    expect(cubit.state.solicitudes.single.estado, 'EN_TRAMITE');
    expect(cubit.state.mensaje, contains('asumida'));

    remote.errorResolver = const ApiException(
      message: 'Otra persona ya atendió esta solicitud',
      statusCode: 409,
    );
    await cubit.resolver('s1', atendida: true, respuesta: 'Corregido');
    expect(cubit.state.error, contains('Otra persona'));

    remote.errorResolver = null;
    await cubit.resolver(
      's1',
      atendida: true,
      respuesta: 'Corregido según documento',
    );
    expect(cubit.state.solicitudes, isEmpty);
    expect(cubit.state.mensaje, contains('atendida'));
  });

  testWidgets('la pantalla muestra el caso y atiende con respuesta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final remote = _FakeDerechos();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SolicitudesDerechosScreen(remote: remote)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Carlos Pérez'), findsOneWidget);
    expect(find.textContaining('apellido → Pérez Rojas'), findsOneWidget);

    await tester.tap(find.text('Atender'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Se corrigió el apellido según el documento.',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Atender'));
    await tester.pumpAndSettle();
    expect(
      remote.llamadas,
      contains('resolver:s1:true:Se corrigió el apellido según el documento.'),
    );
    expect(find.text('Sin solicitudes'), findsOneWidget);
  });
}

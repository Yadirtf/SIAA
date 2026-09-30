import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/features/auditoria/data/auditoria_remote_datasource.dart';
import 'package:siaa_web/features/auditoria/domain/auditoria_repository_impl.dart';
import 'package:siaa_web/features/auditoria/presentation/bloc/auditoria_cubit.dart';
import 'package:siaa_web/features/auditoria/presentation/screens/auditoria_screen.dart';

void main() {
  testWidgets('lista la bitácora y abre el detalle con JSON', (tester) async {
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
    await tester.binding.setSurfaceSize(const Size(1600, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final peticiones = <Uri>[];
    final client = MockClient((req) async {
      peticiones.add(req.url);
      return http.Response(
        '[{"id":"a1","entidad":"usuario","entidadId":"u1",'
        '"accion":"usuario.desactivar","actorId":"adm",'
        '"actorNombre":"Admin General","valorAnterior":{"activo":true},'
        '"valorNuevo":{"activo":false},"creadoEn":"2026-09-29T12:00:00Z"}]',
        200,
        headers: {'x-total-count': '1', 'content-type': 'application/json'},
      );
    });
    final repo = AuditoriaRepositoryImpl(
      remoteDataSource: AuditoriaRemoteDataSource(
        client: ApiClient(client: client),
      ),
    );

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuditoriaCubit(repository: repo),
        child: const MaterialApp(home: Scaffold(body: AuditoriaScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(peticiones.single.path, endsWith('/auditoria'));
    expect(find.text('usuario.desactivar'), findsOneWidget);
    expect(find.text('Admin General'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsOneWidget);

    await tester.tap(find.byTooltip('Ver detalle'));
    await tester.pumpAndSettle();
    expect(find.text('Valor anterior'), findsOneWidget);
    expect(find.text('{\n  "activo": false\n}'), findsOneWidget);
  });
}

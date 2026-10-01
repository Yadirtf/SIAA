import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/core/network/edicion_remote_datasource.dart';
import 'package:siaa_web/features/academico/data/models/academico_models.dart';
import 'package:siaa_web/features/academico/presentation/bloc/academico_bloc.dart';
import 'package:siaa_web/features/academico/presentation/edicion/editores_academicos.dart';
import 'package:siaa_web/features/geo/presentation/edicion/editores_geo.dart';

import '../../helpers/fake_edicion.dart';
import 'academico_dialogs_test.dart' show FakeAcademicoRepository;

const _facultad = FacultadModel(
  id: 'fac-1',
  codigo: 'ING',
  nombre: 'Ingeniería',
  sedeId: 'sede-1',
);

void main() {
  late FakeEdicion edicion;

  setUp(() => edicion = FakeEdicion());

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<EdicionRemoteDataSource>.value(
        value: edicion,
        child: BlocProvider(
          create: (_) => AcademicoBloc(repository: FakeAcademicoRepository()),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => editarFacultad(ctx, _facultad),
                  child: const Text('Editar'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
  }

  Future<void> renombrar(WidgetTester tester, String nombre) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      nombre,
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
  }

  testWidgets('abre la facultad con sus datos y guarda el nuevo nombre', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('Editar facultad'), findsOneWidget);
    expect(find.text('ING'), findsOneWidget);

    await renombrar(tester, '  Ingeniería y Ciencias ');

    final (url, cuerpo, parcial) = edicion.llamadas.single;
    expect(url, endsWith('/facultades/fac-1'));
    expect(parcial, isFalse);
    expect(cuerpo, {'codigo': 'ING', 'nombre': 'Ingeniería y Ciencias'});
    expect(find.text('Editar facultad'), findsNothing);
  });

  testWidgets('no envía un nombre vacío', (tester) async {
    await abrir(tester);
    await renombrar(tester, '   ');
    expect(edicion.llamadas, isEmpty);
    expect(find.text('Nombre es obligatorio'), findsOneWidget);
  });

  testWidgets(
    'si el servidor rechaza, explica el error y conserva lo escrito',
    (tester) async {
      edicion.rechazo = const ApiException(
        statusCode: 409,
        message: 'Ya existe una facultad con el código ING.',
      );
      await abrir(tester);
      await renombrar(tester, 'Ingeniería Nueva');

      expect(
        find.text('Ya existe una facultad con el código ING.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Revisar el formulario'));
      await tester.pumpAndSettle();
      expect(find.text('Editar facultad'), findsOneWidget);
      expect(find.text('Ingeniería Nueva'), findsOneWidget);
    },
  );

  test('parsearPisos lee los pisos nuevos escritos con comas o espacios', () {
    expect(parsearPisos('4, 5 6;7'), [4, 5, 6, 7]);
    expect(parsearPisos('dos, 3'), [3]);
    expect(parsearPisos(''), isEmpty);
  });
}

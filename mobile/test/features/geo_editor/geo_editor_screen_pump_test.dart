import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_bloc.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/screens/geo_editor_screen.dart';

void main() {
  testWidgets('GeoEditorScreen pumps without crashing for newly created aula', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<GeoEditorBloc>(
          create: (_) => GeoEditorBloc(),
          child: const GeoEditorScreen(
            espacioId: 'esp-01',
            espacioCodigo: 'A-101',
            espacioNombre: 'Aula Magistral 101',
            coordenadasExistentes: null,
          ),
        ),
      ),
    );

    final exception = tester.takeException();
    print('GEO_EDITOR EXCEPTION: $exception');
    expect(exception, isNull);
  });
}

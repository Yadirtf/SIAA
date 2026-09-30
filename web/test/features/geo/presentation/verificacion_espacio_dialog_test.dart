import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/geo/data/models/geo_models.dart';
import 'package:siaa_web/features/geo/presentation/bloc/verificacion_espacio_cubit.dart';
import 'package:siaa_web/features/geo/presentation/dialogs/verificacion_espacio_dialog.dart';

import 'fake_geo_repository.dart';

void main() {
  late FakeGeoRepository repo;
  EspacioModel? guardado;

  Future<void> abrir(WidgetTester tester, EspacioModel espacio) async {
    repo = FakeGeoRepository()..espacios = [espacio];
    guardado = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BlocProvider(
                create: (_) =>
                    VerificacionEspacioCubit(repository: repo, espacioId: 'e1'),
                child: VerificacionEspacioDialog(
                  espacio: espacio,
                  onGuardado: (e) => guardado = e,
                ),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('precarga valores, agrega/quita BSSIDs y guarda', (tester) async {
    await abrir(
      tester,
      espacioDePrueba(
        verificacion: const VerificacionEspacioModel(
          wifiBssids: ['aa:bb:cc:dd:ee:ff'],
          bleUuid: 'uuid-1',
        ),
      ),
    );
    expect(find.text('aa:bb:cc:dd:ee:ff'), findsOneWidget);
    expect(find.text('uuid-1'), findsOneWidget);
    expect(find.text('Quitar verificación'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('bssid-input')),
      '11:22:33:44:55:66',
    );
    await tester.tap(find.text('Agregar'));
    await tester.pump();
    await tester.tap(find.byTooltip('Quitar BSSID').first);
    await tester.pump();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.ultimaVerificacion!.wifiBssids, ['11:22:33:44:55:66']);
    expect(repo.ultimaVerificacion!.bleUuid, 'uuid-1');
    expect(guardado!.tieneVerificacion, isTrue);
    expect(find.byType(VerificacionEspacioDialog), findsNothing);
  });

  testWidgets('Generar crea un código QR con el código del espacio', (
    tester,
  ) async {
    await abrir(tester, espacioDePrueba());
    expect(find.text('Quitar verificación'), findsNothing);

    await tester.tap(find.text('Generar'));
    await tester.pump();

    final campo = tester.widget<TextField>(
      find.byKey(const Key('qr-codigo-input')),
    );
    expect(
      campo.controller!.text,
      matches(RegExp(r'^SIAA-AUL-101-[A-Z0-9]{6}$')),
    );
  });

  testWidgets('muestra los errores del backend junto a cada campo', (
    tester,
  ) async {
    await abrir(tester, espacioDePrueba());
    repo.errorVerificacion = const ApiException(
      message: 'Verificación complementaria inválida',
      statusCode: 422,
      details: {
        'detalles': [
          {'campo': 'wifiBssids', 'error': 'BSSID inválido: zz'},
          {
            'campo': 'qrCodigo',
            'error': 'El código QR debe tener al menos 6 caracteres',
          },
        ],
      },
    );

    await tester.enterText(find.byKey(const Key('bssid-input')), 'zz');
    await tester.tap(find.text('Agregar'));
    await tester.enterText(find.byKey(const Key('qr-codigo-input')), 'ABC');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Verificación complementaria inválida'), findsOneWidget);
    expect(find.text('BSSID inválido: zz'), findsOneWidget);
    expect(
      find.text('El código QR debe tener al menos 6 caracteres'),
      findsOneWidget,
    );
    expect(guardado, isNull);
  });
}

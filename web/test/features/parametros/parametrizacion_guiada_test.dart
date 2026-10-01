import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/parametros/data/opciones_ambito_datasource.dart';
import 'package:siaa_web/core/models/opcion_catalogo.dart';
import 'package:siaa_web/features/parametros/domain/catalogo_parametros.dart';
import 'package:siaa_web/features/parametros/domain/models/parametro_model.dart';
import 'package:siaa_web/features/parametros/domain/parametros_repository.dart';
import 'package:siaa_web/features/parametros/presentation/bloc/parametros_bloc.dart';
import 'package:siaa_web/features/parametros/presentation/screens/parametros_screen.dart';
import 'package:siaa_web/features/parametros/presentation/widgets/linea_tiempo_clase.dart';

// Claves de backend/internal/domain/parametro/parametro.go (ValoresPorDefecto).
const _clavesBackend = [
  'holgura_entrada_antes_min',
  'holgura_entrada_despues_min',
  'umbral_tardanza_min',
  'holgura_salida_antes_min',
  'holgura_salida_despues_min',
  'precision_gps_max_metros',
  'buffer_perimetral_metros',
  'promedio_lecturas_vertice',
  'salida_obligatoria',
  'offline_permitido',
  'bloqueo_mock_location',
  'bloqueo_dispositivo_rooteado',
  'verificacion_complementaria',
  'exigir_attestation',
  'porcentaje_minimo_asistencia',
  'inasistencias_consecutivas_alerta',
  'retencion_coordenadas_dias',
];

ParametroEfectivoModel _p(
  String clave,
  Object valor, [
  String nivel = 'GLOBAL',
]) => ParametroEfectivoModel(
  clave: clave,
  valor: valor,
  nivel: nivel,
  nivelId: '',
);

class _Repo implements ParametrosRepository {
  final guardados = <GuardarParametroRequest>[];

  @override
  Future<ParametrosSnapshot> obtenerEfectivos({
    String? sedeId,
    String? facultadId,
    String? bloqueId,
    String? espacioId,
    String? asignacionId,
  }) async => ParametrosSnapshot(
    parametros: [for (final c in catalogoParametros) _p(c.clave, c.porDefecto)],
  );

  @override
  Future<void> guardarParametro(GuardarParametroRequest r) async =>
      guardados.add(r);
}

class _SinOpciones implements FuenteOpcionesAmbito {
  @override
  Future<List<OpcionCatalogo>> opciones(String nivel) async => const [];
}

void main() {
  test('cada parámetro del backend tiene nombre y explicación', () {
    for (final clave in _clavesBackend) {
      final info = infoParametro(clave);
      expect(info.nombre, isNot(clave), reason: clave);
      expect(info.comoFunciona, isNotEmpty, reason: clave);
    }
    expect(catalogoParametros.length, _clavesBackend.length);
  });

  test('valida el rango y muestra la unidad', () {
    final h = infoParametro('holgura_entrada_antes_min');
    expect(h.formatear(15), '15 min');
    expect(h.validar('130'), 'Debe estar entre 0 y 120 min');
    expect(h.validar('dos'), 'Escriba un número entero');
    expect(h.validar('20'), isNull);
    expect(
      infoParametro('salida_obligatoria').formatear('OPCIONAL'),
      'Opcional',
    );
  });

  test('la clase de ejemplo explica las ventanas en a. m./p. m.', () {
    final v = VentanasEjemplo.desde([
      _p('holgura_entrada_antes_min', 15),
      _p('holgura_entrada_despues_min', 20),
      _p('umbral_tardanza_min', 10),
      _p('salida_obligatoria', 'OPCIONAL'),
    ]);
    expect(v.descripcion, [
      'Entrada: de 6:45 a. m. a 7:20 a. m.',
      'Presente hasta 7:10 a. m.; desde ahí y hasta 7:20 a. m. cuenta como Tardanza.',
      'Salida: de 8:50 a. m. a 9:20 a. m.',
    ]);
    final sinTardanza = VentanasEjemplo.desde([
      _p('holgura_entrada_despues_min', 5),
      _p('umbral_tardanza_min', 10),
    ]);
    expect(sinTardanza.tardanzaInalcanzable, isTrue);
  });

  testWidgets('la pantalla agrupa los parámetros y explica cada uno', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1500, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _Repo();
    await tester.pumpWidget(
      RepositoryProvider<FuenteOpcionesAmbito>.value(
        value: _SinOpciones(),
        child: BlocProvider(
          create: (_) => ParametrosBloc(repository: repo),
          child: const MaterialApp(home: Scaffold(body: ParametrosScreen())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final g in GrupoParametro.values) {
      expect(find.text(g.titulo), findsOneWidget);
    }
    expect(find.text('Así queda una clase con estos valores'), findsOneWidget);
    expect(find.text('• Entrada: de 6:45 a. m. a 7:15 a. m.'), findsOneWidget);
    expect(find.text('Todavía no se aplica'), findsNWidgets(5));

    await tester.tap(find.byTooltip('¿Qué configura "Umbral de tardanza"?'));
    await tester.pumpAndSettle();
    expect(find.text('Para qué sirve'), findsOneWidget);
    expect(find.text('Cuándo surte efecto'), findsOneWidget);
    expect(find.textContaining('Entre 0 y 60 min'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('¿Cómo funciona?'));
    await tester.pumpAndSettle();
    expect(find.text('Cómo funciona la parametrización'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    // Un valor fuera de rango se explica y no se envía.
    await tester.tap(find.text('10 min').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '90');
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Debe estar entre 0 y 60 min'), findsOneWidget);
    expect(repo.guardados, isEmpty);
  });
}

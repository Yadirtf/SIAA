import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/archivo_binario.dart';
import 'package:siaa_web/core/upload/selector_archivos.dart';
import 'package:siaa_web/features/academico/data/models/importacion_model.dart';
import 'package:siaa_web/features/academico/domain/importacion_repository.dart';
import 'package:siaa_web/features/academico/presentation/bloc/importacion_bloc.dart';
import 'package:siaa_web/features/academico/presentation/dialogs/importar_csv_dialog.dart';

const _fila = FilaImportacionModel(
  numeroFila: 3,
  periodoCodigo: '2026-2',
  facultadCodigo: '',
  programaCodigo: 'SIS',
  asignaturaCodigo: 'MAT1',
  asignaturaNombre: '',
  grupoCodigo: '11',
  docenteDocumento: '999',
  aulaCodigo: 'A-302',
  diaSemana: 2,
  horaInicio: '06:00',
  horaFin: '07:00',
  modalidad: 'PRESENCIAL',
  valida: false,
  errores: ["El docente '999' no existe"],
);

/// API simulada: el archivo con "malo" supera el umbral; el limpio se aplica.
class _RepoCarga implements ImportacionRepository {
  final List<String> llamadas = [];

  PreviewImportacionModel _informe(String contenido) =>
      contenido.contains('malo')
      ? const PreviewImportacionModel(
          totalFilas: 2,
          filasValidas: 1,
          filasConError: 1,
          filas: [_fila],
          umbralErroresPct: 5,
          superaUmbral: true,
        )
      : const PreviewImportacionModel(
          totalFilas: 1,
          filasValidas: 1,
          filasConError: 0,
          filas: [],
        );

  @override
  Future<PreviewImportacionModel> preview(
    List<int> bytes,
    String nombre,
  ) async {
    llamadas.add('preview:$nombre');
    return _informe(utf8.decode(bytes));
  }

  @override
  Future<ResultadoImportacionModel> confirmar(
    List<int> bytes,
    String nombre,
  ) async {
    llamadas.add('confirmar:$nombre');
    final informe = _informe(utf8.decode(bytes));
    return informe.superaUmbral
        ? ResultadoImportacionModel(
            aplicada: false,
            mensaje: 'No se aplicó nada',
            informe: informe,
          )
        : const ResultadoImportacionModel(
            aplicada: true,
            mensaje: 'Carga aplicada',
            asignacionesCreadas: 1,
          );
  }

  @override
  Future<ArchivoBinario> diagnostico(List<int> bytes, String nombre) async {
    llamadas.add('diagnostico:$nombre');
    return ArchivoBinario(bytes: Uint8List.fromList(bytes), mime: 'text/csv');
  }

  @override
  Future<ArchivoBinario> plantilla(String formato) async {
    llamadas.add('plantilla:$formato');
    return ArchivoBinario(bytes: Uint8List(0), mime: 'text/csv');
  }
}

void main() {
  test(
    'el bloc valida, descarga el diagnóstico y no aplica sobre el umbral',
    () async {
      final repo = _RepoCarga();
      final guardados = <String>[];
      final bloc = ImportacionBloc(
        repository: repo,
        guardar: (a, n) => guardados.add(n),
      );
      bloc.add(
        PreviewImportarCsvEvent(bytes: utf8.encode('malo'), filename: 'h.csv'),
      );
      final previa = await bloc.stream.firstWhere(
        (s) => s is ImportacionPreviewLoaded,
      ) as ImportacionPreviewLoaded;
      expect(previa.preview.superaUmbral, isTrue);

      bloc.add(const DescargarDiagnosticoEvent());
      bloc.add(const ConfirmarImportarCsvEvent());
      final tras = await bloc.stream.firstWhere(
        (s) => s is ImportacionPreviewLoaded && s.aviso != null,
      ) as ImportacionPreviewLoaded;
      expect(tras.aviso, 'No se aplicó nada');
      expect(guardados, ['diagnostico-h.csv']);
      expect(repo.llamadas, [
        'preview:h.csv',
        'diagnostico:h.csv',
        'confirmar:h.csv',
      ]);
      await bloc.close();
    },
  );

  testWidgets('el asistente sube el archivo elegido y aplica la carga limpia', (
    tester,
  ) async {
    final repo = _RepoCarga();
    final bloc = ImportacionBloc(repository: repo, guardar: (_, __) {});
    addTearDown(bloc.close);
    Future<ArchivoSeleccionado?> elegir({String accept = ''}) async =>
        ArchivoSeleccionado(
          nombre: 'limpio.xlsx',
          bytes: Uint8List.fromList(utf8.encode('ok')),
        );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: ImportarCsvDialog(seleccionar: elegir),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Elegir archivo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('limpio.xlsx'), findsOneWidget);
    expect(find.text('Aplicar carga (1 filas)'), findsOneWidget);
    expect(repo.llamadas, ['preview:limpio.xlsx']);
  });
}

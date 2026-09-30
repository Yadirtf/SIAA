import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/justificaciones/data/datasources/justificacion_remote_datasource.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/justificacion_exception.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/soporte_adjunto.dart';

/// Adaptador que registra la petición y responde con un cuerpo fijo.
class _AdaptadorFijo implements HttpClientAdapter {
  final int status;
  final Object cuerpo;
  final Map<String, List<String>> headers;
  RequestOptions? ultima;
  String? cuerpoEnviado;

  _AdaptadorFijo(this.status, this.cuerpo, {this.headers = const {}});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    ultima = options;
    if (requestStream != null) {
      final bytes = await requestStream.expand((c) => c).toList();
      cuerpoEnviado = latin1.decode(bytes);
    }
    return ResponseBody.fromString(jsonEncode(cuerpo), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
      ...headers,
    });
  }

  @override
  void close({bool force = false}) {}
}

JustificacionRemoteDataSource _ds(_AdaptadorFijo a) =>
    JustificacionRemoteDataSource(
        dio: Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'))
          ..httpClientAdapter = a);

void main() {
  final soporte = SoporteAdjunto(
    nombre: 'incapacidad.pdf',
    bytes: Uint8List.fromList(utf8.encode('%PDF-1.4 contenido')),
  );

  test('radicar envía multipart con campos y soportes repetidos', () async {
    final a = _AdaptadorFijo(201, {'id': 'j1', 'estado': 'RADICADA'});
    final j = await _ds(a).radicar(
      sesionId: 's1',
      tipo: 'INCAPACIDAD',
      descripcion: 'Incapacidad de dos días',
      soportes: [soporte, soporte],
    );

    expect(j.id, 'j1');
    expect(a.ultima!.path, '/justificaciones');
    expect(a.ultima!.headers[Headers.contentTypeHeader],
        startsWith('multipart/form-data; boundary='));
    final cuerpo = a.cuerpoEnviado!;
    expect(cuerpo, contains('name="sesionId"'));
    expect(cuerpo, contains('INCAPACIDAD'));
    expect(
        RegExp('name="soportes"; filename="incapacidad.pdf"')
            .allMatches(cuerpo),
        hasLength(2));
    expect(cuerpo, contains('content-type: application/pdf'));
  });

  test('409 se traduce al mensaje del backend', () async {
    final a = _AdaptadorFijo(409, {
      'codigo': 'CONFLICTO',
      'mensaje': 'Ya existe una justificación pendiente para esta sesión',
      'correlationId': 'c1',
    });
    await expectLater(
      _ds(a).radicar(
        sesionId: 's1',
        tipo: 'PERMISO',
        descripcion: 'Permiso de decanatura',
        soportes: [soporte],
      ),
      throwsA(isA<JustificacionException>()
          .having((e) => e.status, 'status', 409)
          .having((e) => e.mensaje, 'mensaje',
              'Ya existe una justificación pendiente para esta sesión')),
    );
  });

  test('listar lee el arreglo y el total de X-Total-Count', () async {
    final a = _AdaptadorFijo(
      200,
      [
        {'id': 'j1', 'estado': 'APROBADA'},
      ],
      headers: {
        'x-total-count': ['7'],
      },
    );
    final pagina = await _ds(a).listar(estado: 'APROBADA', pagina: 2);
    expect(pagina.items.single.id, 'j1');
    expect(pagina.total, 7);
    expect(a.ultima!.queryParameters,
        {'pagina': 2, 'limite': 20, 'estado': 'APROBADA'});
  });
}

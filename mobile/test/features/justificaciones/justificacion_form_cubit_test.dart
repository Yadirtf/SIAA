import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/justificaciones/data/repositories/justificacion_repository.dart';
import 'package:siaa_mobile/features/justificaciones/data/services/soporte_picker_service.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/catalogo_justificacion.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/justificacion_exception.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/justificacion_model.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/soporte_adjunto.dart';
import 'package:siaa_mobile/features/justificaciones/presentation/cubit/justificacion_form_cubit.dart';
import 'package:siaa_mobile/features/justificaciones/presentation/cubit/justificacion_form_state.dart';

class _MockRepo extends Mock implements JustificacionRepository {}

class _MockPicker extends Mock implements SoportePickerService {}

void main() {
  late _MockRepo repo;
  late _MockPicker picker;

  final pdf = SoporteAdjunto(nombre: 'soporte.pdf', bytes: Uint8List(64));
  const descripcion = 'Cita médica programada con anticipación';
  const radicada = Justificacion(
    id: 'j1',
    sesionId: 's1',
    docenteId: 'd1',
    tipo: 'INCAPACIDAD',
    descripcion: descripcion,
    estado: 'RADICADA',
  );

  final listo = JustificacionFormState(
    sesionId: 's1',
    tipo: TipoJustificacion.incapacidad,
    soportes: [pdf],
  );

  setUp(() {
    repo = _MockRepo();
    picker = _MockPicker();
  });

  JustificacionFormCubit crear() =>
      JustificacionFormCubit(repo, sesionId: 's1', picker: picker);

  void radicarResponde(Future<Justificacion> Function() respuesta) {
    when(() => repo.radicar(
          sesionId: any(named: 'sesionId'),
          tipo: any(named: 'tipo'),
          descripcion: any(named: 'descripcion'),
          soportes: any(named: 'soportes'),
        )).thenAnswer((_) => respuesta());
  }

  blocTest<JustificacionFormCubit, JustificacionFormState>(
    'enviar radica con multipart y pasa a éxito',
    build: () {
      radicarResponde(() async => radicada);
      return crear();
    },
    seed: () => listo,
    act: (c) => c.enviar('  $descripcion  '),
    expect: () => [
      listo.copyWith(envio: EnvioJustificacion.enviando),
      listo.copyWith(envio: EnvioJustificacion.exito, radicada: radicada),
    ],
    verify: (_) => verify(() => repo.radicar(
          sesionId: 's1',
          tipo: 'INCAPACIDAD',
          descripcion: descripcion,
          soportes: [pdf],
        )).called(1),
  );

  blocTest<JustificacionFormCubit, JustificacionFormState>(
    '409: muestra el mensaje del backend y vuelve a edición',
    build: () {
      radicarResponde(() => Future.error(const JustificacionException(
            mensaje: 'Ya existe una justificación pendiente o aprobada '
                'para esta sesión',
            codigo: 'CONFLICTO',
            status: 409,
          )));
      return crear();
    },
    seed: () => listo,
    act: (c) => c.enviar(descripcion),
    expect: () => [
      listo.copyWith(envio: EnvioJustificacion.enviando),
      listo.copyWith(
        error: 'Ya existe una justificación pendiente o aprobada para esta '
            'sesión',
      ),
    ],
  );

  blocTest<JustificacionFormCubit, JustificacionFormState>(
    '422: muestra la validación del backend (fuera de la ventana hábil)',
    build: () {
      radicarResponde(() => Future.error(const JustificacionException(
            mensaje: 'El plazo para justificar esta sesión venció',
            codigo: 'VALIDACION',
            status: 422,
          )));
      return crear();
    },
    seed: () => listo,
    act: (c) => c.enviar(descripcion),
    expect: () => [
      listo.copyWith(envio: EnvioJustificacion.enviando),
      listo.copyWith(error: 'El plazo para justificar esta sesión venció'),
    ],
  );

  blocTest<JustificacionFormCubit, JustificacionFormState>(
    'valida en cliente la descripción corta sin llamar al backend',
    build: crear,
    seed: () => listo,
    act: (c) => c.enviar('corta'),
    expect: () => [
      listo.copyWith(error: 'La descripción debe tener al menos 10 caracteres'),
    ],
    verify: (_) => verifyNever(() => repo.radicar(
          sesionId: any(named: 'sesionId'),
          tipo: any(named: 'tipo'),
          descripcion: any(named: 'descripcion'),
          soportes: any(named: 'soportes'),
        )),
  );

  blocTest<JustificacionFormCubit, JustificacionFormState>(
    'exige al menos un soporte',
    build: crear,
    seed: () => JustificacionFormState(
      sesionId: 's1',
      tipo: TipoJustificacion.permiso,
    ),
    act: (c) => c.enviar(descripcion),
    expect: () => [
      const JustificacionFormState(
        sesionId: 's1',
        tipo: TipoJustificacion.permiso,
        error: 'Adjunta al menos un soporte',
      ),
    ],
  );

  blocTest<JustificacionFormCubit, JustificacionFormState>(
    'adjuntar agrega el archivo elegido y quitarSoporte lo elimina',
    build: () {
      when(() => picker.seleccionar(OrigenSoporte.pdf))
          .thenAnswer((_) async => pdf);
      return crear();
    },
    act: (c) async {
      await c.adjuntar(OrigenSoporte.pdf);
      c.quitarSoporte(0);
    },
    expect: () => [
      const JustificacionFormState(
          sesionId: 's1', envio: EnvioJustificacion.adjuntando),
      const JustificacionFormState(sesionId: 's1'),
      JustificacionFormState(sesionId: 's1', soportes: [pdf]),
      const JustificacionFormState(sesionId: 's1'),
    ],
  );

  blocTest<JustificacionFormCubit, JustificacionFormState>(
    'rechaza en cliente soportes mayores a 10 MB',
    build: crear,
    act: (c) => c.agregarSoporte(SoporteAdjunto(
      nombre: 'foto.jpg',
      bytes: Uint8List(ReglasSoporte.maxBytes + 1),
    )),
    expect: () => [
      const JustificacionFormState(
        sesionId: 's1',
        error: 'El archivo "foto.jpg" supera 10 MB',
      ),
    ],
  );

  blocTest<JustificacionFormCubit, JustificacionFormState>(
    'no permite más de 3 soportes',
    build: crear,
    seed: () =>
        JustificacionFormState(sesionId: 's1', soportes: [pdf, pdf, pdf]),
    act: (c) => c.agregarSoporte(pdf),
    expect: () => [
      JustificacionFormState(
        sesionId: 's1',
        soportes: [pdf, pdf, pdf],
        error: 'Puedes adjuntar máximo 3 soportes',
      ),
    ],
  );
}

// horario_widgets_test.dart - Mi Horario semanal con nombres legibles (US-ACA-01..09, §9.1)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/horario/data/datasources/horario_remote_datasource.dart';
import 'package:siaa_mobile/features/horario/data/models/sesion_horario_model.dart';
import 'package:siaa_mobile/features/horario/data/repositories/horario_repository_impl.dart';
import 'package:siaa_mobile/features/horario/domain/repositories/horario_repository.dart';
import 'package:siaa_mobile/features/horario/presentation/bloc/horario_bloc.dart';
import 'package:siaa_mobile/features/horario/presentation/bloc/horario_event.dart';
import 'package:siaa_mobile/features/horario/presentation/bloc/horario_state.dart';
import 'package:siaa_mobile/features/horario/presentation/screens/mi_horario_screen.dart';
import 'package:siaa_mobile/features/horario/presentation/widgets/dias_selector.dart';
import 'package:siaa_mobile/features/horario/presentation/widgets/horario_card.dart';

const _dtoSesiones = {
  'id': 'ses-101',
  'asignaturaId': '65f0aa11bb22cc33dd44ee55',
  'grupoId': '65f0aa11bb22cc33dd44ee66',
  'espacioId': '65f0aa11bb22cc33dd44ee77',
  'docenteIds': ['65f0aa11bb22cc33dd44ee88'],
  'fecha': '2026-09-28',
  'horaInicio': '08:00',
  'horaFin': '10:00',
  'estado': 'PROGRAMADA',
  'asignaturaCodigo': 'MAT101',
  'asignaturaNombre': 'Cálculo I',
  'grupoNumero': '01',
  'espacioCodigo': 'A-301',
  'espacioNombre': 'Aula 301',
  'docentesNombres': ['Ana Gómez', 'Luis Pérez'],
};

SesionHorarioModel _sesion(String nombre, String inicio,
        {String estado = 'PROGRAMADA'}) =>
    SesionHorarioModel(
      id: nombre,
      asignaturaNombre: nombre,
      grupoNumero: '01',
      espacioCodigo: 'A-301',
      fecha: DateTime(2026, 9, 28),
      horaInicio: inicio,
      horaFin: '12:00',
      estado: estado,
    );

class _RepoFake implements HorarioRepository {
  final Map<DateTime, List<SesionHorarioModel>> semana;
  Object? error;
  final List<DateTime> pedidos = [];
  _RepoFake(this.semana);

  @override
  Future<Map<DateTime, List<SesionHorarioModel>>> obtenerSemana(
      {required DateTime lunes, String? docenteId}) async {
    pedidos.add(lunes);
    if (error != null) throw error!;
    return semana;
  }
}

class _DataSourceFake extends HorarioRemoteDataSource {
  final List<String> fechas = [];
  _DataSourceFake() : super(dio: Dio());

  @override
  Future<List<SesionHorarioModel>> obtenerSesionesDelDia(
      {required DateTime fecha, String? docenteId}) async {
    fechas.add(HorarioRemoteDataSource.formatoFecha(fecha));
    return fecha.weekday == DateTime.monday
        ? [_sesion('Física', '10:00'), _sesion('Álgebra', '07:00')]
        : [];
  }
}

void main() {
  group('SesionHorarioModel', () {
    test('usa los nombres del DTO de /sesiones y nunca los ids', () {
      final m = SesionHorarioModel.fromJson(_dtoSesiones);
      expect(m.tituloConGrupo, 'Cálculo I · Grupo 01');
      expect(m.aulaEtiqueta, 'A-301 · Aula 301');
      expect(m.docentesNombres, ['Ana Gómez', 'Luis Pérez']);
      expect(m.fecha, DateTime(2026, 9, 28));
      for (final texto in [m.tituloConGrupo, m.aulaEtiqueta]) {
        expect(texto.contains('65f0'), isFalse);
      }
    });

    test('sin nombres muestra textos genéricos, no identificadores', () {
      final m = SesionHorarioModel.fromJson(const {
        'id': 's',
        'asignaturaId': 'abc123',
        'espacioId': 'xyz789',
        'fecha': '2026-09-28',
        'horaInicio': '08:00',
        'horaFin': '09:00',
      });
      expect(m.titulo, 'Asignatura sin nombre');
      expect(m.aulaEtiqueta, 'Aula por confirmar');
    });

    test('acepta el resumen de /me/sesiones/hoy y la cancelación con motivo',
        () {
      final m = SesionHorarioModel.fromJson(const {
        'sesionId': 's-9',
        'asignatura': 'Programación II',
        'grupo': '02',
        'espacioCodigo': 'LAB-2',
        'inicioProgramado': '2026-09-28T13:00:00Z',
        'finProgramado': '2026-09-28T15:00:00Z',
        'estado': 'CANCELADA',
        'motivoCancelacion': 'Festivo',
      });
      expect(m.id, 's-9');
      expect(m.tituloConGrupo, 'Programación II · Grupo 02');
      expect(m.esCancelada, isTrue);
      expect(m.motivoCancelacion, 'Festivo');
    });
  });

  group('HorarioRepositoryImpl', () {
    test('consulta lunes a sábado y ordena por hora', () async {
      final ds = _DataSourceFake();
      final semana = await HorarioRepositoryImpl(remoteDataSource: ds)
          .obtenerSemana(lunes: DateTime(2026, 9, 28));
      expect(ds.fechas, [
        '2026-09-28',
        '2026-09-29',
        '2026-09-30',
        '2026-10-01',
        '2026-10-02',
        '2026-10-03'
      ]);
      expect(semana[DateTime(2026, 9, 28)]!.map((s) => s.titulo),
          ['Álgebra', 'Física']);
    });
  });

  group('Widgets', () {
    testWidgets(
        'HorarioCard muestra asignatura, grupo, aula, docentes y motivo',
        (tester) async {
      final cancelada = SesionHorarioModel.fromJson({
        ..._dtoSesiones,
        'estado': 'CANCELADA',
        'motivoCancelacion': 'Paro'
      });
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: HorarioCard(sesion: cancelada))));
      expect(find.text('Cálculo I · Grupo 01'), findsOneWidget);
      expect(find.text('A-301 · Aula 301'), findsOneWidget);
      expect(find.text('Ana Gómez, Luis Pérez'), findsOneWidget);
      expect(find.text('Motivo: Paro'), findsOneWidget);
      expect(find.text('CANCELADA'), findsOneWidget);
    });

    testWidgets('DiasSelector muestra Lun..Sáb con conteo y responde',
        (tester) async {
      DateTime? elegido;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DiasSelector(
            lunes: DateTime(2026, 9, 28),
            fechaSeleccionada: DateTime(2026, 9, 30),
            conteo: (d) => d.day == 28 ? 2 : 0,
            onDiaSeleccionado: (d) => elegido = d,
          ),
        ),
      ));
      expect(find.text('Sáb'), findsOneWidget);
      final conteoLunes =
          tester.widget<Text>(find.byKey(const Key('conteo-dia-0')));
      expect(conteoLunes.data, '2');
      await tester.tap(find.text('Vie'));
      expect(elegido, DateTime(2026, 10, 2));
    });
  });

  group('HorarioBloc', () {
    final lunes = DateTime(2026, 9, 28);

    test('carga la semana y cambia de día sin nueva petición', () async {
      final repo = _RepoFake({
        lunes: [_sesion('Cálculo I', '08:00')]
      });
      final bloc = HorarioBloc(repository: repo);
      bloc.add(CargarHorarioEvent(fecha: DateTime(2026, 9, 30)));
      final listo = await bloc.stream
          .firstWhere((s) => s.estado == EstadoCargaHorario.listo);
      expect(listo.lunes, lunes);
      expect(listo.sesionesDelDia, isEmpty); // miércoles
      bloc.add(CambiarDiaEvent(lunes));
      final lun = await bloc.stream.first;
      expect(lun.sesionesDelDia.single.titulo, 'Cálculo I');
      expect(repo.pedidos, [lunes]);
      bloc.add(const CambiarSemanaEvent(1));
      await bloc.stream.firstWhere((s) => s.estado == EstadoCargaHorario.listo);
      expect(repo.pedidos.last, DateTime(2026, 10, 5));
      await bloc.close();
    });

    test('el domingo muestra la semana siguiente', () {
      final s = HorarioState.inicial(DateTime(2026, 10, 4)); // domingo
      expect(s.lunes, DateTime(2026, 10, 5));
    });

    test('un error se expone (sin ocultarlo con datos vacíos)', () async {
      final repo = _RepoFake({})..error = Exception('Sin permiso de horario');
      final bloc = HorarioBloc(repository: repo)
        ..add(const CargarHorarioEvent());
      final s = await bloc.stream
          .firstWhere((s) => s.estado == EstadoCargaHorario.error);
      expect(s.error, 'Sin permiso de horario');
      await bloc.close();
    });
  });

  group('MiHorarioScreen', () {
    testWidgets('muestra el error con Reintentar y luego las clases',
        (tester) async {
      final hoy = DateTime.now();
      final dia = HorarioState.diaLectivoDe(hoy);
      final repo = _RepoFake({
        dia: [_sesion('Bases de Datos', '08:00')]
      })
        ..error = Exception('Servidor no disponible');
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: MiHorarioScreen(repository: repo))));
      await tester.pumpAndSettle();
      expect(find.text('Servidor no disponible'), findsOneWidget);
      repo.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Bases de Datos · Grupo 01'), findsOneWidget);
    });
  });
}

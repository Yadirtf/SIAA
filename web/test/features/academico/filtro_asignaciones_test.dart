import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/academico/data/models/academico_models.dart';
import 'package:siaa_web/features/academico/presentation/helpers/filtro_asignaciones.dart';

AsignacionModel _asig(
  String id, {
  String periodo = 'per-1',
  int dia = 3,
  String inicio = '18:30',
  String docente = 'Ana Pérez',
  String asignatura = '',
  String aula = 'A-201 · Aula 201',
}) => AsignacionModel(
  id: id,
  periodoId: periodo,
  docenteNombre: docente,
  grupoId: 'g-1',
  asignaturaId: 'as-1',
  asignaturaNombre: asignatura,
  espacioNombre: aula,
  diaSemana: dia,
  horaInicio: inicio,
  horaFin: '19:30',
  modalidad: 'PRESENCIAL',
  estado: 'ACTIVA',
);

const _asignaturas = [
  AsignaturaModel(
    id: 'as-1',
    codigo: 'CAL1',
    nombre: 'Cálculo I',
    programaId: 'p',
    creditos: 4,
  ),
];
const _grupos = [
  GrupoModel(
    id: 'g-1',
    numero: '01',
    asignaturaId: 'as-1',
    periodoId: 'per-1',
    cupo: 30,
  ),
];

List<FilaAsignacion> _aplicar(
  FiltroAsignaciones f,
  List<AsignacionModel> lista,
) => f.aplicar(asignaciones: lista, asignaturas: _asignaturas, grupos: _grupos);

void main() {
  final lista = [
    _asig('a', dia: 3, inicio: '18:30'),
    _asig('b', dia: 1, inicio: '07:00', docente: 'Luis Mora'),
    _asig('c', periodo: 'per-2', dia: 1, inicio: '06:00'),
    _asig('d', dia: 1, inicio: '06:00', aula: 'B-105 · Laboratorio'),
  ];

  test('sin filtros lista todo ordenado por día y hora', () {
    final ids = _aplicar(
      const FiltroAsignaciones(),
      lista,
    ).map((f) => f.asignacion.id);
    expect(ids, ['c', 'd', 'b', 'a']);
  });

  test(
    'resuelve asignatura y grupo por nombre cuando el backend no los trae',
    () {
      final fila = _aplicar(const FiltroAsignaciones(), [_asig('a')]).single;
      expect(fila.asignatura, 'Cálculo I');
      expect(fila.grupo, '01');
    },
  );

  test('filtra por periodo y por día', () {
    final f = const FiltroAsignaciones(periodoId: 'per-1', dia: 1);
    expect(_aplicar(f, lista).map((f) => f.asignacion.id), ['d', 'b']);
  });

  test(
    'la búsqueda ignora tildes y mayúsculas y cubre docente, asignatura y aula',
    () {
      expect(
        _aplicar(
          const FiltroAsignaciones(texto: 'luis'),
          lista,
        ).map((f) => f.asignacion.id),
        ['b'],
      );
      expect(
        _aplicar(
          const FiltroAsignaciones(texto: 'laboratorio'),
          lista,
        ).map((f) => f.asignacion.id),
        ['d'],
      );
      expect(
        _aplicar(const FiltroAsignaciones(texto: 'CALCULO'), lista).length,
        4,
      );
    },
  );
}

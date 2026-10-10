// fakes_grupal.dart — Repositorio remoto falso para el marcaje grupal (US-MAR-13/14).
import 'package:dio/dio.dart';
import 'package:siaa_mobile/features/marcaje/data/datasources/marcaje_grupal_remote_datasource.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/lista_manual_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/sesion_activa_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/ventana_estudiantil_model.dart';

/// Error del backend con su cuerpo {codigo, mensaje}.
DioException errorApi(int status, String mensaje,
    {String codigo = 'CONFLICTO_UNICIDAD'}) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: req,
      statusCode: status,
      data: {'codigo': codigo, 'mensaje': mensaje},
    ),
  );
}

SesionActivaModel sesionDocente({Map<String, dynamic>? ventanaEstudiantil}) {
  final ahora = DateTime.now().toUtc();
  return SesionActivaModel.fromDetalleJson({
    'sesion': {
      'id': 'ses-1',
      'asignatura': 'Cálculo I',
      'grupo': 'A1',
      'espacio': {'id': 'e1', 'codigo': 'B-302', 'nombre': 'Aula 302'},
      'inicioProgramado':
          ahora.subtract(const Duration(minutes: 10)).toIso8601String(),
      'finProgramado': ahora.add(const Duration(hours: 1)).toIso8601String(),
    },
    'ventana': {'estado': 'ABIERTA'},
    'horaServidor': ahora.toIso8601String(),
    if (ventanaEstudiantil != null) 'ventanaEstudiantil': ventanaEstudiantil,
  });
}

class GrupalRemoteFake extends MarcajeGrupalRemoteDataSource {
  GrupalRemoteFake() : super(dio: Dio());

  Object? errorAbrir;
  Object? errorCerrar;
  Object? errorLista;
  Object? errorRegistrar;
  int? duracionPedida;
  int cierres = 0;
  String? motivoEnviado;
  Map<String, bool>? presentesEnviados;
  List<EstudianteListaManual> estudiantes = const [];
  ResultadoListaManual resultado = const ResultadoListaManual(
    mensaje: 'Lista manual registrada y auditada',
    registrados: 1,
    conservados: 1,
    noPertenecen: ['ajeno'],
  );

  @override
  Future<VentanaEstudiantil> abrirVentana(String sesionId,
      {required int duracionMinutos}) async {
    if (errorAbrir != null) throw errorAbrir!;
    duracionPedida = duracionMinutos;
    return VentanaEstudiantil(
      abierta: true,
      cierraEn: DateTime.now().add(Duration(minutes: duracionMinutos)),
    );
  }

  @override
  Future<VentanaEstudiantil> cerrarVentana(String sesionId) async {
    if (errorCerrar != null) throw errorCerrar!;
    cierres++;
    return VentanaEstudiantil(abierta: false, cierraEn: DateTime.now());
  }

  @override
  Future<List<EstudianteListaManual>> consultarLista(String sesionId) async {
    if (errorLista != null) throw errorLista!;
    return estudiantes;
  }

  @override
  Future<ResultadoListaManual> registrarLista({
    required String sesionId,
    required String motivo,
    required Map<String, bool> presentes,
  }) async {
    if (errorRegistrar != null) throw errorRegistrar!;
    motivoEnviado = motivo;
    presentesEnviados = presentes;
    return resultado;
  }
}

const estudiantesGrupo = [
  EstudianteListaManual(
    id: 'est-1',
    nombre: 'Laura Pérez',
    resultado: 'PRESENTE',
    origen: 'APP_MOVIL',
    bloqueado: true,
  ),
  EstudianteListaManual(id: 'est-2', nombre: 'Mateo Ruiz'),
];

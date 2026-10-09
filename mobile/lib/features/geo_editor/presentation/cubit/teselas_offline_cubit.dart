// teselas_offline_cubit.dart — Caché de teselas del modo mapa: cobertura sin red y descarga previa
// Sin conexión indica si el área visible tiene teselas guardadas (US-GEO-03 AC-04); con
// conexión permite guardar la zona de la sede o bloque antes de ir a levantar el espacio.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/network/conectividad.dart';
import '../../data/teselas/repositorio_teselas.dart';
import '../../domain/models/capa_mapa.dart';
import '../../domain/models/clave_tesela.dart';
import '../../domain/services/teselas_area.dart';
import '../widgets/map/tesela_cache_provider.dart';
import 'teselas_offline_state.dart';

class TeselasOfflineCubit extends Cubit<TeselasOfflineState> {
  /// Tope de teselas por descarga (≈ 30–60 MB de imágenes satelitales).
  static const limiteDescarga = 3000;

  /// Zoom más alejado que se guarda, para poder ubicar la sede sin red.
  static const zoomMinimoDescarga = 15;

  /// Máximo de teselas revisadas al estimar la cobertura del área visible.
  static const _muestraCobertura = 64;

  final RepositorioTeselas _repositorio;
  final Future<bool> Function() _hayConexion;
  final Duration _espera;
  final Map<CapaMapa, TileProvider> _proveedores = {};
  Timer? _temporizador;

  TeselasOfflineCubit({
    RepositorioTeselas? repositorio,
    Future<bool> Function()? hayConexion,
    Duration espera = const Duration(milliseconds: 700),
  })  : _repositorio = repositorio ?? RepositorioTeselas(),
        _hayConexion = hayConexion ?? hayConexionDeRed,
        _espera = espera,
        super(const TeselasOfflineState());

  /// Proveedor estable por capa (flutter_map recrea teselas si cambia la instancia).
  TileProvider proveedorPara(CapaMapa capa) => _proveedores.putIfAbsent(
        capa,
        () =>
            TeselaCacheTileProvider(repositorio: _repositorio, capa: capa.name),
      );

  static int zoomNativo(CapaMapa capa, double zoom) =>
      math.min(zoom.round(), capa.maxNativeZoom);

  /// Reevalúa la conexión y, sin red, la cobertura guardada del área visible.
  Future<void> evaluar(CapaMapa capa, AreaGeo visible, double zoom) async {
    final enLinea = await _hayConexion();
    if (isClosed) return;
    if (enLinea) {
      emit(state.copyWith(
          enLinea: true, cobertura: CoberturaTeselas.desconocida));
      return;
    }
    final z = zoomNativo(capa, zoom);
    final claves =
        TeselasArea.enArea(capa.name, visible, z, z).take(_muestraCobertura);
    final total = claves.length;
    final guardadas = await _repositorio.contarGuardadas(claves);
    if (isClosed) return;
    final cobertura = guardadas == 0
        ? CoberturaTeselas.ninguna
        : (guardadas < total
            ? CoberturaTeselas.parcial
            : CoberturaTeselas.completa);
    emit(state.copyWith(enLinea: false, cobertura: cobertura));
  }

  /// Llamado al mover la cámara: agrupa movimientos seguidos en una sola evaluación.
  void camaraMovida(CapaMapa capa, AreaGeo visible, double zoom) {
    _temporizador?.cancel();
    _temporizador = Timer(_espera, () => evaluar(capa, visible, zoom));
  }

  /// Guarda en el dispositivo las teselas del área visible para usarlas sin red.
  Future<void> descargarZona(
      CapaMapa capa, AreaGeo visible, double zoom) async {
    if (state.descargando) return;
    if (!await _hayConexion()) {
      _avisar('Se necesita conexión para descargar la zona. Hágalo desde la '
          'sede con WiFi antes de levantar el espacio.');
      return;
    }
    final zMax = math.min(capa.maxNativeZoom, 19);
    final zMin = math.min(zoomMinimoDescarga, math.max(3, zoom.floor()));
    final zTope = TeselasArea.zoomMaximoDentroDeLimite(
        visible, zMin, zMax, limiteDescarga);
    if (zTope == null) {
      _avisar('El área visible es demasiado grande para guardarla. Acerque el '
          'mapa a la sede o bloque e intente de nuevo.');
      return;
    }
    emit(state.copyWith(descargando: true, procesadas: 0, total: 0));
    final resumen = await _repositorio.predescargar(
      capa: capa.name,
      plantillaUrl: capa.urlTemplate,
      area: visible,
      zMin: zMin,
      zMax: zTope,
      onProgreso: (hechas, total) {
        if (isClosed) return;
        if (hechas == total || hechas % 10 == 0) {
          emit(state.copyWith(procesadas: hechas, total: total));
        }
      },
    );
    if (isClosed) return;
    emit(state.copyWith(descargando: false));
    _avisar(_textoResumen(resumen, zTope, zMax));
  }

  static String _textoResumen(ResumenDescarga r, int zTope, int zMax) {
    final b = StringBuffer('Zona guardada para uso sin conexión: '
        '${r.descargadas} teselas nuevas, ${r.yaGuardadas} ya estaban.');
    if (r.fallidas > 0) {
      b.write(' ${r.fallidas} no se pudieron descargar; repita la descarga.');
    }
    if (zTope < zMax) {
      b.write(' Por el tamaño del área se guardó hasta el zoom $zTope; '
          'acerque el mapa para guardar más detalle.');
    }
    return b.toString();
  }

  void _avisar(String texto) {
    if (isClosed) return;
    emit(state.copyWith(mensaje: texto, nuevoMensaje: true));
  }

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}

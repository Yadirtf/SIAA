// consentimiento_cubit.dart — Flujo del aviso de privacidad y la decisión (US-LEG-01, CA-011)
// Consulta la decisión vigente, carga el aviso y registra Acepto / No acepto.
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/consentimiento_gate.dart';
import '../../data/privacidad_remote_datasource.dart';
import 'consentimiento_state.dart';

class ConsentimientoCubit extends Cubit<ConsentimientoState> {
  final PrivacidadRemoteDataSource _remote;
  final ConsentimientoGate _gate;
  final Future<String> Function() _instalacionId;

  ConsentimientoCubit({
    PrivacidadRemoteDataSource? remote,
    ConsentimientoGate? gate,
    Future<String> Function()? instalacionId,
  })  : _remote = remote ?? PrivacidadRemoteDataSource(),
        _gate = gate ?? ConsentimientoGate.instance,
        _instalacionId =
            instalacionId ?? SecureStorage.getOrCreateInstalacionId,
        super(const ConsentimientoState());

  /// Consulta GET /me/consentimiento; si no hay aceptación carga también el aviso
  /// (su `contacto` se muestra cuando el marcaje queda deshabilitado).
  Future<void> verificar() async {
    emit(state.copyWith(fase: FaseConsentimiento.cargando, limpiarError: true));
    try {
      final c = await _remote.obtenerConsentimiento();
      await _gate.aplicar(c);
      emit(state.copyWith(fase: FaseConsentimiento.listo, consentimiento: c));
      if (!c.otorgado && state.politica?.version != c.versionVigente) {
        await cargarPolitica();
      }
    } catch (_) {
      emit(state.copyWith(
        fase: FaseConsentimiento.error,
        error:
            'No fue posible consultar su consentimiento. Revise su conexión.',
      ));
    }
  }

  /// GET /privacidad/politica — aviso vigente.
  Future<void> cargarPolitica() async {
    try {
      final politica = await _remote.obtenerPolitica();
      emit(state.copyWith(politica: politica, limpiarError: true));
    } catch (_) {
      emit(state.copyWith(
        error: 'No fue posible cargar el aviso de privacidad.',
      ));
    }
  }

  /// POST /me/consentimiento con la decisión explícita. Devuelve true si quedó registrada.
  Future<bool> decidir({required bool acepta}) async {
    final version =
        state.politica?.version ?? state.consentimiento?.versionVigente;
    if (version == null || version.isEmpty || state.enviando) return false;
    emit(state.copyWith(enviando: true, limpiarError: true));
    try {
      final c = await _remote.registrarDecision(
        version: version,
        acepta: acepta,
        dispositivoId: await _instalacionId(),
      );
      await _gate.aplicar(c);
      emit(state.copyWith(
        enviando: false,
        fase: FaseConsentimiento.listo,
        consentimiento: c,
      ));
      return true;
    } on VersionPoliticaDesactualizadaException {
      emit(state.copyWith(
        enviando: false,
        error:
            'Se publicó una nueva versión del aviso. Revísela antes de decidir.',
      ));
      await cargarPolitica();
      await verificar();
      return false;
    } catch (_) {
      emit(state.copyWith(
        enviando: false,
        error: 'No fue posible registrar su decisión. Inténtelo de nuevo.',
      ));
      return false;
    }
  }

  /// El servidor respondió 403 CONSENTIMIENTO_REQUERIDO: se vuelve a consultar.
  Future<void> requerirDeNuevo() async {
    await _gate.marcarRequerido();
    await verificar();
  }

  /// Cierre de sesión: la decisión pertenece al usuario anterior.
  void reiniciar() => emit(const ConsentimientoState());
}

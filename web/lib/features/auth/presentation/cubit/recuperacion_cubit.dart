import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/auth_repository.dart';

/// Estados del flujo de recuperación de contraseña (US-AUT-04).
enum RecuperacionPaso { inicial, enviando, solicitudEnviada, confirmada, error }

class RecuperacionState extends Equatable {
  final RecuperacionPaso paso;
  final String? mensaje;

  const RecuperacionState(this.paso, [this.mensaje]);

  @override
  List<Object?> get props => [paso, mensaje];
}

/// Solicita el enlace de recuperación y confirma la nueva contraseña con el token del correo.
class RecuperacionCubit extends Cubit<RecuperacionState> {
  final AuthRepository _repository;

  RecuperacionCubit(this._repository)
    : super(const RecuperacionState(RecuperacionPaso.inicial));

  Future<void> solicitar(String correo) async {
    emit(const RecuperacionState(RecuperacionPaso.enviando));
    try {
      await _repository.recuperarPassword(correo: correo.trim());
      emit(const RecuperacionState(RecuperacionPaso.solicitudEnviada));
    } catch (e) {
      emit(RecuperacionState(RecuperacionPaso.error, _mensaje(e)));
    }
  }

  Future<void> confirmar(String token, String password) async {
    emit(const RecuperacionState(RecuperacionPaso.enviando));
    try {
      await _repository.confirmarRecuperacion(
        token: token.trim(),
        newPassword: password,
      );
      emit(const RecuperacionState(RecuperacionPaso.confirmada));
    } catch (e) {
      emit(RecuperacionState(RecuperacionPaso.error, _mensaje(e)));
    }
  }

  String _mensaje(Object e) {
    if (e is ApiException) return e.message;
    return 'No se pudo completar la solicitud. Intenta de nuevo.';
  }
}

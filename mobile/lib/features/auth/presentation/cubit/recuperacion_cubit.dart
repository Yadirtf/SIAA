// Recuperación de contraseña en la app móvil - US-AUT-04
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';

enum RecuperacionPaso { correo, enviando, codigo, confirmada }

class RecuperacionState extends Equatable {
  final RecuperacionPaso paso;
  final String? error;

  const RecuperacionState(this.paso, {this.error});

  @override
  List<Object?> get props => [paso, error];
}

/// Pide el enlace por correo y, con el código recibido, define la nueva contraseña.
class RecuperacionCubit extends Cubit<RecuperacionState> {
  final AuthRepository _repository;

  RecuperacionCubit(this._repository)
      : super(const RecuperacionState(RecuperacionPaso.correo));

  /// Envía el correo. La respuesta es la misma exista o no la cuenta (anti-enumeración).
  Future<void> solicitar(String correo) async {
    emit(const RecuperacionState(RecuperacionPaso.enviando));
    try {
      await _repository.solicitarRecuperacion(correo: correo.trim());
      emit(const RecuperacionState(RecuperacionPaso.codigo));
    } on AuthException catch (e) {
      emit(RecuperacionState(RecuperacionPaso.correo, error: e.message));
    }
  }

  /// Pasa directo al paso del código (el usuario ya tiene el correo).
  void yaTengoCodigo() =>
      emit(const RecuperacionState(RecuperacionPaso.codigo));

  Future<void> confirmar(String codigo, String password) async {
    emit(const RecuperacionState(RecuperacionPaso.enviando));
    try {
      await _repository.confirmarRecuperacion(
        token: extraerToken(codigo),
        password: password,
      );
      emit(const RecuperacionState(RecuperacionPaso.confirmada));
    } on AuthException catch (e) {
      emit(RecuperacionState(RecuperacionPaso.codigo, error: e.message));
    }
  }
}

/// Acepta el código solo o el enlace completo del correo (…?token=…).
String extraerToken(String entrada) {
  final texto = entrada.trim();
  final uri = Uri.tryParse(texto);
  final token = uri?.queryParameters['token'];
  return (token != null && token.isNotEmpty) ? token : texto;
}

/// Política de contraseña del backend: 12+ caracteres, mayúscula, minúscula y dígito.
String? validarNuevaClave(String? valor) {
  final v = valor ?? '';
  if (v.length < 12) return 'Debe tener al menos 12 caracteres';
  if (!RegExp(r'[A-Z]').hasMatch(v) ||
      !RegExp(r'[a-z]').hasMatch(v) ||
      !RegExp(r'\d').hasMatch(v)) {
    return 'Combina mayúsculas, minúsculas y números';
  }
  return null;
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/catalogo_usuarios_model.dart';
import '../../domain/usuarios_repository.dart';
import 'usuarios_bloc.dart';

class CatalogoUsuariosState extends Equatable {
  final bool cargando;
  final CatalogoUsuariosModel catalogo;
  final String? error;

  const CatalogoUsuariosState({
    this.cargando = false,
    this.catalogo = const CatalogoUsuariosModel(),
    this.error,
  });

  bool get cargado => !cargando && error == null;

  @override
  List<Object?> get props => [cargando, catalogo, error];
}

/// Catálogos de roles y ámbitos usados por los selectores de usuarios.
class CatalogoUsuariosCubit extends Cubit<CatalogoUsuariosState> {
  final UsuariosRepository _repository;

  CatalogoUsuariosCubit({required UsuariosRepository repository})
    : _repository = repository,
      super(const CatalogoUsuariosState());

  Future<void> cargar() async {
    if (state.cargando) return;
    emit(CatalogoUsuariosState(cargando: true, catalogo: state.catalogo));
    try {
      final catalogo = await _repository.cargarCatalogo();
      emit(CatalogoUsuariosState(catalogo: catalogo));
    } catch (e) {
      emit(
        CatalogoUsuariosState(
          catalogo: state.catalogo,
          error: UsuariosBloc.mensajeDe(e),
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../geo_editor/data/espacio_repository.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import 'crear_bloque_dialog.dart';
import 'crear_espacio_dialog.dart';
import 'crear_sede_dialog.dart';

/// Coordinador desacoplado para mostrar los modales de creación y despachar eventos a HomeBloc.
class HomeDialogActions {
  static Future<void> crearSede(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => CrearSedeDialog(
        onGuardar: (
            {required String codigo,
            required String nombre,
            String? direccion}) async {
          context.read<HomeBloc>().add(CrearSedeRequested(
                codigo: codigo,
                nombre: nombre,
                direccion: direccion,
              ));
        },
      ),
    );
  }

  static Future<void> crearBloque(BuildContext context, SedeModel? sede) {
    if (sede == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Primero debe registrar o seleccionar una Sede.')),
      );
      return Future.value();
    }

    return showDialog(
      context: context,
      builder: (_) => CrearBloqueDialog(
        sedeNombre: sede.nombre,
        onGuardar: (
            {required String codigo,
            required String nombre,
            required List<int> pisos}) async {
          context.read<HomeBloc>().add(CrearBloqueRequested(
                sedeId: sede.id,
                codigo: codigo,
                nombre: nombre,
                pisos: pisos,
              ));
        },
      ),
    );
  }

  static Future<void> crearAula(
      BuildContext context, SedeModel? sede, BloqueModel? bloque) {
    if (sede == null || bloque == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Seleccione una Sede y un Bloque antes de crear un aula.')),
      );
      return Future.value();
    }

    return showDialog(
      context: context,
      builder: (_) => CrearEspacioDialog(
        bloqueNombre: bloque.nombre,
        pisosDisponibles: bloque.pisos,
        onGuardar: ({
          required String codigo,
          required String nombre,
          required int piso,
          required int capacidad,
          required String tipo,
        }) async {
          context.read<HomeBloc>().add(CrearEspacioRequested(
                sedeId: sede.id,
                bloqueId: bloque.id,
                codigo: codigo,
                nombre: nombre,
                piso: piso,
                capacidad: capacidad,
                tipo: tipo,
              ));
        },
      ),
    );
  }
}

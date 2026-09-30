import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/aviso_panel.dart';
import '../../data/privacidad_remote_datasource.dart';
import '../bloc/politica_privacidad_cubit.dart';
import '../widgets/markdown_simple.dart';
import '../widgets/politica_encabezado.dart';

/// Contenido del aviso de privacidad (RNF-LEG-003, US-LEG-01 AC-06).
/// Se usa tanto en la página pública como dentro de la consola.
class PoliticaPrivacidadView extends StatelessWidget {
  /// Origen de datos; por defecto el endpoint público real.
  final PrivacidadRemoteDataSource? dataSource;

  const PoliticaPrivacidadView({super.key, this.dataSource});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PoliticaPrivacidadCubit(
        dataSource: dataSource ?? PrivacidadRemoteDataSource(),
      )..cargar(),
      child: const _Contenido(),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoliticaPrivacidadCubit, PoliticaPrivacidadState>(
      builder: (context, state) {
        final politica = state.politica;
        Widget cuerpo;
        if (state.error != null) {
          cuerpo = AvisoPanel.error(
            titulo: 'No se pudo cargar el aviso de privacidad',
            detalle: state.error!,
            onReintentar: () =>
                context.read<PoliticaPrivacidadCubit>().cargar(),
          );
        } else if (politica == null) {
          return AvisoPanel.cargando();
        } else {
          cuerpo = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PoliticaEncabezado(politica: politica),
              const SizedBox(height: 16),
              MarkdownSimple(markdown: politica.contenido),
            ],
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: cuerpo,
            ),
          ),
        );
      },
    );
  }
}

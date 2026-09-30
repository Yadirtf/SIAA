import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/privacidad_remote_datasource.dart';
import 'politica_privacidad_view.dart';

/// Página pública del aviso de privacidad, accesible sin iniciar sesión
/// (enlace en el login o `?vista=privacidad`).
class AvisoPrivacidadScreen extends StatelessWidget {
  final PrivacidadRemoteDataSource? dataSource;

  const AvisoPrivacidadScreen({super.key, this.dataSource});

  /// Valor de `?vista=` que abre esta página directamente.
  static const String vista = 'privacidad';

  /// true si la URL actual pide abrir el aviso de privacidad.
  static bool solicitadaEn(Uri uri) => uri.queryParameters['vista'] == vista;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Aviso de privacidad')),
      body: PoliticaPrivacidadView(dataSource: dataSource),
    );
  }
}

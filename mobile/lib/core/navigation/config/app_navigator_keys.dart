// app_navigator_keys.dart — Llaves globales de navegación y mensajes (SIAA Movil)
// Permiten abrir destinos y mostrar avisos desde eventos externos (notificaciones push).
import 'package:flutter/material.dart';

class AppNavigatorKeys {
  AppNavigatorKeys._();

  static final navigator = GlobalKey<NavigatorState>();
  static final messenger = GlobalKey<ScaffoldMessengerState>();
}

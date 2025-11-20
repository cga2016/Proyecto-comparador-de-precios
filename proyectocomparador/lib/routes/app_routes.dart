import 'package:flutter/material.dart';
import 'package:proyectocomparador/models/juego.dart';
import 'package:proyectocomparador/screens/iniciarSesion.dart';
import 'package:proyectocomparador/screens/menuPrincipal.dart';
import 'package:proyectocomparador/screens/registroUsuarios.dart';
import 'package:proyectocomparador/screens/detalleJuego.dart';

class AppRoutes {
  static const String menuPrincipal = '/screen/menuPrincipal';
  static const String iniciarSesion = '/screen/iniciarSesion';
  static const String registroUsuario = '/screen/registroUsuarios';
  static const String detalleJuego = '/screen/detalleJuego';

  static final Map<String, WidgetBuilder> routes = {
    menuPrincipal: (context) => const MenuPrincipal(title: 'Menu Principal'),
    iniciarSesion: (context) => const IniciarSesion(title: "Iniciar Sesión"),
    registroUsuario: (context) => const RegistroUsuario(title: "Registro"),
  };

  // Aquí manejamos rutas con parámetros
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == detalleJuego) {
      final juego = settings.arguments as Juego;

      return MaterialPageRoute(
        builder: (_) => DetalleJuego(
          title: "Detalle del Juego",
          juego: juego,
        ),
      );
    }

    return null; // fallback
  }
}

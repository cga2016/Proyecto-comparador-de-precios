import 'package:flutter/material.dart';
import 'package:proyectocomparador/screens/screen.dart';

class AppRoutes {
  static const String menuPrincipal = '/screen/menuPrincipal';
  static const String iniciarSesion = '/screen/iniciarSesion';
  static const String registroUsuario = '/screen/registroUsuarios';
  static const String detalleJuego = '/screen/detalleJuego';
  static const String usuarioPerfil = '/screen/usuarioPerfil';
  static const String plantilla = '/screen/plantilla';
  static const String buscador = '/screen/buscador';
  static const String lista = '/screen/lista';

  static final Map<String, WidgetBuilder> routes = {
    menuPrincipal: (context) => const MenuPrincipal(title: 'Menu Principal'),
    iniciarSesion: (context) => const IniciarSesion(title: "Iniciar Sesión"),
    registroUsuario: (context) => const RegistroUsuario(title: "Registro"),
  };

  static void addRoutes(Map<String, WidgetBuilder> newRoutes) {
    routes.addAll(newRoutes);
  }
}

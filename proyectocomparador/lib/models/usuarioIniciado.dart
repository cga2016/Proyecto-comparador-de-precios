// ignore_for_file: file_names

import 'package:proyectocomparador/models/usuarios.dart';

class UsuarioIniciado {
  static Usuario? _usuario;
  static bool _sesionIniciada = false;

  static Usuario? get usuario => _usuario;
  static bool get sesionIniciada => _sesionIniciada;

  static final Usuario _usuarioAnonimo = Usuario(
    name: 'Anonimo',
    correo: 'anonimo@anonimo.com',
    contrasena: 'anonimo',
  );

  static void iniciarSesion(Usuario usuario) {
    _usuario = usuario;
    _sesionIniciada = true;
  }

  static void iniciarSesionAnonima() {
    _usuario = _usuarioAnonimo;
    _sesionIniciada = true;
  }

  static void cerrarSesion() {
    _usuario = null;
    _sesionIniciada = false;
  }
}

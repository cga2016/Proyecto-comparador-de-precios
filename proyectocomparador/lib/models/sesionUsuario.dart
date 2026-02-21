import 'package:proyectocomparador/models/usuario.dart';

class SesionUsuario {
  static Usuario? usuarioActual;

  static void iniciarSesion(Usuario usuario) {
    usuarioActual = usuario;
  }

  static void cerrarSesion() {
    usuarioActual = null;
  }
}

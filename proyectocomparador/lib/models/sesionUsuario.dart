import 'package:proyectocomparador/models/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SesionUsuario {
  static Usuario? usuarioActual;

  static void iniciarSesion(Usuario usuario) {
    usuarioActual = usuario;
  }

  static Future<void> cerrarSesion() async {
    usuarioActual = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("usuario_actual");
    await prefs.remove("ultima_notificacion");
    await prefs.remove("notificacion_mostrada_login");
  }
}

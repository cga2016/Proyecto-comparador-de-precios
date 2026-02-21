// ignore_for_file: file_names

import 'package:proyectocomparador/models/sesionUsuario.dart';
import 'package:proyectocomparador/models/usuario.dart';

class UsuarioIniciado {
  static Usuario? _usuario;
  static bool _sesionIniciada = false;

  static Usuario? get usuario => _usuario;
  static bool get sesionIniciada => _sesionIniciada;

  static final Usuario _usuarioAnonimo = Usuario(
    id: 0,
    nick: 'Anonimo',
    correo: 'anonimo@anonimo.com',
    contrasena: 'anonimo',
    imagenRuta: '',
    listaFavoritos: [],
  );

  static void iniciarSesion(Usuario usuario) {
    _usuario = usuario;
    SesionUsuario.iniciarSesion(usuario);
    _sesionIniciada = true;
    // debug
    // print('UsuarioIniciado: id=${usuario.id}, correo=${usuario.correo}');
  }

  static void iniciarSesionAnonima() {
    _usuario = _usuarioAnonimo;

    _sesionIniciada = true;
  }

  static void cerrarSesion() {
    _usuario = null;
    _sesionIniciada = false;
    SesionUsuario.cerrarSesion();
  }

  static bool get esAnonimo {
    if (_usuario == null) return false;
    return _usuario!.id == _usuarioAnonimo.id ||
        _usuario!.correo == _usuarioAnonimo.correo;
  }

  static String get usuarioIdString {
    if (_usuario == null) return '0';
    try {
      return _usuario!.idAsString;
    } catch (_) {
      return _usuario!.id.toString();
    }
  }

  static void asegurarListaFavoritos() {
    if (_usuario == null) return;
  }
}

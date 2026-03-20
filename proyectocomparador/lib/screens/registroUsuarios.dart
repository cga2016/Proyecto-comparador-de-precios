// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:proyectocomparador/firebase/firebase.dart';
import 'package:proyectocomparador/models/usuario.dart';
import 'package:proyectocomparador/models/usuarioIniciado.dart';

class RegistroUsuario extends StatefulWidget {
  const RegistroUsuario({super.key, required this.title});
  final String title;

  @override
  State<RegistroUsuario> createState() => _RegistroUsuarioState();
}

class _RegistroUsuarioState extends State<RegistroUsuario> {
  final _nick = TextEditingController();
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  static const Color botonColor = Color(0xFFC77DFF);
  static const Color botonColorPressed = Color(0xFFDDB4FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B2CBF),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Registro",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              _campo('Nick', _nick),
              _campo('Correo', _correo),
              _campo('Contraseña', _pass, pass: true),
              _campo('Confirmar contraseña', _confirm, pass: true),
              const SizedBox(height: 25),
              _boton(
                texto: "Registrar",
                onPressed: _registroNormal,
              ),
              const SizedBox(height: 15),
              _botonGoogle(),
              const SizedBox(height: 15),
              _boton(
                texto: "Volver a inicio de sesión",
                onPressed: () =>
                    Navigator.pushNamed(context, '/screen/iniciarSesion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController c, {bool pass = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: TextField(
        controller: c,
        obscureText: pass,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white24,
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _boton({
    required String texto,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 250,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (states) {
              if (states.contains(MaterialState.pressed)) {
                return botonColorPressed;
              }
              return botonColor;
            },
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _botonGoogle() {
    return SizedBox(
      width: 250,
      height: 48,
      child: ElevatedButton(
        onPressed: _registroGoogle,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (states) {
              if (states.contains(MaterialState.pressed)) {
                return Colors.grey.shade300;
              }
              return Colors.white;
            },
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/google.png',
              height: 20,
              width: 20,
            ),
            const SizedBox(width: 10),
            const Text(
              'Registrar con Google',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registroNormal() async {
    final List<String> errores = [];

    final correo = _correo.text.trim();
    final password = _pass.text.trim();
    final confirm = _confirm.text.trim();

    if (password != confirm) {
      errores.add("Las contraseñas no coinciden");
    }

    final emailRegex =
        RegExp(r'^[^@]+@[^@]+\.(com|net|es)$', caseSensitive: false);

    if (!emailRegex.hasMatch(correo)) {
      errores.add("El correo debe ser válido (ej: texto@gmail.com/.net/.es)");
    }

    if (password.length < 4) {
      errores.add("La contraseña debe tener al menos 4 caracteres");
    }
    final tieneNumero = RegExp(r'\d').hasMatch(password);
    if (!tieneNumero) {
      errores.add("La contraseña debe contener al menos un número");
    }
    if (await firestoreService.correoExiste(correo)) {
      errores.add("Ya existe un usuario con ese correo");
    }
    if (errores.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errores.join("\n")),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    final id = await firestoreService.obtenerSiguienteId();

    final nuevoUsuario = Usuario(
      id: id,
      nick: _nick.text.trim(),
      correo: correo,
      contrasena: password,
      imagenRuta: 'default.png',
    );

    await firestoreService.addUsuario(nuevoUsuario);
    UsuarioIniciado.iniciarSesion(nuevoUsuario);

    Navigator.pushReplacementNamed(context, '/screen/menuPrincipal');
  }

  Future<void> _registroGoogle() async {
    final usuario = await firestoreService.registrarConGoogle(context);

    if (usuario == null) return;

    Navigator.pushReplacementNamed(context, '/screen/menuPrincipal');
  }
}

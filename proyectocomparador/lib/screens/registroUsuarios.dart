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
                style: TextStyle(color: Colors.white, fontSize: 20),
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
    if (_pass.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    final correo = _correo.text.trim();

    if (await firestoreService.correoExiste(correo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya existe un usuario con ese correo')),
      );
      return;
    }

    final id = await firestoreService.obtenerSiguienteId();

    final nuevoUsuario = Usuario(
      id: id,
      nick: _nick.text.trim(),
      correo: correo,
      contrasena: _pass.text.trim(),
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
